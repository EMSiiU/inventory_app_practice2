import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_practice2/features/inventory/screens/new_item_screen.dart';
import 'package:inventory_app_practice2/features/settings/screens/purchase_history_screen.dart';
import 'package:inventory_app_practice2/shared/widgets/product_card.dart';

void main() {
  testWidgets('new item form groups the initial batch fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NewItemScreen()));

    expect(find.text('Nuevo artículo'), findsOneWidget);
    expect(find.text('Imagen del artículo (opcional)'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de galería'), findsOneWidget);
    expect(find.text('Quitar imagen'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Lote inicial'), findsOneWidget);
    expect(find.text('Caducidad'), findsOneWidget);
    expect(find.text('Activar alarmas locales'), findsOneWidget);
  });

  testWidgets('new item form validates its existing required fields', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NewItemScreen()));

    await tester.tap(find.byTooltip('Guardar artículo'));
    await tester.pumpAndSettle();
    expect(find.text('Ingrese un nombre'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    final quantityField = find.ancestor(
      of: find.text('Cantidad inicial'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(quantityField, '0');
    await tester.tap(find.byTooltip('Guardar artículo'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese una cantidad mayor que 0'), findsOneWidget);
  });

  testWidgets('product card shows its default image placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(
          name: 'Arroz',
          category: 'Categoría: Abarrotes',
          store: 'Última tienda: Tienda',
          statusText: 'Stock óptimo',
          quantity: 1,
          status: ProductStatus.good,
          onAddToCart: () {},
          onConsume: () {},
        ),
      ),
    );

    expect(find.byIcon(CupertinoIcons.cube_box), findsOneWidget);
  });

  testWidgets('history distinguishes partial consumption from depletion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            InventoryHistoryEntryCard(
              productName: 'Arroz',
              imagePath: null,
              isPurchase: false,
              isDepleted: false,
              quantity: 1,
              dateLabel: '16/10/2026',
              remainingStock: 2,
            ),
            InventoryHistoryEntryCard(
              productName: 'Leche',
              imagePath: null,
              isPurchase: false,
              isDepleted: true,
              quantity: 1,
              dateLabel: '16/10/2026',
              remainingStock: 0,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Consumo de inventario'), findsOneWidget);
    expect(find.text('El artículo quedó agotado'), findsOneWidget);
    expect(find.text('Restan 2'), findsOneWidget);
    expect(find.text('Producto agotado'), findsOneWidget);
    expect(find.text('-1 UNIDADES'), findsNWidgets(2));
  });
}
