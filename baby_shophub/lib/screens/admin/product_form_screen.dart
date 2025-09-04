import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/category_service.dart';
import '../../../services/product_service.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../widgets/common/app_button.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _categoryService = CategoryService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _ageRangeController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategory;
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _categoriesLoading = true;

  List<String> _imageUrls = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If editing an existing product, populate the form
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _brandController.text = widget.product!.brand;
      _ageRangeController.text = widget.product!.ageRange;
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category;
      _isFeatured = widget.product!.isFeatured;
      _imageUrls = widget.product!.imageUrls;
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

        // If no category is selected yet, select the first one
        if (_selectedCategory == null && _categories.isNotEmpty) {
          _selectedCategory = _categories.first.name;
        }
      });
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
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
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          imageUrls: _imageUrls,
          category: _selectedCategory!,
          brand: _brandController.text,
          ageRange: _ageRangeController.text,
          stock: int.parse(_stockController.text),
          rating: widget.product?.rating ?? 0,
          reviewCount: widget.product?.reviewCount ?? 0,
          isFeatured: _isFeatured,
          createdAt: widget.product?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.product == null) {
          await _productService.addProduct(product);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        } else {
          await _productService.updateProduct(product);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        // In a real app, you would upload the image to Firebase Storage
        // and get the download URL. For now, we'll just use a placeholder.
        setState(() {
          _imageUrls.add('https://via.placeholder.com/300?text=Product+Image');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              _buildImageSection(),
              const SizedBox(height: 20),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Age Range
              TextFormField(
                controller: _ageRangeController,
                decoration: const InputDecoration(
                  labelText: 'Age Range',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Featured Checkbox
              CheckboxListTile(
                title: const Text('Featured Product'),
                value: _isFeatured,
                onChanged: (bool? value) {
                  setState(() {
                    _isFeatured = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              AppButton(
                onPressed: _saveProduct,
                text: widget.product == null ? 'Add Product' : 'Update Product',
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categoriesLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(),
        ],
      );
    }

    if (_categories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'No categories available. Please add categories first.',
            style: TextStyle(color: Colors.red[700]),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
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
                  child: const Icon(Icons.add, size: 40),
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
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _imageUrls.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _productService.deleteProduct(widget.product!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _ageRangeController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}