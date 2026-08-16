/// Modelo simplificado de jugador usado en la exploración y listas del captador.
class JugadorExplorar {
  final String id;
  final String nombreUsuario;
  final String? fotoUrl;
  final String? posicionPrincipal;
  final List<String> posicionesSecundarias;
  final int? edad;
  final String? ciudad;
  final double rating;
  final bool verificado;
  final String? planId;

  JugadorExplorar({
    required this.id,
    required this.nombreUsuario,
    this.fotoUrl,
    this.posicionPrincipal,
    this.posicionesSecundarias = const [],
    this.edad,
    this.ciudad,
    this.rating = 0,
    this.verificado = false,
    this.planId,
  });

  factory JugadorExplorar.fromJson(Map<String, dynamic> json) => JugadorExplorar(
        id: json['id'],
        nombreUsuario: json['nombre_usuario'] ?? 'Jugador',
        fotoUrl: json['foto_url'],
        posicionPrincipal: json['posicion_principal'],
        posicionesSecundarias: List<String>.from(json['posiciones_secundarias'] ?? []),
        edad: json['edad'],
        ciudad: json['ciudad'],
        rating: (json['rating'] ?? 0).toDouble(),
        verificado: json['verificado'] ?? false,
        planId: json['plan_id'],
      );
}
