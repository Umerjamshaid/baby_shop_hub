import 'package:flutter/material.dart';

class PromoBanner extends StatelessWidget {
  final VoidCallback onShopNow;

  const PromoBanner({super.key, required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffEAF7F5), Color(0xffFFF7EF)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'New essentials',
                    style: TextStyle(
                      color: Color(0xff00A884),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Everything for\nyour baby',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -0.7,
                    color: Color(0xff202020),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: onShopNow,
                  borderRadius: BorderRadius.circular(999),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shop now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff202020),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=700&q=80',
                fit: BoxFit.cover,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.55),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Color(0xff00A884),
                      size: 42,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
