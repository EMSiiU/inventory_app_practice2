import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final versionDB = 1;
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Obtiene la instancia de la base de datos, la inicializa si no existe
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory_app.db');
    return _database!;
  }

  // Inicializa la base de datos en el almacenamiento local del dispositivo
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: versionDB,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  // Habilita el soporte para llaves foráneas en SQLite
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Ejecuta los scripts de creación de tablas e índices
  Future _createDB(Database db, int version) async {
    // 1. Tabla Categoria
    await db.execute('''
      CREATE TABLE Categoria (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          icono TEXT,
          color_hex TEXT
      )
    ''');

    // 2. Tabla Tienda
    await db.execute('''
      CREATE TABLE Tienda (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          ubicacion TEXT,
          icono TEXT
      )
    ''');

    // 3. Tabla Producto
    await db.execute('''
      CREATE TABLE Producto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria_id INTEGER NOT NULL,
          imagen_url TEXT,
          stock_seguridad INTEGER DEFAULT 1,
          ultima_tienda_id INTEGER,
          alarma_activa INTEGER DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE RESTRICT,
          FOREIGN KEY (ultima_tienda_id) REFERENCES Tienda(id) ON DELETE SET NULL
      )
    ''');

    // 4. Tabla Lote_Producto
    await db.execute('''
      CREATE TABLE Lote_Producto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER NOT NULL,
          codigo_lote TEXT,
          fecha_caducidad DATE NOT NULL,
          cantidad INTEGER NOT NULL CHECK (cantidad >= 0),
          tienda_id INTEGER,
          FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE,
          FOREIGN KEY (tienda_id) REFERENCES Tienda(id) ON DELETE SET NULL
      )
    ''');

    // 5. Tabla Historial_Compras
    await db.execute('''
      CREATE TABLE Historial_Compras (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER NOT NULL,
          tienda_id INTEGER NOT NULL,
          fecha_compra DATETIME DEFAULT CURRENT_TIMESTAMP,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL,
          FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE,
          FOREIGN KEY (tienda_id) REFERENCES Tienda(id) ON DELETE RESTRICT
      )
    ''');

    // Creación de Índices
    await db.execute('CREATE INDEX idx_lote_caducidad ON Lote_Producto(fecha_caducidad, cantidad)');
    await db.execute('CREATE INDEX idx_producto_categoria ON Producto(categoria_id)');
  }

  // Cierra la conexión a la base de datos
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}