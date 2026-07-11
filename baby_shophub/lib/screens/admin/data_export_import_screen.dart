import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/product_service.dart';

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
class DataExportImportScreen extends StatefulWidget {
  const DataExportImportScreen({super.key});

  @override
  State<DataExportImportScreen> createState() => _DataExportImportScreenState();
}

class _DataExportImportScreenState extends State<DataExportImportScreen>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------
     2-a  Animation & scroll stuff
     ------------------------------------------------- */
  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  bool _isLoading = false;
  double _appBarOpacity = 0;

  final AdminService _adminService = AdminService();
  final ProductService _productService = ProductService();

  // Export state
  bool _exportProducts = true;
  bool _exportOrders = true;
  bool _exportUsers = false;
  bool _exportCategories = true;
  String _exportFormat = 'CSV';
  DateTime? _exportStartDate;
  DateTime? _exportEndDate;

  // Import state
  bool _importOverwrite = false;
  String _importFormat = 'CSV';

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
                  child: _buildDataManagementContent(),
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
        'Data Export & Import',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  /* -------------------------------------------------
     2-d  Data management content
     ------------------------------------------------- */
  Widget _buildDataManagementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExportSection(),
        const SizedBox(height: 24),
        _buildImportSection(),
        const SizedBox(height: 24),
        _buildDataBackupSection(),
      ],
    );
  }

  Widget _buildExportSection() {
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
                  Icons.file_download,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Export Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Select data to export and format',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Data selection
          _buildCheckboxTile(
            title: 'Products',
            subtitle: 'Export all product information',
            value: _exportProducts,
            onChanged: (value) => setState(() => _exportProducts = value!),
            icon: Icons.inventory,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildCheckboxTile(
            title: 'Orders',
            subtitle: 'Export order history and details',
            value: _exportOrders,
            onChanged: (value) => setState(() => _exportOrders = value!),
            icon: Icons.shopping_cart,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildCheckboxTile(
            title: 'Users',
            subtitle: 'Export user accounts and profiles',
            value: _exportUsers,
            onChanged: (value) => setState(() => _exportUsers = value!),
            icon: Icons.people,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildCheckboxTile(
            title: 'Categories',
            subtitle: 'Export product categories',
            value: _exportCategories,
            onChanged: (value) => setState(() => _exportCategories = value!),
            icon: Icons.category,
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          // Format selection
          const Text(
            'Export Format',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFormatChip('CSV', _exportFormat == 'CSV'),
              const SizedBox(width: 12),
              _buildFormatChip('JSON', _exportFormat == 'JSON'),
              const SizedBox(width: 12),
              _buildFormatChip('XML', _exportFormat == 'XML'),
            ],
          ),
          const SizedBox(height: 20),
          // Date range
          const Text(
            'Date Range (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Start Date',
                  date: _exportStartDate,
                  onChanged: (date) => setState(() => _exportStartDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: 'End Date',
                  date: _exportEndDate,
                  onChanged: (date) => setState(() => _exportEndDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _exportData,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_download),
              label: Text(_isLoading ? 'Exporting...' : 'Export Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection() {
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
                  Icons.file_upload,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Import Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Import data from external sources',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Import format
          const Text(
            'Import Format',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFormatChip('CSV', _importFormat == 'CSV'),
              const SizedBox(width: 12),
              _buildFormatChip('JSON', _importFormat == 'JSON'),
            ],
          ),
          const SizedBox(height: 16),
          // Overwrite option
          _buildCheckboxTile(
            title: 'Overwrite Existing Data',
            subtitle: 'Replace existing records with imported data',
            value: _importOverwrite,
            onChanged: (value) => setState(() => _importOverwrite = value!),
            icon: Icons.warning,
            color: AppColors.warning,
          ),
          const SizedBox(height: 20),
          // Import button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importData,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select File to Import'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: .3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure your import file matches the expected format. Download a sample template first.',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBackupSection() {
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
                  Icons.backup,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Data Backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Create and manage data backups',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBackupAction(
                  title: 'Full Backup',
                  subtitle: 'Complete database backup',
                  icon: Icons.backup,
                  color: AppColors.primary,
                  onTap: _createFullBackup,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBackupAction(
                  title: 'Sample Template',
                  subtitle: 'Download import template',
                  icon: Icons.download,
                  color: AppColors.success,
                  onTap: _downloadTemplate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBackupAction(
                  title: 'Backup History',
                  subtitle: 'View previous backups',
                  icon: Icons.history,
                  color: AppColors.warning,
                  onTap: _viewBackupHistory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBackupAction(
                  title: 'Restore',
                  subtitle: 'Restore from backup',
                  icon: Icons.restore,
                  color: AppColors.error,
                  onTap: _restoreFromBackup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
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
          Checkbox(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String format, bool isSelected) {
    return FilterChip(
      label: Text(format),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            if (format == 'CSV' || format == 'JSON' || format == 'XML') {
              _exportFormat = format;
            }
            if (format == 'CSV' || format == 'JSON') {
              _importFormat = format;
            }
          });
        }
      },
      backgroundColor: AppColors.scaffold,
      selectedColor: AppColors.primary.withValues(alpha: .1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: .2),
          ),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? '${date.month}/${date.day}/${date.year}' : label,
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupAction({
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------
     2-e  Action handlers
     ------------------------------------------------- */
  Future<void> _exportData() async {
    if (!_exportProducts &&
        !_exportOrders &&
        !_exportUsers &&
        !_exportCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one data type to export'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String csvData = '';

      // Export Products
      if (_exportProducts) {
        final products = await _productService.getAllProducts();
        csvData += 'PRODUCTS\n';
        csvData +=
            'id,name,description,price,category,brand,ageRange,stock,isFeatured\n';
        for (final product in products) {
          csvData +=
              '${product.id},${product.name},${product.description},${product.price},${product.category},${product.brand},${product.ageRange},${product.stock},${product.isFeatured}\n';
        }
        csvData += '\n';
      }

      // Export Orders
      if (_exportOrders) {
        final orders = await _adminService.getAllOrders();
        csvData += 'ORDERS\n';
        csvData += 'id,userId,totalAmount,status,orderDate\n';
        for (final order in orders) {
          csvData +=
              '${order.id},${order.userId},${order.totalAmount},${order.status},${order.orderDate.toIso8601String()}\n';
        }
        csvData += '\n';
      }

      // Export Categories - Placeholder for now
      if (_exportCategories) {
        csvData += 'CATEGORIES\n';
        csvData += 'id,name,description\n';
        // In a real implementation, this would fetch categories from the service
        csvData += '\n';
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: csvData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Data exported to clipboard successfully'),
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
                Expanded(child: Text('Export failed: $e')),
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

  void _importData() {
    // In a real app, this would open a file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File import functionality would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createFullBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full backup creation would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template download would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewBackupHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup history view would be implemented here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restoreFromBackup() {
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
