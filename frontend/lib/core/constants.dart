import 'package:flutter/foundation.dart';

/// Constantes compartidas de la app (posiciones, ciudades, URLs, etc.)
class AppConstants {
  // Base URL del backend según plataforma
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const List<String> posiciones = [
    'Portero',
    'Defensa Central',
    'Lateral Derecho',
    'Lateral Izquierdo',
    'Mediocampista Defensivo',
    'Mediocampista',
    'Mediocampista Ofensivo',
    'Extremo Derecho',
    'Extremo Izquierdo',
    'Segundo Delantero',
    'Delantero Centro',
  ];

  static const List<String> ciudades = [
    'Lima',
    'Arequipa',
    'Trujillo',
    'Chiclayo',
    'Piura',
    'Iquitos',
    'Cusco',
    'Huancayo',
    'Tacna',
    'Ica',
    'Callao',
    'Puno',
    'Cajamarca',
    'Chimbote',
    'Juliaca',
  ];

  static const List<String> tiposClub = ['club', 'campeon', 'subcampeon'];
}
