class Notificacion {
  final String id;
  final String tipo;
  final String texto;
  final bool leido;
  final DateTime creadoEn;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.texto,
    required this.leido,
    required this.creadoEn,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'],
        tipo: json['tipo'],
        texto: json['texto'],
        leido: json['leido'] ?? false,
        creadoEn: DateTime.parse(json['creado_en']),
      );
}
