import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/notification_model.dart';

class PrettyNotificationCard extends StatelessWidget {
  final NotificationModel notif;
  final String userId;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PrettyNotificationCard({
    super.key,
    required this.notif,
    required this.userId,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = dark ? Colors.grey.shade900 : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: ValueKey(notif.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.redAccent,
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor.withOpacity(.55),
                  cardColor.withOpacity(.35),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.blue.withOpacity(.15),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /* ---------------  TOP ROW  --------------- */
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon or hero image
                          _leadingImage(),
                          const SizedBox(width: 12),
                          // Title + time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  notif.formattedDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Unread dot
                          if (!notif.isReadBy(userId))
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueAccent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      /* ---------------  MESSAGE  --------------- */
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      /* ---------------  OPTIONAL IMAGE  --------------- */
                      if (notif.imageUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            notif.imageUrl!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      /* ---------------  ACTION BAR  --------------- */
                      if (notif.data?['type'] == 'product') ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _glassButton(
                              label: 'View',
                              onTap: () => _handleProductTap(context),
                            ),
                            const SizedBox(width: 8),
                            _glassButton(
                              label: 'Save',
                              onTap: () => _handleSaveTap(context),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------------------------------------------------------- */
  Widget _leadingImage() {
    final icon = Icons.notifications;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(.8), Colors.blue],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _glassButton({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      );

  void _handleProductTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/product',
      arguments: {'id': notif.data!['productId']},
    );
  }

  void _handleSaveTap(BuildContext context) {
    // call your save/fav logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved!')));
  }
}
