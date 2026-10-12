// Archivo: lib/data/repositories/batch_repository.dart

import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/product_batch_model.dart';

class BatchRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Inserta un nuevo lote para un producto específico
  Future<int> insertBatch(ProductBatchModel batch) async {
    final Database db = await _dbHelper.database;
    return await db.insert('Lote_Producto', batch.toMap());
  }

  // Obtiene todos los lotes activos (cantidad > 0) de todos los productos
  Future<List<ProductBatchModel>> getAllActiveBatches() async{
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Lote_Producto',
      where: 'cantidad > 0',
    );

    return List.generate(maps.length, (i) => ProductBatchModel.fromMap(maps[i]));
  }

  // Obtiene todos los lotes activos (cantidad > 0) de un producto
  Future<List<ProductBatchModel>> getActiveBatchesByProductId(int productId) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Lote_Producto',
      where: 'producto_id = ? AND cantidad > 0',
      whereArgs: [productId],
      orderBy: 'fecha_caducidad ASC', // Ordena para visualizar FEFO
    );
    
    return List.generate(maps.length, (i) => ProductBatchModel.fromMap(maps[i]));
  }

  // Obtiene los lotes que caducan en una fecha específica (para el calendario de alertas)
  Future<List<ProductBatchModel>> getBatchesExpiringOnDate(DateTime date) async {
    final Database db = await _dbHelper.database;
    final String dateString = date.toIso8601String().split('T').first;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'Lote_Producto',
      where: 'fecha_caducidad = ? AND cantidad > 0',
      whereArgs: [dateString],
    );

    return List.generate(maps.length, (i) => ProductBatchModel.fromMap(maps[i]));
  }
}