// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../../services/admin_service.dart';
// import '../../models/product_model.dart';
// import '../../widgets/common/app_button.dart';
//
// class AdminEditProductScreen extends StatefulWidget {
//   final Product? product;
//   final Function() onProductSaved;
//
//   const AdminEditProductScreen({
//     super.key,
//     this.product,
//     required this.onProductSaved,
//   });
//
//   @override
//   State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
// }
//
// class _AdminEditProductScreenState extends State<AdminEditProductScreen>
//     with TickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _adminService = AdminService();
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _stockController = TextEditingController();
//   final _categoryController = TextEditingController();
//   final _brandController = TextEditingController();
//   final _ageRangeController = TextEditingController();
//
//   List<String> _imageUrls = [];
//   bool _isLoading = false;
//   bool _isFeatured = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _animationController.forward();
//
//     if (widget.product != null) {
//       _nameController.text = widget.product!.name;
//       _descriptionController.text = widget.product!.description;
//       _priceController.text = widget.product!.price.toString();
//       _stockController.text = widget.product!.stock.toString();
//       _categoryController.text = widget.product!.category;
//       _brandController.text = widget.product!.brand;
//       _ageRangeController.text = widget.product!.ageRange;
//       _imageUrls = widget.product!.imageUrls;
//       _isFeatured = widget.product!.isFeatured;
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 85,
//       maxWidth: 1024,
//       maxHeight: 1024,
//     );
//
//     if (image != null) {
//       setState(() {
//         _isLoading = true;
//       });
//
//       try {
//         final imageUrl = await _adminService.uploadProductImage(image.path);
//         setState(() {
//           _imageUrls.add(imageUrl);
//           _isLoading = false;
//         });
//         _showSuccessSnackBar('Image uploaded successfully');
//       } catch (e) {
//         setState(() {
//           _isLoading = false;
//         });
//         _showErrorSnackBar('Failed to upload image: $e');
//       }
//     }
//   }
//
//   Future<void> _removeImage(int index) async {
//     final imageUrl = _imageUrls[index];
//     setState(() {
//       _imageUrls.removeAt(index);
//     });
//
//     try {
//       await _adminService.deleteProductImage(imageUrl);
//       _showSuccessSnackBar('Image removed successfully');
//     } catch (e) {
//       _showErrorSnackBar('Failed to remove image: $e');
//     }
//   }
//
//   Future<void> _saveProduct() async {
//     if (_formKey.currentState!.validate()) {
//       if (_imageUrls.isEmpty) {
//         _showErrorSnackBar('Please add at least one product image');
//         return;
//       }
//
//       setState(() {
//         _isLoading = true;
//       });
//
//       try {
//         final product = Product(
//           id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//           name: _nameController.text.trim(),
//           description: _descriptionController.text.trim(),
//           price: double.parse(_priceController.text),
//           imageUrls: _imageUrls,
//           category: _categoryController.text.trim(),
//           brand: _brandController.text.trim(),
//           ageRange: _ageRangeController.text.trim(),
//           stock: int.parse(_stockController.text),
//           isFeatured: _isFeatured,
//           rating: widget.product?.rating ?? 0,
//           reviewCount: widget.product?.reviewCount ?? 0,
//           createdAt: widget.product?.createdAt ?? DateTime.now(),
//         );
//
//         if (widget.product == null) {
//           await _adminService.createProduct(product);
//         } else {
//           await _adminService.updateProduct(product);
//         }
//
//         _showSuccessSnackBar(
//           'Product ${widget.product == null ? 'created' : 'updated'} successfully',
//         );
//         widget.onProductSaved();
//         Navigator.pop(context);
//       } catch (e) {
//         _showErrorSnackBar('Failed to save product: $e');
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 8),
//             Text(message),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: _buildAppBar(),
//       body: Stack(
//         children: [
//           _buildProductForm(),
//           if (_isLoading) _buildLoadingOverlay(),
//         ],
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         widget.product == null ? 'Add New Product' : 'Edit Product',
//         style: const TextStyle(
//           fontWeight: FontWeight.w600,
//           fontSize: 20,
//         ),
//       ),
//       centerTitle: true,
//       elevation: 0,
//       backgroundColor: Theme.of(context).primaryColor,
//       foregroundColor: Colors.white,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios),
//         onPressed: () => Navigator.pop(context),
//       ),
//       actions: [
//         if (widget.product != null)
//           IconButton(
//             icon: const Icon(Icons.delete_outline),
//             onPressed: () => _showDeleteConfirmation(),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildLoadingOverlay() {
//     return Container(
//       color: Colors.black54,
//       child: const Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text(
//                   'Processing...',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProductForm() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildImageSection(),
//               const SizedBox(height: 32),
//               _buildBasicInfoSection(),
//               const SizedBox(height: 24),
//               _buildPricingStockSection(),
//               const SizedBox(height: 24),
//               _buildCategoryBrandSection(),
//               const SizedBox(height: 24),
//               _buildFeaturedSection(),
//               const SizedBox(height: 40),
//               _buildSaveButton(),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               size: 20,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImageSection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader('Product Images', Icons.image),
//             const SizedBox(height: 8),
//             Text(
//               'Add up to 5 high-quality images of your product',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildImageGrid(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageGrid() {
//     return GridView.builder(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 1,
//       ),
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: _imageUrls.length + (_imageUrls.length < 5 ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == _imageUrls.length) {
//           return _buildAddImageTile();
//         }
//         return _buildImageTile(index);
//       },
//     );
//   }
//
//   Widget _buildAddImageTile() {
//     return GestureDetector(
//       onTap: _pickImage,
//       child: Container(
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: Theme.of(context).primaryColor.withOpacity(0.3),
//             width: 2,
//             style: BorderStyle.solid,
//           ),
//           borderRadius: BorderRadius.circular(12),
//           color: Theme.of(context).primaryColor.withOpacity(0.05),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.add_photo_alternate,
//               size: 32,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Add Photo',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Theme.of(context).primaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageTile(int index) {
//     return Stack(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.network(
//               _imageUrls[index],
//               fit: BoxFit.cover,
//               width: double.infinity,
//               height: double.infinity,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return Container(
//                   color: Colors.grey[200],
//                   child: const Center(
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                 );
//               },
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey[200],
//                   child: const Icon(Icons.error, color: Colors.grey),
//                 );
//               },
//             ),
//           ),
//         ),
//         Positioned(
//           top: 6,
//           right: 6,
//           child: GestureDetector(
//             onTap: () => _removeImage(index),
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.9),
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 4,
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.close,
//                 size: 16,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//         if (index == 0)
//           Positioned(
//             bottom: 6,
//             left: 6,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Text(
//                 'Main',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildBasicInfoSection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader('Basic Information', Icons.info_outline),
//             _buildStyledTextField(
//               controller: _nameController,
//               label: 'Product Name',
//               icon: Icons.shopping_bag_outlined,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter product name';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildStyledTextField(
//               controller: _descriptionController,
//               label: 'Product Description',
//               icon: Icons.description_outlined,
//               maxLines: 4,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter product description';
//                 }
//                 return null;
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPricingStockSection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader('Pricing & Inventory', Icons.attach_money),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStyledTextField(
//                     controller: _priceController,
//                     label: 'Price (\$)',
//                     icon: Icons.attach_money,
//                     keyboardType: TextInputType.numberWithOptions(decimal: true),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Enter price';
//                       }
//                       if (double.tryParse(value) == null) {
//                         return 'Invalid price';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStyledTextField(
//                     controller: _stockController,
//                     label: 'Stock Quantity',
//                     icon: Icons.inventory_2_outlined,
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Enter quantity';
//                       }
//                       if (int.tryParse(value) == null) {
//                         return 'Invalid number';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategoryBrandSection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader('Category & Details', Icons.category_outlined),
//             _buildStyledTextField(
//               controller: _categoryController,
//               label: 'Category',
//               icon: Icons.category_outlined,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter category';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStyledTextField(
//                     controller: _brandController,
//                     label: 'Brand',
//                     icon: Icons.business_outlined,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStyledTextField(
//                     controller: _ageRangeController,
//                     label: 'Age Range',
//                     icon: Icons.child_care_outlined,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeaturedSection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader('Product Settings', Icons.settings_outlined),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: _isFeatured
//                     ? Theme.of(context).primaryColor.withOpacity(0.1)
//                     : Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: _isFeatured
//                       ? Theme.of(context).primaryColor.withOpacity(0.3)
//                       : Colors.grey.withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.star_outline,
//                     color: _isFeatured
//                         ? Theme.of(context).primaryColor
//                         : Colors.grey[600],
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Featured Product',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Featured products appear prominently in the app',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Switch(
//                     value: _isFeatured,
//                     onChanged: (value) {
//                       setState(() {
//                         _isFeatured = value;
//                       });
//                     },
//                     activeColor: Theme.of(context).primaryColor,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStyledTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     String? Function(String?)? validator,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: Colors.red),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       ),
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       validator: validator,
//     );
//   }
//
//   Widget _buildSaveButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : _saveProduct,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).primaryColor,
//           foregroundColor: Colors.white,
//           elevation: 2,
//           shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: Text(
//           widget.product == null ? 'Create Product' : 'Update Product',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showDeleteConfirmation() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           title: const Text('Delete Product'),
//           content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Add delete functionality here
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               child: const Text('Delete', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _stockController.dispose();
//     _categoryController.dispose();
//     _brandController.dispose();
//     _ageRangeController.dispose();
//     super.dispose();
//   }
// }

// =====================================================================

// ===========================================================================











// ===========================================================================// ===========================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/admin_service.dart';
import '../../services/category_service.dart'; // Add this import
import '../../models/product_model.dart';
import '../../models/category_model.dart'; // Add this import
import '../../widgets/common/app_button.dart';

class AdminEditProductScreen extends StatefulWidget {
  final Product? product;
  final Function() onProductSaved;

  const AdminEditProductScreen({
    super.key,
    this.product,
    required this.onProductSaved,
  });

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _categoryService = CategoryService(); // Add this
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  // Remove _categoryController since we'll use dropdown
  final _brandController = TextEditingController();
  final _ageRangeController = TextEditingController();

  List<String> _imageUrls = [];
  List<Category> _categories = []; // Add this to store categories
  String? _selectedCategory; // Add this for dropdown value
  bool _isLoading = false;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Load categories when screen initializes

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category; // Set selected category
      _brandController.text = widget.product!.brand;
      _ageRangeController.text = widget.product!.ageRange;
      _imageUrls = widget.product!.imageUrls;
      _isFeatured = widget.product!.isFeatured;
    }
  }

  // Add this method to load categories
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final imageUrl = await _adminService.uploadProductImage(image.path);
        setState(() {
          _imageUrls.add(imageUrl);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    final imageUrl = _imageUrls[index];
    setState(() {
      _imageUrls.removeAt(index);
    });

    try {
      await _adminService.deleteProductImage(imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove image: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final product = Product(
          id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          imageUrls: _imageUrls,
          category: _selectedCategory!, // Use selected category
          brand: _brandController.text.trim(),
          ageRange: _ageRangeController.text.trim(),
          stock: int.parse(_stockController.text),
          isFeatured: _isFeatured,
          rating: widget.product?.rating ?? 0,
          reviewCount: widget.product?.reviewCount ?? 0,
          createdAt: widget.product?.createdAt ?? DateTime.now(),
        );

        if (widget.product == null) {
          await _adminService.createProduct(product);
        } else {
          await _adminService.updateProduct(product);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product ${widget.product == null ? 'created' : 'updated'} successfully')),
        );
        widget.onProductSaved();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProductForm(),
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Product Images
            _buildImageSection(),
            const SizedBox(height: 24),

            // Product Details
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // REPLACED TextFormField with DropdownButtonFormField
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((Category category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ageRangeController,
                    decoration: const InputDecoration(
                      labelText: 'Age Range',
                      prefixIcon: Icon(Icons.child_care),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              title: const Text('Featured Product'),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value ?? false;
                });
              },
            ),
            const SizedBox(height: 32),

            AppButton(
              onPressed: _saveProduct,
              text: widget.product == null ? 'Create Product' : 'Update Product',
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Image Grid
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _imageUrls.length + 1,
          itemBuilder: (context, index) {
            if (index == _imageUrls.length) {
              return GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo, size: 32),
                ),
              );
            }

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _ageRangeController.dispose();
    super.dispose();
  }
}
