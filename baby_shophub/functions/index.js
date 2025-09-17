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


