class ProductModel {
  final int? id;
  final String name;
  final int categoryId;
  final String? imageUrl;
  final int securityStock;
  final int? lastStoreId;
  final bool isAlarmActive;
  final DateTime? createdAt;
  final String? categoryName;
  final String? lastStoreName;

  ProductModel({
    this.id,
    required this.name,
    required this.categoryId,
    this.imageUrl,
    this.securityStock = 1,
    this.lastStoreId,
    this.isAlarmActive = true,
    this.createdAt,
    this.categoryName,
    this.lastStoreName
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'categoria_id': categoryId,
      'imagen_url': imageUrl,
      'stock_seguridad': securityStock,
      'ultima_tienda_id': lastStoreId,
      'alarma_activa': isAlarmActive ? 1 : 0, // no se maneja booleanos nativos
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['nombre'],
      categoryId: map['categoria_id'],
      imageUrl: map['imagen_url'],
      securityStock: map['stock_seguridad'],
      lastStoreId: map['ultima_tienda_id'],
      isAlarmActive: map['alarma_activa'] == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      categoryName: map['category_name'],
      lastStoreName: map['last_store_name']
    );
  }
}