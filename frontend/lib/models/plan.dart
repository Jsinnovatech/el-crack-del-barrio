class Plan {
  final String id;
  final String nombre;
  final double precio;
  final String unidad;
  final List<String> beneficios;
  final bool destacado;

  Plan({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.unidad,
    this.beneficios = const [],
    this.destacado = false,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'],
        nombre: json['nombre'],
        precio: (json['precio'] ?? 0).toDouble(),
        unidad: json['unidad'],
        beneficios: List<String>.from(json['beneficios'] ?? []),
        destacado: json['destacado'] ?? false,
      );
}
