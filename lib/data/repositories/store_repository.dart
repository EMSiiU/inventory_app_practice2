// Archivo: lib/data/repositories/store_repository.dart

import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/store_model.dart';

class StoreRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Inserta una nueva tienda en la base de datos
  Future<int> insertStore(StoreModel store) async {
    final Database db = await _dbHelper.database;
    return await db.insert('Tienda', store.toMap());
  }

  // Obtiene todas las tiendas registradas
  Future<List<StoreModel>> getAllStores() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Tienda');
    return List.generate(maps.length, (i) => StoreModel.fromMap(maps[i]));
  }

  // Obtiene una tienda específica por su ID
  Future<StoreModel?> getStoreById(int id) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Tienda',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return StoreModel.fromMap(maps.first);
    }
    return null;
  }
}