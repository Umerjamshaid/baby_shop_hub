import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/admin_service.dart';
import '../../services/category_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';

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

class _AdminEditProductScreenState extends State<AdminEditProductScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _categoryService = CategoryService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _ageRangeController = TextEditingController();
  final _discountController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _skuController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _originCountryController = TextEditingController();
  final _tagsController = TextEditingController();

  List<String> _imageUrls = [];
  List<Category> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isFeatured = false;
  bool _isEcoFriendly = false;
  bool _isOrganic = false;
  bool _categoriesLoading = true;

  // New optional fields
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  List<String> _selectedMaterials = [];
  List<String> _tags = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _loadCategories();
    _populateForm();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _ageRangeController.dispose();
    _discountController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _skuController.dispose();
    _warrantyController.dispose();
    _originCountryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _populateForm() {
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category;
      _brandController.text = widget.product!.brand;
      _ageRangeController.text = widget.product!.ageRange;
      _imageUrls = widget.product!.imageUrls;
      _isFeatured = widget.product!.isFeatured;
      _discountController.text = widget.product!.discountPercentage.toString();
      _isEcoFriendly = widget.product!.isEcoFriendly;
      _isOrganic = widget.product!.isOrganic;

      // Populate new optional fields
      _weightController.text = widget.product!.weight?.toString() ?? '';
      _lengthController.text = widget.product!.length?.toString() ?? '';
      _widthController.text = widget.product!.width?.toString() ?? '';
      _heightController.text = widget.product!.height?.toString() ?? '';
      _skuController.text = widget.product!.sku ?? '';
      _warrantyController.text = widget.product!.warranty ?? '';
      _originCountryController.text = widget.product!.originCountry ?? '';
      _selectedSizes = List.from(widget.product!.sizes);
      _selectedColors = List.from(widget.product!.colors);
      _selectedMaterials = List.from(widget.product!.materials);
      _tags = List.from(widget.product!.tags);
      _tagsController.text = _tags.join(', ');
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
    });

    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
      });
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

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
        _showSuccessSnackBar('Image uploaded successfully');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to upload image: $e');
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
      _showSuccessSnackBar('Image removed successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to remove image: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      if (_imageUrls.isEmpty) {
        _showErrorSnackBar('Please add at least one product image');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final product = Product(
          id:
              widget.product?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          imageUrls: _imageUrls,
          category: _selectedCategory!,
          brand: _brandController.text.trim(),
          ageRange: _ageRangeController.text.trim(),
          stock: int.parse(_stockController.text),
          isFeatured: _isFeatured,
          discountPercentage: double.tryParse(_discountController.text) ?? 0,
          isEcoFriendly: _isEcoFriendly,
          isOrganic: _isOrganic,
          rating: widget.product?.rating ?? 0,
          reviewCount: widget.product?.reviewCount ?? 0,
          createdAt: widget.product?.createdAt ?? DateTime.now(),
          // New optional fields
          weight: double.tryParse(_weightController.text),
          length: double.tryParse(_lengthController.text),
          width: double.tryParse(_widthController.text),
          height: double.tryParse(_heightController.text),
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          tags: _tagsController.text.trim().isEmpty
              ? []
              : _tagsController.text
                    .trim()
                    .split(',')
                    .map((tag) => tag.trim())
                    .toList(),
          warranty: _warrantyController.text.trim().isEmpty
              ? null
              : _warrantyController.text.trim(),
          originCountry: _originCountryController.text.trim().isEmpty
              ? null
              : _originCountryController.text.trim(),
          sizes: _selectedSizes,
          colors: _selectedColors,
          materials: _selectedMaterials,
        );

        if (widget.product == null) {
          await _adminService.createProduct(product);
        } else {
          await _adminService.updateProduct(product);
        }

        _showSuccessSnackBar(
          'Product ${widget.product == null ? 'created' : 'updated'} successfully',
        );
        widget.onProductSaved();
        Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('Failed to save product: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildProductForm(),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            widget.product == null ? 'Add New Product' : 'Edit Product',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        if (widget.product != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Icon(Icons.delete, color: Colors.red[700], size: 20),
              ),
              onPressed: () => _showDeleteConfirmation(),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 6),
              Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildBasicInfoSection(),
            const SizedBox(height: 6),
            _buildPricingStockSection(),
            const SizedBox(height: 6),
            _buildCategoryBrandSection(),
            const SizedBox(height: 6),
            _buildAdditionalAttributesSection(),
            const SizedBox(height: 6),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Product Images', Icons.image),
            const SizedBox(height: 6),
            Text(
              'Add up to 5 high-quality images of your product',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 6),
            _buildImageGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _imageUrls.length + (_imageUrls.length < 5 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _imageUrls.length) {
          return _buildAddImageTile();
        }
        return _buildImageTile(index);
      },
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.blue[600]),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Main',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Information', Icons.info_outline),
            _buildStyledTextField(
              controller: _nameController,
              label: 'Product Name',
              icon: Icons.shopping_bag_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            _buildStyledTextField(
              controller: _descriptionController,
              label: 'Product Description',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingStockSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Pricing & Inventory', Icons.attach_money),
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _priceController,
                    label: 'Price (\$)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _stockController,
                    label: 'Stock Quantity',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildStyledTextField(
              controller: _discountController,
              label: 'Discount Percentage (%)',
              icon: Icons.local_offer,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final discount = double.tryParse(value);
                  if (discount == null || discount < 0 || discount > 100) {
                    return 'Enter valid discount (0-100)';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBrandSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Category & Details', Icons.category_outlined),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: Colors.blue[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: _categories.map((Category category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: _categoriesLoading
                  ? null
                  : (String? newValue) {
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
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _brandController,
                    label: 'Brand',
                    icon: Icons.business_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _ageRangeController,
                    label: 'Age Range',
                    icon: Icons.child_care_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalAttributesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Additional Attributes',
              Icons.extension_outlined,
            ),
            const SizedBox(height: 6),
            // Weight and Dimensions
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _lengthController,
                    label: 'Length (cm)',
                    icon: Icons.straighten,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _widthController,
                    label: 'Width (cm)',
                    icon: Icons.width_normal,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // SKU and Warranty
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _skuController,
                    label: 'SKU',
                    icon: Icons.qr_code,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _warrantyController,
                    label: 'Warranty',
                    icon: Icons.shield_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Origin Country and Tags
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _originCountryController,
                    label: 'Origin Country',
                    icon: Icons.flag_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _tagsController,
                    label: 'Tags (comma separated)',
                    icon: Icons.tag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Sizes, Colors, Materials dropdowns
            _buildMultiSelectDropdown(
              label: 'Sizes',
              icon: Icons.format_size,
              options: ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
              selectedValues: _selectedSizes,
              onChanged: (values) => setState(() => _selectedSizes = values),
            ),
            const SizedBox(height: 6),
            _buildMultiSelectDropdown(
              label: 'Colors',
              icon: Icons.color_lens,
              options: [
                'Red',
                'Blue',
                'Green',
                'Yellow',
                'Black',
                'White',
                'Gray',
                'Pink',
                'Purple',
                'Orange',
                'Brown',
              ],
              selectedValues: _selectedColors,
              onChanged: (values) => setState(() => _selectedColors = values),
            ),
            const SizedBox(height: 6),
            _buildMultiSelectDropdown(
              label: 'Materials',
              icon: Icons.texture,
              options: [
                'Cotton',
                'Polyester',
                'Wool',
                'Silk',
                'Leather',
                'Plastic',
                'Metal',
                'Wood',
                'Glass',
                'Ceramic',
              ],
              selectedValues: _selectedMaterials,
              onChanged: (values) =>
                  setState(() => _selectedMaterials = values),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectDropdown({
    required String label,
    required IconData icon,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  selectedValues.isEmpty
                      ? 'Select $label'
                      : '${selectedValues.length} selected',
                  style: TextStyle(
                    color: selectedValues.isEmpty
                        ? Colors.grey[600]
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            children: options.map((option) {
              return CheckboxListTile(
                title: Text(option),
                value: selectedValues.contains(option),
                onChanged: (bool? value) {
                  if (value == true) {
                    onChanged([...selectedValues, option]);
                  } else {
                    onChanged(
                      selectedValues.where((item) => item != option).toList(),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Product Settings', Icons.settings_outlined),
            _buildSettingTile(
              title: 'Featured Product',
              subtitle: 'Featured products appear prominently in the app',
              icon: Icons.star_outline,
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value ?? false;
                });
              },
            ),
            const SizedBox(height: 6),
            _buildSettingTile(
              title: 'Eco-Friendly',
              subtitle: 'Mark as environmentally friendly product',
              icon: Icons.eco,
              value: _isEcoFriendly,
              onChanged: (value) {
                setState(() {
                  _isEcoFriendly = value ?? false;
                });
              },
            ),
            const SizedBox(height: 6),
            _buildSettingTile(
              title: 'Organic',
              subtitle: 'Mark as organic product',
              icon: Icons.agriculture,
              value: _isOrganic,
              onChanged: (value) {
                setState(() {
                  _isOrganic = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? Colors.blue[600] : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: value ? Colors.blue[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B73FF),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF6B73FF).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.product == null ? 'Create Product' : 'Update Product',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning, color: Colors.red[700], size: 24),
              ),
              const SizedBox(width: 8),
              const Text('Delete Product'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this product? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add delete functionality here
                _showErrorSnackBar('Delete functionality not implemented yet');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
