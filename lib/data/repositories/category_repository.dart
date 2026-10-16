import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Inserta una nueva categoría en la base de datos
  Future<int> insertCategory(CategoryModel category) async {
    final Database db = await _dbHelper.database;
    return await db.insert('Categoria', category.toMap());
  }

  // Obtiene todas las categorías registradas
  Future<List<CategoryModel>> getAllCategories() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Categoria');
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  Future<int> getOrCreateDefaultCategoryId() async {
    final Database db = await _dbHelper.database;

    return db.transaction((transaction) async {
      final categories = await transaction.query(
        'Categoria',
        columns: ['id'],
        orderBy: 'id ASC',
        limit: 1,
      );

      if (categories.isNotEmpty) {
        return categories.first['id'] as int;
      }

      return transaction.insert('Categoria', {'nombre': 'Despensa'});
    });
  }

  // Eliminar
  Future<bool> deleteCategory(int id) async {
    final Database db = await _dbHelper.database;
    try {
      final rowsAffected = await db.delete('Categoria', where: 'id = ?', whereArgs: [id]);
      return rowsAffected > 0;
    } catch (e) {
      // Si entra aquí, es porque SQLite bloqueó el borrado por el ON DELETE RESTRICT
      return false; 
    }
  }
}