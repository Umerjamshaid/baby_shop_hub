import 'dart:ui';
import 'package:baby_shophub/screens/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';
import 'address_management_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

/* -------------------------------------------------
   1.  CONSTANTS – change only here for re-skin
   ------------------------------------------------- */
class AppColors {
  static const primary = Color(0xFF6366F1); // indigo-500
  static const primaryDark = Color(0xFF4F46E5); // indigo-600
  static const secondary = Color(0xFFEC4899); // pink-500
  static const success = Color(0xFF10B981); // emerald-500
  static const warning = Color(0xFFF59E0B); // amber-500
  static const error = Color(0xFFEF4444); // red-500
  static const scaffold = Color(0xFFFAFAFA); // grey-50
  static const card = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
}

/* -------------------------------------------------
   2.  MAIN SCREEN
   ------------------------------------------------- */
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------
     2-a  Animation & scroll stuff
     ------------------------------------------------- */
  late AnimationController _avatarCtrl;
  late ScrollController _scrollCtrl;
  bool _isLoading = false;
  double _appBarOpacity = 0;

  @override
  void initState() {
    super.initState();
    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scrollCtrl = ScrollController()
      ..addListener(() {
        final offset = _scrollCtrl.offset;
        setState(() => _appBarOpacity = (offset / 120).clamp(0, 1));
      });
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /* -------------------------------------------------
     2-b  Build
     ------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          /* -------------  background wave  ------------- */
          Positioned.fill(
            child: AnimatedWaveBackground(opacity: _appBarOpacity),
          ),
          /* -------------  content  ------------- */
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(user),
              if (_isLoading)
                ..._buildShimmerSliver()
              else if (user == null)
                ..._buildLoggedOutSliver()
              else
                ..._buildProfileSlivers(user, auth),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------
     2-c  Sliver AppBar (glass)
     ------------------------------------------------- */
  Widget _buildSliverAppBar(UserModel? user) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: AppColors.card.withOpacity(_appBarOpacity)),
        ),
      ),
      title: Text(
        user?.name ?? 'Profile',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      leading: const SizedBox(),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _onEdit(user),
              icon: const Icon(Icons.edit_rounded),
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  /* -------------------------------------------------
     2-d  Logged-out state
     ------------------------------------------------- */
  List<Widget> _buildLoggedOutSliver() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _AnimatedAvatar(onTap: () => HapticFeedback.mediumImpact()),
              const SizedBox(height: 32),
              const Text(
                'Welcome to BabyShopHub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to unlock exclusive features',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary.withOpacity(.8),
                ),
              ),
              const SizedBox(height: 40),
              _NeuroButton(
                label: 'Create Account',
                onPressed: _goRegister,
                isPrimary: true,
              ),
              const SizedBox(height: 16),
              _NeuroButton(
                label: 'Sign In',
                onPressed: _goLogin,
                isPrimary: false,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /* -------------------------------------------------
     2-e  Profile content (logged-in)
     ------------------------------------------------- */
  List<Widget> _buildProfileSlivers(UserModel user, AuthProvider auth) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _ProfileHeader(user: user, avatarCtrl: _avatarCtrl),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _AccountCard(user: user),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _AddressCard(user: user),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _ActionGrid(auth: auth),
        ),
      ),
    ];
  }

  /* -------------------------------------------------
     2-f  Helpers
     ------------------------------------------------- */
  List<Widget> _buildShimmerSliver() => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 180, radius: 24),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 120, radius: 24),
      ),
    ),
  ];

  void _onEdit(UserModel user) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
  );

  void _goRegister() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const RegisterScreen()),
  );

  void _goLogin() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

/* ==========================================================
   3.  RE-USABLE WIDGETS
   ========================================================== */

/* -------------  animated avatar  ------------- */
class _AnimatedAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _AnimatedAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 1, end: 0.95),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                size: 56,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

/* -------------  profile header (logged-in)  ------------- */
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final AnimationController avatarCtrl;
  const _ProfileHeader({required this.user, required this.avatarCtrl});

  @override
  Widget build(BuildContext context) {
    return _NeuroCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          /* -------------  avatar with ring  ------------- */
          GestureDetector(
            onTap: () => avatarCtrl.forward().then((_) => avatarCtrl.reverse()),
            child: AnimatedBuilder(
              animation: avatarCtrl,
              builder: (_, __) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3 + 2 * avatarCtrl.value,
                    ),
                    image: user.profileImage != null
                        ? DecorationImage(
                            image: NetworkImage(user.profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: user.profileImage == null
                      ? const Icon(Icons.person, size: 48, color: Colors.white)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (user.phone != null)
            Text(
              user.phone!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------  account card  ------------- */
class _AccountCard extends StatelessWidget {
  final UserModel user;
  const _AccountCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _infoRow('Member since', _formatDate(user.createdAt)),
          const Divider(height: 24),
          _infoRow('Email', user.email),
          if (user.phone != null) ...[
            const Divider(height: 24),
            _infoRow('Phone', user.phone!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String l, String v) => Row(
    children: [
      Expanded(
        child: Text(l, style: const TextStyle(color: Colors.grey)),
      ),
      Expanded(
        flex: 2,
        child: Text(
          v,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/* -------------  address card  ------------- */
class _AddressCard extends StatelessWidget {
  final UserModel user;
  const _AddressCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final addr = user.defaultAddress;
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Addresses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _TextChip(
                label: 'Manage',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressManagementScreen(user: user),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (addr != null)
            _AddressTile(address: addr, isDefault: true)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No address added yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

/* -------------  action grid  ------------- */
class _ActionGrid extends StatelessWidget {
  final AuthProvider auth;
  const _ActionGrid({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.settings_rounded,
          label: 'Settings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.favorite_rounded,
          label: 'My Favorites',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.notifications_rounded,
          label: 'Notification Settings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _NeuroButton(
          label: 'Logout',
          onPressed: () => _logout(context),
          isPrimary: false,
        ),
      ],
    );
  }

  void _logout(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logged out successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

/* ==========================================================
   4.  SMALL UI COMPONENTS
   ========================================================== */

/* -------------  neuro-card  ------------- */
class _NeuroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _NeuroCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black54 : AppColors.primary.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* -------------  neuro-button  ------------- */
class _NeuroButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  const _NeuroButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : AppColors.primary.withOpacity(.4),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/* -------------  text-chip  ------------- */
class _TextChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/* -------------  address tile  ------------- */
class _AddressTile extends StatelessWidget {
  final Address address;
  final bool isDefault;
  const _AddressTile({required this.address, required this.isDefault});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDefault
            ? AppColors.primary.withOpacity(.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? AppColors.primary : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEFAULT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isDefault) const SizedBox(height: 8),
          Text(
            address.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(address.phone, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            address.fullAddress,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/* -------------  action tile  ------------- */
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================================================
   5.  MISC
   ========================================================== */

/* -------------  shimmer skeleton  ------------- */
class ShimmerWidget extends StatelessWidget {
  final double height;
  final double radius;
  const ShimmerWidget.rect({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/* -------------  animated wave background  ------------- */
class AnimatedWaveBackground extends StatelessWidget {
  final double opacity;
  const AnimatedWaveBackground({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: CustomPaint(
        painter: _WavePainter(Theme.of(context).brightness),
        size: Size.infinite,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Brightness brightness;
  _WavePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(.15),
          AppColors.secondary.withOpacity(.1),
        ],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(0, size.height * .3)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .4,
        size.width * .5,
        size.height * .3,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .2,
        size.width,
        size.height * .3,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
