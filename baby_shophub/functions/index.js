const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const title = data.title || 'BabyShopHub';
    const body = data.message || '';
    const imageUrl = data.imageUrl || null;
    const userIds = Array.isArray(data.userIds) ? data.userIds : [];
    const payloadData = data.data || {};

    try {
      let targetUserIds = userIds;

      if (userIds.includes('all')) {
        const usersSnapshot = await db.collection('users').get();
        targetUserIds = usersSnapshot.docs.map((d) => d.id);
      }

      if (!targetUserIds.length) {
        console.log('No target users, skipping FCM send');
        return null;
      }

      // Collect tokens for all target users
      const userDocs = await Promise.all(
        targetUserIds.map((uid) => db.collection('users').doc(uid).get())
      );

      const tokens = [];
      userDocs.forEach((doc) => {
        const userData = doc.data() || {};
        const userTokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : [];
        userTokens.forEach((t) => {
          if (typeof t === 'string' && t.length > 0) tokens.push(t);
        });
      });

      const uniqueTokens = Array.from(new Set(tokens));
      if (!uniqueTokens.length) {
        console.log('No tokens found for target users');
        return null;
      }

      const message = {
        notification: {
          title,
          body,
          ...(imageUrl ? { image: imageUrl } : {}),
        },
        data: {
          type: payloadData.type || 'general',
          ...(imageUrl ? { imageUrl } : {}),
          ...Object.keys(payloadData).reduce((acc, key) => {
            acc[key] = String(payloadData[key]);
            return acc;
          }, {}),
        },
        android: {
          notification: {
            channelId: 'order_updates',
            priority: 'HIGH',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              contentAvailable: true,
            },
          },
        },
        tokens: uniqueTokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`FCM sent: success=${response.successCount}, failure=${response.failureCount}`);

      // Optionally prune invalid tokens
      const invalidTokens = [];
      response.responses.forEach((res, idx) => {
        if (!res.success) {
          const errCode = res.error && res.error.code;
          if (
            errCode === 'messaging/invalid-registration-token' ||
            errCode === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(uniqueTokens[idx]);
          }
        }
      });

      if (invalidTokens.length) {
        const batch = db.batch();
        userDocs.forEach((doc) => {
          batch.update(doc.ref, {
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
          });
        });
        await batch.commit();
        console.log(`Pruned invalid tokens: ${invalidTokens.length}`);
      }

      // Write back basic send stats
      try {
        await snap.ref.update({
          successCount: response.successCount,
          failureCount: response.failureCount,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (e) {
        console.warn('Could not write back send stats:', e);
      }
      return null;
    } catch (err) {
      console.error('Error sending FCM:', err);
      return null;
    }
  });

// Price drop alert trigger
exports.sendPriceDropAlert = functions.firestore
 .document('products/{productId}')
 .onUpdate((change, context) => {
   const before = change.before.data();
   const after  = change.after.data();
   const was = before.price;
   const now = after.price;
   const drop = Math.round((1 - now / was) * 100);
   if (drop >= 20) {   // only if real drop
     const payload = {
       notification: null, // we build it manually
       data: {
         type: 'price_drop',
         productId: context.params.productId,
         oldPrice: String(was),
         newPrice: String(now),
         discount: String(drop),
         imageUrl: after.imageUrls[0],
         expiry: String(Date.now() + 2 * 3600 * 1000) // 2 h flash
       },
       topic: `priceDrop_${context.params.productId}`
     };
     return admin.messaging().send(payload);
   }
   return null;
 });

// Stock low warning trigger
exports.sendStockLowAlert = functions.firestore
 .document('products/{productId}')
 .onUpdate((change, context) => {
   const before = change.before.data();
   const after = change.after.data();
   const stock = after.stock;
   if (stock <= 5 && before.stock > 5) { // only if it just went low
     const payload = {
       notification: null,
       data: {
         type: 'stock_low',
         productId: context.params.productId,
         stockLeft: String(stock),
         imageUrl: after.imageUrls[0],
       },
       topic: `stockLow_${context.params.productId}`
     };
     return admin.messaging().send(payload);
   }
   return null;
 });

// Order shipped notification trigger
exports.sendOrderShippedNotification = functions.firestore
 .document('orders/{orderId}')
 .onUpdate((change, context) => {
   const before = change.before.data();
   const after = change.after.data();
   if (before.status !== 'shipped' && after.status === 'shipped') {
     const payload = {
       notification: null,
       data: {
         type: 'order_shipped',
         orderId: context.params.orderId,
       },
       topic: `orderShipped_${context.params.orderId}`
     };
     return admin.messaging().send(payload);
   }
   return null;
 });

// Cart reminder trigger (scheduled daily)
exports.sendCartReminders = functions.pubsub
 .schedule('every 24 hours')
 .onRun(async (context) => {
   const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago
   const carts = await db.collection('carts')
     .where('lastUpdated', '<', cutoff)
     .where('status', '==', 'active') // assuming carts have status
     .get();

   const promises = [];
   carts.forEach(cartDoc => {
     const cartData = cartDoc.data();
     const userId = cartData.userId;
     const items = cartData.items || [];
     const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);

     const payload = {
       notification: null,
       data: {
         type: 'cart_reminder',
         items: String(items.length),
         total: String(total),
       },
       topic: `cartReminder_${userId}`
     };
     promises.push(admin.messaging().send(payload));
   });

   await Promise.all(promises);
   return null;
 });

