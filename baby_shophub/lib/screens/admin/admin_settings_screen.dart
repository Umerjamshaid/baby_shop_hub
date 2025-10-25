import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_service.dart';

/* -------------------------------------------------
   1.  CONSTANTS – change only here for re-skin
   ------------------------------------------------- */
class AppColors {
  static const Color primary = Color(0xFF6366F1); // indigo-500
  static const Color primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color secondary = Color(0xFFEC4899); // pink-500
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color scaffold = Color(0xFFFAFAFA); // grey-50
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
}

/* -------------------------------------------------
   2.  MAIN SCREEN
   ------------------------------------------------- */
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------
     2-a  Animation & scroll stuff
     ------------------------------------------------- */
  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  bool _isLoading = false;
  double _appBarOpacity = 0;

  final AdminService _adminService = AdminService();

  // Settings state
  bool _maintenanceMode = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoBackup = true;
  String _currency = 'USD';
  String _timezone = 'UTC';
  int _sessionTimeout = 30;
  double _taxRate = 8.5;
  String _storeName = 'Baby Shop Hub';
  String _storeEmail = 'admin@babyshophub.com';
  String _supportPhone = '+1 (555) 123-4567';

  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeEmailController = TextEditingController();
  final TextEditingController _supportPhoneController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollCtrl = ScrollController()
      ..addListener(() {
        final offset = _scrollCtrl.offset;
        setState(() => _appBarOpacity = (offset / 120).clamp(0, 1));
      });
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    _storeNameController.dispose();
    _storeEmailController.dispose();
    _supportPhoneController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // In a real app, load settings from backend
    setState(() {
      _storeNameController.text = _storeName;
      _storeEmailController.text = _storeEmail;
      _supportPhoneController.text = _supportPhone;
      _taxRateController.text = _taxRate.toString();
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, save to backend
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _storeName = _storeNameController.text;
        _storeEmail = _storeEmailController.text;
        _supportPhone = _supportPhoneController.text;
        _taxRate = double.tryParse(_taxRateController.text) ?? _taxRate;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save settings: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /* -------------------------------------------------
     2-b  Build
     ------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
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
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildSettingsContent(),
                ),
              ),
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
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.card.withValues(alpha: _appBarOpacity),
          ),
        ),
      ),
      title: const Text(
        'Admin Settings',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ],
    );
  }

  /* -------------------------------------------------
     2-d  Settings content
     ------------------------------------------------- */
  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStoreSettings(),
        const SizedBox(height: 24),
        _buildSystemSettings(),
        const SizedBox(height: 24),
        _buildNotificationSettings(),
        const SizedBox(height: 24),
        _buildSecuritySettings(),
        const SizedBox(height: 24),
        _buildBackupSettings(),
      ],
    );
  }

  Widget _buildStoreSettings() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Store Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _storeNameController,
            label: 'Store Name',
            icon: Icons.business,
            hint: 'Enter store name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _storeEmailController,
            label: 'Store Email',
            icon: Icons.email,
            hint: 'Enter store email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _supportPhoneController,
            label: 'Support Phone',
            icon: Icons.phone,
            hint: 'Enter support phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _taxRateController,
            label: 'Tax Rate (%)',
            icon: Icons.percent,
            hint: 'Enter tax rate',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Currency',
            icon: Icons.currency_exchange,
            value: _currency,
            items: const ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
            onChanged: (value) => setState(() => _currency = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_system_daydream,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'System Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Timezone',
            icon: Icons.schedule,
            value: _timezone,
            items: const ['UTC', 'EST', 'PST', 'GMT', 'CET'],
            onChanged: (value) => setState(() => _timezone = value!),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Session Timeout (minutes)',
            icon: Icons.timer,
            value: _sessionTimeout.toString(),
            items: const ['15', '30', '60', '120', '240'],
            onChanged: (value) =>
                setState(() => _sessionTimeout = int.parse(value!)),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Maintenance Mode',
            subtitle: 'Put the store in maintenance mode',
            value: _maintenanceMode,
            onChanged: (value) => setState(() => _maintenanceMode = value),
            icon: Icons.build,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive email notifications for important events',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
            icon: Icons.email,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications on mobile devices',
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            icon: Icons.notifications_active,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Security Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionTile(
            title: 'Change Password',
            subtitle: 'Update your admin password',
            icon: Icons.lock,
            color: AppColors.primary,
            onTap: _changePassword,
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            icon: Icons.verified_user,
            color: AppColors.success,
            onTap: _setup2FA,
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: 'Login History',
            subtitle: 'View recent login attempts',
            icon: Icons.history,
            color: AppColors.warning,
            onTap: _viewLoginHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSettings() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.backup,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Backup & Recovery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: 'Automatic Backup',
            subtitle: 'Automatically backup data daily',
            value: _autoBackup,
            onChanged: (value) => setState(() => _autoBackup = value),
            icon: Icons.backup,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: 'Manual Backup',
            subtitle: 'Create a backup right now',
            icon: Icons.cloud_upload,
            color: AppColors.success,
            onTap: _createBackup,
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: 'Restore from Backup',
            subtitle: 'Restore data from a previous backup',
            icon: Icons.restore,
            color: AppColors.secondary,
            onTap: _restoreBackup,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: .2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: .2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.card,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: .2),
            ),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.card,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 12),
                      Text(item),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary.withValues(alpha: .5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------
     2-e  Action handlers
     ------------------------------------------------- */
  void _changePassword() {
    // Navigate to change password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Change password functionality would be implemented here',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setup2FA() {
    // Navigate to 2FA setup screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Two-factor authentication setup would be implemented here',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewLoginHistory() {
    // Navigate to login history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login history view would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createBackup() {
    // Create manual backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual backup creation would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restoreBackup() {
    // Restore from backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup restoration would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/* ==========================================================
   3.  SMALL UI COMPONENTS
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black54
                : AppColors.primary.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* -------------  animated wave background  ------------- */
class AnimatedWaveBackground extends StatelessWidget {
  final double opacity;
  const AnimatedWaveBackground({required this.opacity, super.key});

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
  const _WavePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: .15),
          AppColors.secondary.withValues(alpha: .1),
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
