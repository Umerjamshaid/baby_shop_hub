import 'package:baby_shophub/providers/auth_provider.dart';
import 'package:baby_shophub/providers/cart_provider.dart';
import 'package:baby_shophub/providers/notification_provider.dart';
import 'package:baby_shophub/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/home_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCartPressed;

  const HomeAppBar({super.key, required this.onCartPressed});

  @override
  Size get preferredSize => const Size.fromHeight(85);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 85,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xffFAFAFA),
      surfaceTintColor: const Color(0xffFAFAFA),
      automaticallyImplyLeading: false,

      titleSpacing: 20,

      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Hello 👋", style: TextStyle(color: Colors.grey, fontSize: 13)),

          SizedBox(height: 3),

          Text(
            "Baby Shop",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Color(0xff202020),
            ),
          ),
        ],
      ),

      actions: [
        IconButton(
          onPressed: () {
            showSearch(context: context, delegate: AdvancedSearchDelegate());
          },
          icon: const Icon(Icons.search_rounded),
        ),

        Consumer<CartProvider>(
          builder: (context, cart, _) {
            return Badge(
              isLabelVisible: cart.itemCount > 0,

              label: Text(cart.itemCount.toString()),

              child: IconButton(
                onPressed: onCartPressed,
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            );
          },
        ),

        Consumer2<AuthProvider, NotificationProvider>(
          builder: (context, auth, notification, _) {
            final userId = auth.currentUser?.id;

            final unread = userId == null
                ? 0
                : notification.unreadCount(userId);

            return Badge(
              isLabelVisible: unread > 0,

              label: Text(unread.toString()),

              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(width: 12),
      ],
    );
  }
}
