import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/order_service.dart';
import 'address_management_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'notification_settings_screen.dart';
import 'orders_screen.dart';
import 'registry_list_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _bg = Color(0xffFAFAFA);
  static const _ink = Color(0xff202020);
  static const _muted = Color(0xff8A8A8A);
  static const _accent = Color(0xff00A884);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: user == null
            ? const _LoggedOutProfile()
            : _LoggedInProfile(user: user, auth: auth),
      ),
    );
  }
}

class _LoggedOutProfile extends StatelessWidget {
  const _LoggedOutProfile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        28,
        24,
        40 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: ProfileScreen._ink,
          ),
        ),
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xffEAF7F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 42,
                  color: ProfileScreen._accent,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome to Baby Shop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: ProfileScreen._ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to manage orders, favorites, addresses and baby registries.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ProfileScreen._muted,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              _PrimaryButton(
                label: 'Create account',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _SecondaryButton(
                label: 'Sign in',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoggedInProfile extends StatelessWidget {
  final UserModel user;
  final AuthProvider auth;

  const _LoggedInProfile({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        44 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: ProfileScreen._ink,
                ),
              ),
            ),
            _RoundIconButton(
              icon: Icons.edit_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: user),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _RecentOrdersCard(userId: user.id),
        const SizedBox(height: 22),
        const _FavoritesPreviewCard(),
        const SizedBox(height: 22),
        _ProfileHero(user: user),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Addresses',
                value: '${user.addresses.length}',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                label: 'Favorites',
                value: '${user.favoriteProducts.length}',
                icon: Icons.favorite_border_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle('My account'),
        const SizedBox(height: 12),
        _MenuCard(
          children: [
            _MenuRow(
              icon: Icons.favorite_border_rounded,
              title: 'Favorites',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
            _MenuRow(
              icon: Icons.location_on_outlined,
              title: 'Addresses',
              subtitle: user.defaultAddress?.city,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddressManagementScreen(user: user),
                ),
              ),
            ),
            _MenuRow(
              icon: Icons.card_giftcard_rounded,
              title: 'Baby registries',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistryListScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Preferences'),
        const SizedBox(height: 12),
        _MenuCard(
          children: [
            _MenuRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            _MenuRow(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SecondaryButton(
          label: 'Log out',
          isDanger: true,
          onTap: () async {
            HapticFeedback.mediumImpact();
            await auth.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logged out')));
            }
          },
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserModel user;

  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xffEAF7F5),
              shape: BoxShape.circle,
              image: user.profileImage == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(user.profileImage!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: user.profileImage == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: ProfileScreen._accent,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: ProfileScreen._ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ProfileScreen._muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((user.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.phone!,
                    style: const TextStyle(
                      color: ProfileScreen._muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffF4F4F4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ProfileScreen._ink,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: ProfileScreen._muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: ProfileScreen._ink,
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final String userId;

  const _RecentOrdersCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: OrderService().getUserOrders(userId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <Order>[];
        return _PreviewCard(
          title: 'Recent orders',
          action: 'View all',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
          ),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
                  height: 52,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ProfileScreen._accent,
                    ),
                  ),
                )
              : orders.isEmpty
              ? const _PreviewEmpty(
                  icon: Icons.receipt_long_outlined,
                  message: 'Your orders will appear here.',
                )
              : Column(
                  children: orders.take(2).map((order) {
                    return _OrderPreviewRow(order: order);
                  }).toList(),
                ),
        );
      },
    );
  }
}

class _FavoritesPreviewCard extends StatelessWidget {
  const _FavoritesPreviewCard();

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favoriteProducts;
    return _PreviewCard(
      title: 'Saved favorites',
      action: 'See all',
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
      ),
      child: favorites.isEmpty
          ? const _PreviewEmpty(
              icon: Icons.favorite_border_rounded,
              message: 'Save products you love for later.',
            )
          : SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length > 4 ? 4 : favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final product = favorites[index];
                  return Container(
                    width: 136,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF6F6F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Color(0xffFF6B6B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ProfileScreen._ink,
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  final Widget child;

  const _PreviewCard({
    required this.title,
    required this.action,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ProfileScreen._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _PreviewEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PreviewEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: ProfileScreen._muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ProfileScreen._muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPreviewRow extends StatelessWidget {
  final Order order;

  const _OrderPreviewRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffEAF7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: ProfileScreen._accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: const TextStyle(
                    color: ProfileScreen._ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${order.itemCount} items • ${order.formattedTotalAmount}',
                  style: const TextStyle(
                    color: ProfileScreen._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _OrderStatus(status: order.status),
        ],
      ),
    );
  }
}

class _OrderStatus extends StatelessWidget {
  final String status;

  const _OrderStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'delivered'
        ? const Color(0xff00A884)
        : normalized == 'cancelled'
        ? const Color(0xffFF6B6B)
        : const Color(0xffC07A45);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuRow> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 68, color: Color(0xffEFEFEF)),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xffF4F4F4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: ProfileScreen._ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ProfileScreen._ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ProfileScreen._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffBBBBBB)),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xffE8E8E8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDanger ? const Color(0xffFF6B6B) : ProfileScreen._ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
