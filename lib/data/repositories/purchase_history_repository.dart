import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';

class PurchaseHistoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Registra la compra y actualiza la última tienda del producto en una sola transacción
  Future<void> registerPurchaseAndUpdateStore(
    int productId,
    int storeId,
    int quantity,
    double price,
  ) async {
    final Database db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Inserta el registro en el historial
      await txn.insert('Historial_Compras', {
        'producto_id': productId,
        'tienda_id': storeId,
        'cantidad': quantity,
        'precio_unitario': price,
        'fecha_compra': DateTime.now().toIso8601String(),
      });

      // Actualiza la referencia de la última tienda en el producto
      await txn.update(
        'Producto',
        {'ultima_tienda_id': storeId},
        where: 'id = ?',
        whereArgs: [productId],
      );
    });
  }

  // Combina las compras y los consumos para mostrar una cronología de inventario.
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    final Database db = await _dbHelper.database;

    final String query = '''
      SELECT * FROM (
      SELECT
        h.id,
        'compra' AS tipo,
        h.producto_id,
        h.fecha_compra AS fecha,
        h.cantidad,
        h.precio_unitario,
        NULL AS stock_restante,
        0 AS agotado,
        p.nombre AS producto_nombre,
        p.imagen_url AS producto_imagen_url,
        t.nombre AS tienda_nombre
      FROM Historial_Compras h
      JOIN Producto p ON h.producto_id = p.id
      JOIN Tienda t ON h.tienda_id = t.id

      UNION ALL

      SELECT
        c.id,
        'consumo' AS tipo,
        c.producto_id,
        c.fecha_consumo AS fecha,
        c.cantidad,
        NULL AS precio_unitario,
        c.stock_restante,
        CASE WHEN c.stock_restante = 0 THEN 1 ELSE 0 END AS agotado,
        p.nombre AS producto_nombre,
        p.imagen_url AS producto_imagen_url,
        NULL AS tienda_nombre
      FROM Historial_Consumos c
      JOIN Producto p ON c.producto_id = p.id
      ) AS movimientos
      ORDER BY fecha DESC, id DESC
    ''';

    return await db.rawQuery(query);
  }
}
