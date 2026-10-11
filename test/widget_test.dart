import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_practice2/features/inventory/screens/new_item_screen.dart';

void main() {
  testWidgets('new item form groups the initial batch fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NewItemScreen()));

    expect(find.text('Nuevo artículo'), findsOneWidget);
    expect(find.text('Lote inicial'), findsOneWidget);
    expect(find.text('Caducidad'), findsOneWidget);
    expect(find.text('Activar alarmas locales'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('new item form validates its existing required fields', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NewItemScreen()));

    await tester.enterText(find.byType(TextFormField).last, '0');
    await tester.tap(find.byTooltip('Guardar artículo'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese un nombre'), findsOneWidget);
    expect(find.text('Ingrese una cantidad mayor que 0'), findsOneWidget);
  });
}
