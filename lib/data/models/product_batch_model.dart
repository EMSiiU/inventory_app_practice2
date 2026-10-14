class ProductBatchModel {
  final int? id;
  final int productId;
  final String? batchCode;
  final DateTime expirationDate;
  final int quantity;
  final int? storeId;
  final String? productName;

  ProductBatchModel({
    this.id,
    required this.productId,
    this.batchCode,
    required this.expirationDate,
    required this.quantity,
    this.storeId,
    this.productName
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productId,
      'codigo_lote': batchCode,
      'fecha_caducidad': expirationDate.toIso8601String().split('T').first, // Formato DATE
      'cantidad': quantity,
      'tienda_id': storeId,
    };
  }

  factory ProductBatchModel.fromMap(Map<String, dynamic> map) {
    return ProductBatchModel(
      id: map['id'],
      productId: map['producto_id'],
      batchCode: map['codigo_lote'],
      expirationDate: DateTime.parse(map['fecha_caducidad']),
      quantity: map['cantidad'],
      storeId: map['tienda_id'],
      productName: map['productName'],
    );
  }
}