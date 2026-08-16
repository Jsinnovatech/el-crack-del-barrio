class Prueba {
  final String id;
  final String jugadorId;
  final DateTime? fecha;
  final String? hora;
  final String? lugar;
  final String estado; // 'pendiente' | 'confirmada' | 'realizada'

  Prueba({
    required this.id,
    required this.jugadorId,
    this.fecha,
    this.hora,
    this.lugar,
    required this.estado,
  });

  factory Prueba.fromJson(Map<String, dynamic> json) => Prueba(
        id: json['id'],
        jugadorId: json['jugador_id'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
        hora: json['hora'],
        lugar: json['lugar'],
        estado: json['estado'] ?? 'pendiente',
      );

  /// Cicla el estado en orden: pendiente → confirmada → realizada
  String get siguienteEstado {
    switch (estado) {
      case 'pendiente':
        return 'confirmada';
      case 'confirmada':
        return 'realizada';
      default:
        return 'realizada';
    }
  }
}
