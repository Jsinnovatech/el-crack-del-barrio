class Historial {
  final String id;
  final String torneo;
  final String equipo;
  final int? anio;
  final String? posicion;
  final String? logro;

  const Historial({
    required this.id,
    required this.torneo,
    required this.equipo,
    this.anio,
    this.posicion,
    this.logro,
  });

  factory Historial.fromJson(Map<String, dynamic> j) => Historial(
        id: j['id'] as String,
        torneo: j['torneo'] as String,
        equipo: j['equipo'] as String,
        anio: j['anio'] as int?,
        posicion: j['posicion'] as String?,
        logro: j['logro'] as String?,
      );
}
