import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

import '../../../shared/widgets/custom_sliver_app_bar.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final CategoryRepository _categoryRepo = CategoryRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final categories = await _categoryRepo.getAllCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _addCategory(String name) async{
    if (name.trim().isEmpty) return;
    await _categoryRepo.insertCategory(CategoryModel(name: name.trim()));
    _loadCategories();
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    if (category.id == null) return;
    final success = await _categoryRepo.deleteCategory(category.id!);
    
    if (success) {
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada con éxito')),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            title: const Text('No se puede eliminar', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Esta categoría está siendo usada por uno o más productos. Debes eliminar o reasignar esos productos primero.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido', style: TextStyle(color: AppTheme.accentBlue)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Nueva Categoría', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ej. Lácteos, Carnes...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              onPressed: () {
                Navigator.pop(context);
                _addCategory(controller.text);
              },
              child: const Text('Guardar', style: TextStyle(color: AppTheme.textPrimary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Mis Categorías',
            onAddPressed: _showAddDialog,
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
            )
          else if (_categories.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No hay categorías. Presiona + para agregar.', style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = _categories[index];
                    return Card(
                      color: AppTheme.surfaceElevated,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(cat.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                        leading: const Icon(CupertinoIcons.tag_fill, color: AppTheme.accentBlue),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: AppTheme.badgeAccent),
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ),
                    );
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
            
          // Espaciado final
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}