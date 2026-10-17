import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/notifications/expiration_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../shared/widgets/custom_sliver_app_bar.dart';
import '../../inventory/screens/new_item_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final _notificationService = ExpirationNotificationService.instance;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productRepo.getProductsWithStock();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(int productId) async {
    final success = await _productRepo.deleteProduct(productId);

    if (success) {
      try {
        await _notificationService.synchronizeActiveBatches();
      } catch (error, stackTrace) {
        debugPrint(
          'Error al sincronizar alarmas tras eliminar producto: '
          '$error\n$stackTrace',
        );
      }
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado con éxito')),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            title: const Text(
              'No se puede eliminar',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: const Text(
              'Este producto tiene registros en tu historial de compras o lotes activos. Elimínalos primero o consúmelos para mantener la integridad de tus datos.',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: AppTheme.accentBlue),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Mis Productos',
            onAddPressed: () async {
              // En lugar de un diálogo, navegamos a la pantalla de nuevo artículo
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewItemScreen()),
              );
              // Al regresar de crear el artículo, recargamos la lista
              _loadProducts();
            },
            // onCartPressed se omite
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_products.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No hay productos. Presiona + para agregar.',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  return Card(
                    color: AppTheme.surfaceElevated,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        product['nombre'],
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Categoría: ${product['category_name'] ?? 'N/A'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      leading: const Icon(
                        CupertinoIcons.cube_box_fill,
                        color: AppTheme.accentBlue,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          CupertinoIcons.trash,
                          color: AppTheme.badgeAccent,
                        ),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ),
                  );
                }, childCount: _products.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
