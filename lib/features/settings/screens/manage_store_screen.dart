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
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final stores = await _storeRepo.getAllStores();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Error cargando tiendas: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _addStore(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;

    try {
      await _storeRepo.insertStore(StoreModel(name: normalizedName));
    } catch (error, stackTrace) {
      debugPrint('Error guardando tienda: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la tienda: $error')),
      );
      return;
    }

    if (!mounted) return;
    await _loadStores();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _loadError == null
              ? 'Tienda agregada con éxito'
              : 'La tienda se guardó, pero no se pudo actualizar la lista.',
        ),
      ),
    );
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
            title: const Text(
              'No se puede eliminar',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: const Text(
              'Esta tienda tiene registros en tu historial de compras. No se puede eliminar para no perder la trazabilidad de tus gastos.',
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

  Future<void> _showAddDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddStoreDialog(),
    );
    if (name == null || !mounted) return;
    await _addStore(name);
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
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_loadError != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Text(
                        'No se pudieron cargar las tiendas.',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadStores,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_stores.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No hay tiendas. Presiona + para agregar.',
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
                  final store = _stores[index];
                  return Card(
                    color: AppTheme.surfaceElevated,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        store.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      leading: const Icon(
                        CupertinoIcons.building_2_fill,
                        color: AppTheme.accentBlue,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          CupertinoIcons.trash,
                          color: AppTheme.badgeAccent,
                        ),
                        onPressed: () => _deleteStore(store),
                      ),
                    ),
                  );
                }, childCount: _stores.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _AddStoreDialog extends StatefulWidget {
  const _AddStoreDialog();

  @override
  State<_AddStoreDialog> createState() => _AddStoreDialogState();
}

class _AddStoreDialogState extends State<_AddStoreDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      title: const Text(
        'Nueva Tienda',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: TextField(
        controller: _controller,
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
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
          onPressed: () {
            if (_controller.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ingresa el nombre de la tienda.'),
                ),
              );
              return;
            }
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text(
            'Guardar',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
