class FotoEquipo {
  final String id;
  final String urlFoto;
  final String? resena;
  final int orden;

  const FotoEquipo({
    required this.id,
    required this.urlFoto,
    this.resena,
    required this.orden,
  });

  factory FotoEquipo.fromJson(Map<String, dynamic> j) => FotoEquipo(
        id: j['id'] as String,
        urlFoto: j['url_foto'] as String,
        resena: j['resena'] as String?,
        orden: j['orden'] as int? ?? 0,
      );
}
