import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/store_model.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../shared/widgets/custom_sliver_app_bar.dart';

class ManageStoreScreen extends StatefulWidget {
  const ManageStoreScreen({super.key});

  @override
  State<ManageStoreScreen> createState() => _ManageStoreScreenState();
}

class _ManageStoreScreenState extends State<ManageStoreScreen> {
  final StoreRepository _storeRepo = StoreRepository();
  List<StoreModel> _stores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    final stores = await _storeRepo.getAllStores();
    setState(() {
      _stores = stores;
      _isLoading = false;
    });
  }

  Future<void> _addStore(String name) async {
    if (name.trim().isEmpty) return;
    await _storeRepo.insertStore(StoreModel(name: name.trim()));
    _loadStores();
  }

  Future<void> _deleteStore(StoreModel store) async {
    if (store.id == null) return;
    
    final success = await _storeRepo.deleteStore(store.id!);
    
    if (success) {
      _loadStores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tienda eliminada con éxito')),
        );
      }
    } else {
      // Bloqueado por el ON DELETE RESTRICT del Historial
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            title: const Text('No se puede eliminar', style: TextStyle(color: AppTheme.textPrimary)),
            content: const Text(
              'Esta tienda tiene registros en tu historial de compras. No se puede eliminar para no perder la trazabilidad de tus gastos.',
              style: TextStyle(color: AppTheme.textPrimary),
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
          title: const Text('Nueva Tienda', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ej. Walmart, Mercado, Tienda 3B...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            textCapitalization: TextCapitalization.words,
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
                _addStore(controller.text);
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
            title: 'Mis Tiendas',
            onAddPressed: _showAddDialog,
            // onCartPressed se omite
          ),
          
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
            )
          else if (_stores.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No hay tiendas. Presiona + para agregar.', style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final store = _stores[index];
                    return Card(
                      color: AppTheme.surfaceElevated,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(store.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                        leading: const Icon(CupertinoIcons.building_2_fill, color: AppTheme.accentBlue),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: AppTheme.badgeAccent),
                          onPressed: () => _deleteStore(store),
                        ),
                      ),
                    );
                  },
                  childCount: _stores.length,
                ),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}