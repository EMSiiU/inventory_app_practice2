// Screen de inventario

import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_sliver_app_bar.dart';
import '../../../shared/widgets/docked_navigation_bar.dart';
import '../../../shared/widgets/product_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _currentIndex = 0;

  // Cambia el índice de la barra de navegación
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // TODO: Implementar lógica de enrutamiento entre pantallas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody permite que la lista pase por debajo de la barra de navegación translúcida
      extendBody: true, 
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Artículos',
            cartCount: 3, // Valor estático temporal para pruebas
            onAddPressed: () {
              // TODO: Navegar a la pantalla de "Nuevo Artículo" (Tarea de Rebo)
            },
            onCartPressed: () {
              // TODO: Navegar a la pantalla de "Carrito" (Tarea de Rebo)
            },
          ),
          
          // Sección estática temporal para los filtros o alertas de caducidad
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Todos los artículos', 
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Datos de prueba temporales para visualizar la UI
                return ProductCard(
                  name: index == 0 ? 'Leche entera' : 'Tomate triturado',
                  category: index == 0 ? 'Lácteos' : 'Abarrotes',
                  store: 'Mercadona',
                  statusText: index == 0 ? 'Vence en 2 días' : 'Sin lote activo · Agotado',
                  quantity: index == 0 ? 2 : 0,
                  status: index == 0 ? ProductStatus.warning : ProductStatus.expired,
                  onAddToCart: () {
                    debugPrint('Añadir al carrito presionado');
                  },
                  onConsume: () {
                    debugPrint('Consumir presionado');
                  },
                );
              },
              childCount: 5,
            ),
          ),
        ],
      ),
      bottomNavigationBar: DockedNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}