# 🎯 How to Test All New Features

## ✅ **Features Now Visible on Home Screen!**

When you run the app (`flutter run`), you'll now see **3 colorful buttons** on the home screen right below the promo banner:

### 1. 🎥 **Videos** (Red Button)
- **Label**: "Watch & Shop"
- **What it does**: Opens the TikTok-style video feed
- **How to test**: 
  - Tap the red "Videos" button
  - Swipe up/down to navigate videos
  - Tap products shown in videos to buy
  - Like, share, and view videos

### 2. 🎰 **Spin** (Orange Button)
- **Label**: "Win Rewards"
- **What it does**: Opens the Daily Spin Wheel
- **How to test**:
  - Tap the orange "Spin" button
  - Tap "SPIN NOW!" button
  - Watch the wheel spin
  - Win discounts, free shipping, or points
  - Try again tomorrow (limited to once per day)

### 3. 🎁 **Registry** (Purple Button)
- **Label**: "Gift Lists"
- **What it does**: Opens your baby registries
- **How to test**:
  - Tap the purple "Registry" button
  - Create a new registry
  - Add products to your registry
  - Share the registry link

---

## 📱 **Product Notifications with Images**

### How Product Notifications Work:

**Notifications now show:**
- ✅ Product image (big picture style)
- ✅ Product name and price
- ✅ Action buttons ("View Product", "Save for Later")
- ✅ Tap notification → Opens product detail page

### How to Send a Test Notification:

You can test this by calling the notification service:

```dart
import 'package:baby_shophub/services/notification_service.dart';

// Send a product notification
await NotificationService().sendProductNotification(
  userId: 'your-user-id',
  productId: 'product-123',
  productName: 'Baby Stroller Premium',
  productImage: 'https://example.com/stroller.jpg',
  price: 299.99,
  type: 'price_drop',  // or 'new_arrival', 'back_in_stock'
  discount: '20',
);
```

### Notification Types:
1. **Price Drop** 🔥
   - Title: "Price Drop Alert!"
   - Shows discount percentage

2. **Back in Stock** ✨
   - Title: "Back in Stock!"
   - Alerts when product is available

3. **New Arrival** 🎉
   - Title: "New Arrival!"
   - Shows new products

---

## 🧪 **Testing Checklist**

### ✅ Home Screen Features
- [ ] See 3 colorful feature buttons below promo banner
- [ ] Tap "Videos" button → Opens video feed
- [ ] Tap "Spin" button → Opens spin wheel
- [ ] Tap "Registry" button → Opens registries

### ✅ Video Feed
- [ ] Videos auto-play when scrolled into view
- [ ] Swipe up/down to navigate
- [ ] Tap video to pause/play
- [ ] Like button works (heart icon)
- [ ] Share button works
- [ ] Product cards appear at bottom
- [ ] Tap product → Opens product detail

### ✅ Spin Wheel
- [ ] Wheel spins when tapped
- [ ] Shows reward after spinning
- [ ] Confetti appears on win
- [ ] Coupon code displayed in dialog
- [ ] Can only spin once per 24 hours

### ✅ Baby Registry
- [ ] Create new registry
- [ ] Add products to registry
- [ ] View registry items
- [ ] Share registry link
- [ ] Track purchase progress

### ✅ Product Notifications
- [ ] Notification shows product image
- [ ] Notification shows in system tray
- [ ] Tap notification → Opens product
- [ ] Action buttons work
- [ ] Image loads correctly

---

## 🎬 **Adding Sample Videos**

To test the video feed, add sample videos to Firestore:

### Option 1: Firebase Console
1. Go to Firebase Console → Firestore
2. Create collection: `videos`
3. Add document with this structure:

```json
{
  "id": "video1",
  "videoUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
  "thumbnailUrl": "https://via.placeholder.com/300",
  "title": "Best Baby Stroller Review 2024",
  "description": "Check out this amazing stroller!",
  "uploaderId": "admin",
  "uploaderName": "BabyShopHub",
  "uploaderAvatar": null,
  "productIds": [],
  "views": 0,
  "likes": 0,
  "shares": 0,
  "likedBy": [],
  "createdAt": "2024-01-01T00:00:00Z",
  "isActive": true,
  "category": "Strollers",
  "tags": ["stroller", "review"]
}
```

### Option 2: Use Code
```dart
import 'package:baby_shophub/services/video_service.dart';
import 'package:baby_shophub/models/video_model.dart';

final video = VideoModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  thumbnailUrl: 'https://via.placeholder.com/300',
  title: 'Best Baby Products 2024',
  description: 'Top picks for your baby!',
  uploaderId: 'admin',
  uploaderName: 'BabyShopHub',
  createdAt: DateTime.now(),
);

await VideoService().addVideo(video);
```

### Free Sample Videos:
- https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
- https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4
- https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4

---

## 🐛 **Troubleshooting**

### "Buttons not showing on home screen"
**Solution**: 
1. Stop the app (`flutter run` terminal, press `q`)
2. Run: `flutter pub get`
3. Run: `flutter run`
4. Hot restart (press `R` in terminal)

### "Video feed is empty"
**Solution**: Add sample videos to Firestore (see above)

### "Spin wheel says 'Already Spun Today'"
**Solution**: 
- Wait 24 hours, OR
- Delete your spin history in Firestore:
  - Collection: `spinHistory`
  - Document: `your-user-id`

### "Registry button not working"
**Solution**: Make sure you're logged in

### "Notifications not showing"
**Solution**:
1. Check notification permissions
2. Ensure Firebase Cloud Messaging is configured
3. Check device notification settings

---

## 📸 **What You Should See**

### Home Screen:
```
┌─────────────────────────────┐
│  BabyShopHub     🔍 🛒 🔔  │
├─────────────────────────────┤
│  ┌───────────────────────┐  │
│  │  30% OFF Promo Banner │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────┐ ┌─────┐ ┌─────┐  │
│  │ 🎥  │ │ 🎰  │ │ 🎁  │  │ ← NEW!
│  │Video│ │Spin │ │Reg. │  │
│  └─────┘ └─────┘ └─────┘  │
│                             │
│  Categories                 │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐     │
│  │👶│ │🧸│ │🍼│ │🛁│     │
│  └──┘ └──┘ └──┘ └──┘     │
│                             │
│  Featured Products          │
│  ┌────┐ ┌────┐ ┌────┐     │
│  │Prod│ │Prod│ │Prod│     │
│  └────┘ └────┘ └────┘     │
└─────────────────────────────┘
```

### Video Feed Screen:
```
┌─────────────────────────────┐
│  ← Discover                 │
├─────────────────────────────┤
│                             │
│      [VIDEO PLAYING]        │
│                             │
│                             │
│                        ❤️ 1K│
│                        💬 50 │
│                        ↗️ 100│
│                        👁️ 5K │
│                             │
│  @BabyShopHub               │
│  Best Stroller Review       │
│  Check out this amazing...  │
│  ┌────┐ ┌────┐             │
│  │Prod│ │Prod│  ← Products │
│  └────┘ └────┘             │
└─────────────────────────────┘
```

### Spin Wheel Screen:
```
┌─────────────────────────────┐
│  ← Daily Spin & Win         │
├─────────────────────────────┤
│                             │
│    🎰 Spin the Wheel!       │
│    Tap the wheel to spin    │
│                             │
│       ┌───────────┐         │
│      /  5% OFF    \        │
│     │ Try  │  10%  │        │
│     │ Again│  OFF  │        │
│      \ Free Ship /         │
│       └───────────┘         │
│                             │
│   ┌─────────────────┐       │
│   │   SPIN NOW!     │       │
│   └─────────────────┘       │
│                             │
└─────────────────────────────┘
```

---

## 🚀 **Quick Start Commands**

```bash
# 1. Get dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. Hot reload (after making changes)
# Press 'r' in the terminal

# 4. Hot restart (full restart)
# Press 'R' in the terminal

# 5. Quit
# Press 'q' in the terminal
```

---

## 📝 **Summary**

### What's New:
1. ✅ **3 Feature Buttons** on home screen (Videos, Spin, Registry)
2. ✅ **TikTok-Style Video Feed** with product shopping
3. ✅ **Daily Spin Wheel** for gamification
4. ✅ **Baby Registry** for gift lists
5. ✅ **Product Notifications** with images

### All Features Are Now Accessible!
- No hidden features
- Everything is visible on the home screen
- One tap away from all new functionality

**Last Updated:** 2025-11-27  
**Status:** All Features Live ✅
