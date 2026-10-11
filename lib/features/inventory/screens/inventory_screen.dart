// Screen de inventario

import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_sliver_app_bar.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../data/repositories/product_repository.dart';
import 'new_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductRepository _productRepo = ProductRepository();
  
  // Future que cargará los datos
  late Future<List<Map<String, dynamic>>> _productsFuture;

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
          cartCount: 0, // TODO: Conectar con controlador de carrito
          onAddPressed: () async {
            // Navega al formulario y recarga la lista al regresar
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewItemScreen()),
            );
            _loadProducts();
          },
          onCartPressed: () {
            // TODO: Navegar a pantalla de carrito
          },
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Todos los artículos', 
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),

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

            final products = snapshot.data!;

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  final stockTotal = product['stock_total'] as int;
                  final securityStock = product['stock_seguridad'] as int;
                  final status = _determineStatus(stockTotal, securityStock);
                  
                  // Textos dinámicos según el estado
                  String statusText = 'Stock óptimo';
                  if (stockTotal == 0) statusText = 'Agotado';
                  else if (stockTotal <= securityStock) statusText = 'Stock bajo';

                  return ProductCard(
                    name: product['nombre'],
                    category: 'Categoría ID: ${product['categoria_id']}', 
                    store: 'Última tienda ID: ${product['ultima_tienda_id'] ?? 'N/A'}',
                    statusText: statusText,
                    quantity: stockTotal,
                    status: status,
                    onAddToCart: () {
                      // TODO: Implementar adición al carrito
                    },
                    onConsume: () async {
                      await _productRepo.consumeProductFefo(product['id'], 1);
                      _loadProducts(); // Recarga la lista tras consumir
                    },
                  );
                },
                childCount: products.length,
              ),
            );
          },
        ),
      ],
    );
  }
}