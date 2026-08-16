class Disponibilidad {
  final String id;
  final String jugadorId;
  final DateTime fecha;
  final String estado; // 'disponible' | 'contratado' | 'no_disponible'
  final String? horaDesde;
  final String? horaHasta;

  Disponibilidad({
    required this.id,
    required this.jugadorId,
    required this.fecha,
    required this.estado,
    this.horaDesde,
    this.horaHasta,
  });

  factory Disponibilidad.fromJson(Map<String, dynamic> json) => Disponibilidad(
        id: json['id'],
        jugadorId: json['jugador_id'] ?? '',
        fecha: DateTime.parse(json['fecha']),
        estado: json['estado'],
        horaDesde: json['hora_desde'],
        horaHasta: json['hora_hasta'],
      );

  Map<String, dynamic> toJson() => {
        'fecha':
            '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        'estado': estado,
        if (horaDesde != null) 'hora_desde': horaDesde,
        if (horaHasta != null) 'hora_hasta': horaHasta,
      };
}
