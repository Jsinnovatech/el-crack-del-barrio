class PerfilJugador {
  final String id;
  final String usuarioId;
  final String? fotoUrl;
  final String? dniUrl;
  final bool verificado;
  final String? bio;
  final String? posicionPrincipal;
  final List<String> posicionesSecundarias;
  final int? edad;
  final String? ciudad;
  final double rating;
  final String? planId;
  final int streak;

  PerfilJugador({
    required this.id,
    required this.usuarioId,
    this.fotoUrl,
    this.dniUrl,
    this.verificado = false,
    this.bio,
    this.posicionPrincipal,
    this.posicionesSecundarias = const [],
    this.edad,
    this.ciudad,
    this.rating = 0,
    this.planId,
    this.streak = 0,
  });

  PerfilJugador copyWith({
    String? fotoUrl,
    String? dniUrl,
    bool? verificado,
    String? bio,
    String? posicionPrincipal,
    List<String>? posicionesSecundarias,
    int? edad,
    String? ciudad,
    double? rating,
    String? planId,
    int? streak,
  }) =>
      PerfilJugador(
        id: id,
        usuarioId: usuarioId,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        dniUrl: dniUrl ?? this.dniUrl,
        verificado: verificado ?? this.verificado,
        bio: bio ?? this.bio,
        posicionPrincipal: posicionPrincipal ?? this.posicionPrincipal,
        posicionesSecundarias: posicionesSecundarias ?? this.posicionesSecundarias,
        edad: edad ?? this.edad,
        ciudad: ciudad ?? this.ciudad,
        rating: rating ?? this.rating,
        planId: planId ?? this.planId,
        streak: streak ?? this.streak,
      );

  factory PerfilJugador.fromJson(Map<String, dynamic> json) => PerfilJugador(
        id: json['id'],
        usuarioId: json['usuario_id'],
        fotoUrl: json['foto_url'],
        dniUrl: json['dni_url'],
        verificado: json['verificado'] ?? false,
        bio: json['bio'],
        posicionPrincipal: json['posicion_principal'],
        posicionesSecundarias: List<String>.from(json['posiciones_secundarias'] ?? []),
        edad: json['edad'],
        ciudad: json['ciudad'],
        rating: (json['rating'] ?? 0).toDouble(),
        planId: json['plan_id'],
        streak: json['streak'] ?? 0,
      );
}
