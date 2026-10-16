import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';

class PurchaseHistoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Registra la compra y actualiza la última tienda del producto en una sola transacción
  Future<void> registerPurchaseAndUpdateStore(int productId, int storeId, int quantity, double price) async {
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

  // Obtiene el historial completo con nombres de productos y tiendas
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    final Database db = await _dbHelper.database;
    
    final String query = '''
      SELECT h.*, 
              p.nombre as producto_nombre,
              t.nombre as tienda_nombre
      FROM Historial_Compras h
      JOIN Producto p ON h.producto_id = p.id
      JOIN Tienda t ON h.tienda_id = t.id
      ORDER BY h.fecha_compra DESC
    ''';
    
    return await db.rawQuery(query);
  }
}