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
             COALESCE(SUM(l.cantidad), 0) as stock_total 
      FROM Producto p
      LEFT JOIN Lote_Producto l ON p.id = l.producto_id AND l.cantidad > 0
      GROUP BY p.id
    ''';
    
    return await db.rawQuery(query);
  }

  // Consume unidades de un producto descontando del lote que caduca primero (FEFO)
  Future<void> consumeProductFefo(int productId, int quantityToConsume) async {
    final Database db = await _dbHelper.database;
    
    // Obtiene lotes activos ordenados por la fecha de caducidad más próxima
    final List<Map<String, dynamic>> batches = await db.query(
      'Lote_Producto',
      where: 'producto_id = ? AND cantidad > 0',
      whereArgs: [productId],
      orderBy: 'fecha_caducidad ASC',
    );

    int remainingToConsume = quantityToConsume;

    for (var batch in batches) {
      if (remainingToConsume <= 0) break;

      int batchId = batch['id'];
      int currentQuantity = batch['cantidad'];

      if (currentQuantity <= remainingToConsume) {
        // El lote se agota por completo
        await db.update(
          'Lote_Producto',
          {'cantidad': 0},
          where: 'id = ?',
          whereArgs: [batchId],
        );
        remainingToConsume -= currentQuantity;
      } else {
        // Se descuenta solo una parte del lote, quedando aún stock disponible
        await db.update(
          'Lote_Producto',
          {'cantidad': currentQuantity - remainingToConsume},
          where: 'id = ?',
          whereArgs: [batchId],
        );
        remainingToConsume = 0;
      }
    }
  }
}