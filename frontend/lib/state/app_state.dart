import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/jugador_explorar.dart';
import '../models/perfil_jugador.dart';
import '../models/usuario.dart';

/// Estado global de sesión y acciones comunes.
class AppState extends ChangeNotifier {
  Usuario? usuario;
  PerfilJugador? miPerfilJugador;
  bool cargando = true;
  String? error;

  // IDs de jugadores marcados como favoritos (para el captador)
  final Set<String> _favoritosIds = {};
  Set<String> get favoritosIds => _favoritosIds;

  // Lista de jugadores para comparar (máx 3)
  final List<JugadorExplorar> _comparar = [];
  List<JugadorExplorar> get comparar => List.unmodifiable(_comparar);

  bool get autenticado => usuario != null;

  Future<void> cargarSesion() async {
    cargando = true;
    notifyListeners();
    final token = await ApiClient.instance.obtenerToken();
    if (token != null) {
      try {
        final res = await ApiClient.instance.dio.get('/auth/yo');
        usuario = Usuario.fromJson(res.data);
        if (usuario!.rol == Rol.jugador) {
          final perfilRes = await ApiClient.instance.dio.get('/jugadores/me');
          miPerfilJugador = PerfilJugador.fromJson(perfilRes.data);
        }
      } catch (_) {
        await ApiClient.instance.borrarToken();
        usuario = null;
      }
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> login(String celular, String codigo) async {
    error = null;
    final res = await ApiClient.instance.dio.post('/auth/login', data: {
      'celular': celular,
      'codigo': codigo,
    });
    await ApiClient.instance.guardarToken(res.data['access_token']);
    usuario = Usuario.fromJson(res.data['usuario']);
    notifyListeners();
  }

  Future<void> registrar(String nombre, String celular, Rol rol) async {
    error = null;
    final res = await ApiClient.instance.dio.post('/auth/registro', data: {
      'nombre': nombre,
      'celular': celular,
      'rol': rol == Rol.jugador ? 'jugador' : 'captador',
    });
    await ApiClient.instance.guardarToken(res.data['access_token']);
    usuario = Usuario.fromJson(res.data['usuario']);
    notifyListeners();
  }

  Future<void> recargarPerfil() async {
    if (usuario?.rol != Rol.jugador) return;
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me');
      miPerfilJugador = PerfilJugador.fromJson(res.data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cerrarSesion() async {
    await ApiClient.instance.borrarToken();
    usuario = null;
    miPerfilJugador = null;
    _favoritosIds.clear();
    _comparar.clear();
    notifyListeners();
  }

  // ── Favoritos ────────────────────────────────────────────────────────────
  Future<void> toggleFavorito(String jugadorId) async {
    final esFavorito = _favoritosIds.contains(jugadorId);
    // Actualizar UI optimistamente
    if (esFavorito) {
      _favoritosIds.remove(jugadorId);
    } else {
      _favoritosIds.add(jugadorId);
    }
    notifyListeners();

    try {
      if (esFavorito) {
        await ApiClient.instance.dio.delete('/captadores/me/favoritos/$jugadorId');
      } else {
        await ApiClient.instance.dio.post('/captadores/me/favoritos/$jugadorId');
      }
    } catch (_) {
      // Revertir si falla
      if (esFavorito) {
        _favoritosIds.add(jugadorId);
      } else {
        _favoritosIds.remove(jugadorId);
      }
      notifyListeners();
    }
  }

  void quitarFavorito(String jugadorId) {
    _favoritosIds.remove(jugadorId);
    notifyListeners();
  }

  // ── Comparar ─────────────────────────────────────────────────────────────
  bool addComparar(JugadorExplorar jugador) {
    if (_comparar.any((j) => j.id == jugador.id)) return false;
    if (_comparar.length >= 3) return false;
    _comparar.add(jugador);
    notifyListeners();
    return true;
  }

  void removeComparar(String jugadorId) {
    _comparar.removeWhere((j) => j.id == jugadorId);
    notifyListeners();
  }

  void clearComparar() {
    _comparar.clear();
    notifyListeners();
  }
}
