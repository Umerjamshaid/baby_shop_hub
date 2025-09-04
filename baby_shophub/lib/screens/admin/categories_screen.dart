import 'package:flutter/material.dart';

import '../../../services/category_service.dart';
import '../../../models/category_model.dart';
import '../../../widgets/common/app_button.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryService.getCategoriesWithProductCount();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No categories yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          AppButton(
            onPressed: _showAddCategoryDialog,
            text: 'Add First Category',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.category, size: 40),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${category.productCount} products'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCategoryDialog(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCategory(category),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        onSave: (Category newCategory) {
          _addCategory(newCategory.name, newCategory.imageUrl);
        },
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        onSave: (Category updatedCategory) {
          _updateCategory(updatedCategory);
        },
      ),
    );
  }

  Future<void> _addCategory(String name, String imageUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final category = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        imageUrl: imageUrl,
        productCount: 0,
      );

      await _categoryService.addCategory(category);
      await _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add category: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCategory(Category category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _categoryService.updateCategory(category);
      await _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update category: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.productCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete category with products')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
        await _categoryService.deleteCategory(category.id);
        await _loadCategories();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete category: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// ---------------------- Category Dialog ----------------------

class CategoryDialog extends StatefulWidget {
  final Category? category;
  final Function(Category) onSave;

  const CategoryDialog({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _imageUrlController.text = widget.category!.imageUrl;
    }
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = widget.category?.copyWith(
        name: _nameController.text,
        imageUrl: _imageUrlController.text,
      ) ??
          Category(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            imageUrl: _imageUrlController.text,
            productCount: 0,
          );

      widget.onSave(category);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Please enter category name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveCategory,
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}
