class CategoryModel {
  final int? id;
  final String name;
  final String? icon;
  final String? colorHex;

  CategoryModel({
    this.id,
    required this.name,
    this.icon,
    this.colorHex,
  });

  // Convierte un objeto CategoryModel a un Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'icono': icon,
      'color_hex': colorHex,
    };
  }

  // Crea un objeto CategoryModel a partir de un Map de SQLite
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['nombre'],
      icon: map['icono'],
      colorHex: map['color_hex'],
    );
  }
}