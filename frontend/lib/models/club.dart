class Club {
  final String id;
  final String jugadorId;
  final String nombre;
  final String tipo; // 'club' | 'campeon' | 'subcampeon'
  final int? anio;

  Club({
    required this.id,
    required this.jugadorId,
    required this.nombre,
    required this.tipo,
    this.anio,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'],
        jugadorId: json['jugador_id'] ?? '',
        nombre: json['nombre'],
        tipo: json['tipo'],
        anio: json['anio'],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'tipo': tipo,
        if (anio != null) 'anio': anio,
      };
}
