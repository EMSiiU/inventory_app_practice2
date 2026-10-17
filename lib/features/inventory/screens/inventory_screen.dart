// Screen de inventario

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:inventory_app_practice2/core/theme/app_theme.dart';

import '../../../shared/widgets/custom_sliver_app_bar.dart';
import '../../../shared/widgets/product_card.dart';

import '../../../data/repositories/product_repository.dart';

import '../../cart/cart_manager.dart';
import '../../cart/screens/cart_screen.dart';
import 'new_item_screen.dart';

enum InventoryStockFilter { all, inStock, lowStock, outOfStock }

enum InventorySortOrder { nameAscending, stockAscending, stockDescending }

List<Map<String, dynamic>> filterAndSortInventoryProducts({
  required List<Map<String, dynamic>> products,
  required String query,
  required String? category,
  required InventoryStockFilter stockFilter,
  required InventorySortOrder sortOrder,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = products.where((product) {
    final name = (product['nombre'] as String? ?? '').toLowerCase();
    final productCategory =
        product['category_name'] as String? ?? 'Sin categoría';
    final stock = (product['stock_total'] as num?)?.toInt() ?? 0;
    final securityStock = (product['stock_seguridad'] as num?)?.toInt() ?? 1;

    final matchesQuery =
        normalizedQuery.isEmpty || name.contains(normalizedQuery);
    final matchesCategory = category == null || productCategory == category;
    final matchesStock = switch (stockFilter) {
      InventoryStockFilter.all => true,
      InventoryStockFilter.inStock => stock > 0,
      InventoryStockFilter.lowStock => stock > 0 && stock <= securityStock,
      InventoryStockFilter.outOfStock => stock == 0,
    };

    return matchesQuery && matchesCategory && matchesStock;
  }).toList();

  filtered.sort((left, right) {
    final nameComparison = (left['nombre'] as String? ?? '')
        .toLowerCase()
        .compareTo((right['nombre'] as String? ?? '').toLowerCase());
    final leftStock = (left['stock_total'] as num?)?.toInt() ?? 0;
    final rightStock = (right['stock_total'] as num?)?.toInt() ?? 0;
    final stockComparison = leftStock.compareTo(rightStock);

    return switch (sortOrder) {
      InventorySortOrder.nameAscending => nameComparison,
      InventorySortOrder.stockAscending =>
        stockComparison == 0 ? nameComparison : stockComparison,
      InventorySortOrder.stockDescending =>
        stockComparison == 0 ? nameComparison : -stockComparison,
    };
  });

  return filtered;
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  // Future que cargará los datos
  late Future<List<Map<String, dynamic>>> _productsFuture;
  String _searchQuery = '';
  String? _selectedCategory;
  InventoryStockFilter _stockFilter = InventoryStockFilter.all;
  InventorySortOrder _sortOrder = InventorySortOrder.nameAscending;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _productRepo.getProductsWithStock();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Determina el estado del producto basado en reglas de negocio
  ProductStatus _determineStatus(int stockTotal, int stockSeguridad) {
    if (stockTotal == 0) return ProductStatus.expired; // Agotado
    if (stockTotal <= stockSeguridad) return ProductStatus.low; // Stock bajo
    // TODO: Integrar verificación de fecha para estado 'warning' (Por caducar)
    return ProductStatus.good; // Óptimo
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CustomSliverAppBar(
          title: 'Artículos',
          onAddPressed: () async {
            // Navega al formulario y recarga la lista al regresar
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewItemScreen()),
            );
            _loadProducts();
          },
          onCartPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );

            if (result == true) {
              _loadProducts();
            }
          },
        ),

        SliverToBoxAdapter(child: _buildSearchAndFilterControls()),

        // Constructor asíncrono para leer SQLite
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No hay artículos. Presiona + para agregar.'),
                  ),
                ),
              );
            }

            final allProducts = snapshot.data!;
            final products = filterAndSortInventoryProducts(
              products: allProducts,
              query: _searchQuery,
              category: _selectedCategory,
              stockFilter: _stockFilter,
              sortOrder: _sortOrder,
            );

            if (products.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        CupertinoIcons.search,
                        color: AppTheme.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        allProducts.isEmpty
                            ? 'No hay artículos. Presiona + para agregar.'
                            : 'No hay artículos que coincidan con estos filtros.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (allProducts.isNotEmpty && _hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpiar filtros'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Mostrando ${products.length} de ${allProducts.length} artículos',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    final stockTotal = (product['stock_total'] as num).toInt();
                    final securityStock = (product['stock_seguridad'] as num)
                        .toInt();
                    final status = _determineStatus(stockTotal, securityStock);

                    String statusText = 'Stock óptimo';
                    if (stockTotal == 0) {
                      statusText = 'Agotado';
                    } else if (stockTotal <= securityStock) {
                      statusText = 'Stock bajo';
                    }

                    return ProductCard(
                      name: product['nombre'],
                      category:
                          'Categoría: ${product['category_name'] ?? 'Sin categoría'}',
                      store:
                          'Última tienda: ${product['last_store_name'] ?? 'N/A'}',
                      statusText: statusText,
                      quantity: stockTotal,
                      status: status,
                      imagePath: product['imagen_url'] as String?,
                      onAddToCart: () {
                        CartManager.instance.addToCart(
                          product['id'] as int,
                          product['nombre'] as String,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${product['nombre']} agregado al carrito',
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.accentBlue,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    CartManager.instance.removeFromCart(
                                      product['id'] as int,
                                    );
                                  },
                                  child: const Text('Deshacer'),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onConsume: () async {
                        await _productRepo.consumeProductFefo(
                          product['id'] as int,
                          1,
                        );
                        _loadProducts();
                      },
                    );
                  }, childCount: products.length),
                ),
              ],
            );
          },
        ),

        // Espacio vacio para que la barra de navegacion no corte el ultimo elemento
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedCategory != null ||
      _stockFilter != InventoryStockFilter.all ||
      _sortOrder != InventorySortOrder.nameAscending;

  Widget _buildSearchAndFilterControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppTheme.textPrimary),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar artículos',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final activeCount = [
      if (_selectedCategory != null) true,
      if (_stockFilter != InventoryStockFilter.all) true,
      if (_sortOrder != InventorySortOrder.nameAscending) true,
    ].length;

    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showFilters,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                CupertinoIcons.slider_horizontal_3,
                color: AppTheme.accentBlue,
              ),
              if (activeCount > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters() async {
    late final List<Map<String, dynamic>> allProducts;
    try {
      allProducts = await _productsFuture;
    } catch (error, stackTrace) {
      debugPrint('Error cargando filtros de inventario: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los filtros.')),
      );
      return;
    }
    if (!mounted) return;
    final categories =
        allProducts
            .map(
              (product) =>
                  product['category_name'] as String? ?? 'Sin categoría',
            )
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    var category = _selectedCategory;
    var stockFilter = _stockFilter;
    var sortOrder = _sortOrder;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filtrar y ordenar',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        category = null;
                        stockFilter = InventoryStockFilter.all;
                        sortOrder = InventorySortOrder.nameAscending;
                      }),
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilterDropdown<String?>(
                  label: 'Categoría',
                  value: category,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...categories.map(
                      (item) => DropdownMenuItem<String?>(
                        value: item,
                        child: Text(item),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => category = value),
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown<InventoryStockFilter>(
                  label: 'Estado del stock',
                  value: stockFilter,
                  items: const [
                    DropdownMenuItem(
                      value: InventoryStockFilter.all,
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(
                      value: InventoryStockFilter.inStock,
                      child: Text('En stock'),
                    ),
                    DropdownMenuItem(
                      value: InventoryStockFilter.lowStock,
                      child: Text('Stock bajo'),
                    ),
                    DropdownMenuItem(
                      value: InventoryStockFilter.outOfStock,
                      child: Text('Agotados'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => stockFilter = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown<InventorySortOrder>(
                  label: 'Ordenar por',
                  value: sortOrder,
                  items: const [
                    DropdownMenuItem(
                      value: InventorySortOrder.nameAscending,
                      child: Text('Nombre: A-Z'),
                    ),
                    DropdownMenuItem(
                      value: InventorySortOrder.stockAscending,
                      child: Text('Stock: menor a mayor'),
                    ),
                    DropdownMenuItem(
                      value: InventorySortOrder.stockDescending,
                      child: Text('Stock: mayor a menor'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => sortOrder = value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category;
                        _stockFilter = stockFilter;
                        _sortOrder = sortOrder;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppTheme.surfaceElevated,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _stockFilter = InventoryStockFilter.all;
      _sortOrder = InventorySortOrder.nameAscending;
    });
  }
}
