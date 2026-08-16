enum Rol { jugador, captador }

Rol rolFromString(String s) => s == 'jugador' ? Rol.jugador : Rol.captador;

class Usuario {
  final String id;
  final String nombre;
  final String celular;
  final Rol rol;

  Usuario({required this.id, required this.nombre, required this.celular, required this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        nombre: json['nombre'],
        celular: json['celular'],
        rol: rolFromString(json['rol']),
      );
}
