import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/product_batch_model.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Inserta un nuevo producto
  Future<int> insertProduct(ProductModel product) async {
    final Database db = await _dbHelper.database;
    return await db.insert('Producto', product.toMap());
  }

  Future<int> insertProductWithInitialBatch({
    required ProductModel product,
    required DateTime expirationDate,
    required int quantity,
  }) async {
    final Database db = await _dbHelper.database;

    return db.transaction((transaction) async {
      final productId = await transaction.insert('Producto', product.toMap());
      final initialBatch = ProductBatchModel(
        productId: productId,
        expirationDate: expirationDate,
        quantity: quantity,
      );

      await transaction.insert('Lote_Producto', initialBatch.toMap());
      return productId;
    });
  }

  // Obtiene los productos calculando su stock total dinámicamente
  // Si el stock total es 0, se considera en estado "Agotado"
  Future<List<Map<String, dynamic>>> getProductsWithStock() async {
    final Database db = await _dbHelper.database;
    
    final String query = '''
      SELECT p.*, 
            c.nombre as category_name,
            t.nombre as last_store_name,
            COALESCE(SUM(l.cantidad), 0) as stock_total 
      FROM Producto p
      LEFT JOIN Categoria c ON p.categoria_id = c.id
      LEFT JOIN Tienda t ON p.ultima_tienda_id = t.id
      LEFT JOIN Lote_Producto l ON p.id = l.producto_id AND l.cantidad > 0
      GROUP BY p.id
    ''';

    return await db.rawQuery(query);
  }

  // Consume unidades FEFO y registra el stock resultante en la misma transacción.
  Future<void> consumeProductFefo(int productId, int quantityToConsume) async {
    if (quantityToConsume <= 0) {
      throw ArgumentError.value(
        quantityToConsume,
        'quantityToConsume',
        'La cantidad a consumir debe ser mayor que cero.',
      );
    }

    final Database db = await _dbHelper.database;

    await db.transaction((txn) async {
      final batches = await txn.query(
        'Lote_Producto',
        where: 'producto_id = ? AND cantidad > 0',
        whereArgs: [productId],
        orderBy: 'fecha_caducidad ASC',
      );

      var remainingToConsume = quantityToConsume;
      var consumedQuantity = 0;
      var remainingStock = batches.fold<int>(
        0,
        (total, batch) => total + (batch['cantidad'] as int),
      );

      for (final batch in batches) {
        if (remainingToConsume <= 0) break;

        final batchId = batch['id'] as int;
        final currentQuantity = batch['cantidad'] as int;
        final quantityFromBatch = currentQuantity < remainingToConsume
            ? currentQuantity
            : remainingToConsume;

        await txn.update(
          'Lote_Producto',
          {'cantidad': currentQuantity - quantityFromBatch},
          where: 'id = ?',
          whereArgs: [batchId],
        );
        remainingToConsume -= quantityFromBatch;
        consumedQuantity += quantityFromBatch;
        remainingStock -= quantityFromBatch;
      }

      if (consumedQuantity == 0) return;

      await txn.insert('Historial_Consumos', {
        'producto_id': productId,
        'fecha_consumo': DateTime.now().toIso8601String(),
        'cantidad': consumedQuantity,
        'stock_restante': remainingStock,
      });
    });
  }

  // Eliminar producto
  Future<bool> deleteProduct(int id) async {
    final Database db = await _dbHelper.database;
    try {
      final rowsAffected = await db.delete('Producto', where: 'id = ?', whereArgs: [id]);
      return rowsAffected > 0;
    } catch (e) {
      // Si el borrado es bloqueado por llaves foráneas (ej. Historial), retornamos false
      return false;
    }
  }
}
