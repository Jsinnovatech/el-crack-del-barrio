class VideoJugador {
  final String id;
  final String titulo;
  final String? thumbUrl;
  final String? videoUrl;
  final int vistas;
  final bool destacado;
  final int orden;

  VideoJugador({
    required this.id,
    required this.titulo,
    this.thumbUrl,
    this.videoUrl,
    this.vistas = 0,
    this.destacado = false,
    this.orden = 0,
  });

  factory VideoJugador.fromJson(Map<String, dynamic> json) => VideoJugador(
        id: json['id'],
        titulo: json['titulo'],
        thumbUrl: json['thumb_url'],
        videoUrl: json['video_url'],
        vistas: json['vistas'] ?? 0,
        destacado: json['destacado'] ?? false,
        orden: json['orden'] ?? 0,
      );
}
