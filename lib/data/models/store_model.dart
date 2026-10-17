class StoreModel {
  final int? id;
  final String name;
  final String? location;
  final String? icon;

  StoreModel({this.id, required this.name, this.location, this.icon});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': name, 'ubicacion': location, 'icono': icon};
  }

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      id: map['id'],
      name: map['nombre'],
      location: map['ubicacion'],
      icon: map['icono'],
    );
  }
}
