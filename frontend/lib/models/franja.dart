class Franja {
  final String id;
  final DateTime fecha;
  final String? horaInicio;
  final String? horaFin;
  final String estado; // "ocupado" | "libre"
  final String? descripcion;

  const Franja({
    required this.id,
    required this.fecha,
    this.horaInicio,
    this.horaFin,
    required this.estado,
    this.descripcion,
  });

  factory Franja.fromJson(Map<String, dynamic> j) => Franja(
        id: j['id'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        horaInicio: j['hora_inicio'] as String?,
        horaFin: j['hora_fin'] as String?,
        estado: j['estado'] as String,
        descripcion: j['descripcion'] as String?,
      );

  bool get esOcupado => estado == 'ocupado';
}
