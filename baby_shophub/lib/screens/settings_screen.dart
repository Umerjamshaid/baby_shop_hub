import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('General'),
          _buildCard([
            _buildLanguageTile(),
            const Divider(height: 1),
            _buildThemeTile(),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          _buildCard([
            _buildNotificationTile(),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildCard([
            _buildTile(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () => _showDialog('Privacy Policy', 'This is a placeholder for the Privacy Policy.'),
            ),
            const Divider(height: 1),
            _buildTile(
              title: 'Terms of Service',
              icon: Icons.description_outlined,
              onTap: () => _showDialog('Terms of Service', 'This is a placeholder for the Terms of Service.'),
            ),
            const Divider(height: 1),
            _buildTile(
              title: 'App Version',
              icon: Icons.info_outline,
              trailing: Text(
                'v$_version ($_buildNumber)',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildThemeTile() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          secondary: Icon(
            themeProvider.themeMode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            color: Colors.grey[600],
          ),
          title: const Text('Dark Mode'),
          value: themeProvider.themeMode == ThemeMode.dark,
          onChanged: (value) {
            themeProvider.setThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      leading: Icon(Icons.language, color: Colors.grey[600]),
      title: const Text('Language'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_selectedLanguage, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: _showLanguageDialog,
    );
  }

  Widget _buildNotificationTile() {
    return ListTile(
      leading: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
      title: const Text('Push Notifications'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: ['English', 'Spanish', 'French', 'German'].map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedLanguage = lang);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang),
                  if (_selectedLanguage == lang)
                    Icon(Icons.check, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
