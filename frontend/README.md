# El Crack del Barrio — Frontend (Flutter)

App móvil para jugadores y captadores de fútbol. Traduce a Flutter las pantallas
del prototipo (`vitrina_deportiva.html`) y consume la API FastAPI del backend.

## Stack

- **Flutter** (Dart) — UI móvil multiplataforma
- **provider** — estado global (sesión de usuario)
- **dio** — cliente HTTP hacia el backend
- **shared_preferences** — persistencia del token de sesión
- **table_calendar** — calendario de disponibilidad
- **fl_chart** — sparkline y embudo de captación (pendiente de implementar en UI)
- **image_picker** — subida de foto/DNI/videos (pendiente de implementar)
- **url_launcher** — abrir WhatsApp para contactar jugadores

## Estructura

```
frontend/
├── lib/
│   ├── core/
│   │   ├── api_client.dart     # Dio + interceptor de token JWT
│   │   ├── app_theme.dart      # tema dark mode (mismos colores del prototipo)
│   │   └── constants.dart
│   ├── models/                  # Usuario, PerfilJugador, VideoJugador, Plan
│   ├── state/
│   │   └── app_state.dart       # sesión global (Provider/ChangeNotifier)
│   ├── screens/
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── player/               # Home, Perfil, Videos, Calendario, Planes
│   │   └── scout/                # Home, Explorar, Favoritos, Cuenta
│   ├── widgets/                  # componentes reutilizables
│   └── main.dart
├── pubspec.yaml
└── analysis_options.yaml
```

> **Nota:** este scaffold no incluye las carpetas nativas `android/`, `ios/`, etc.
> Para generarlas: crea un proyecto Flutter vacío y copia `lib/` y `pubspec.yaml`
> encima, o corre `flutter create .` en esta misma carpeta (ver pasos abajo).

## Cómo correrlo localmente

```bash
# 1) Si no existen las carpetas nativas todavía:
flutter create . --project-name crack_del_barrio --org com.jsalasinnovatech

# 2) Instala dependencias
flutter pub get

# 3) Corre contra el backend local
#    - Emulador Android: usa 10.0.2.2 (ya configurado en lib/core/api_client.dart)
#    - iOS / dispositivo físico: cambia baseUrl a la IP de tu máquina
flutter run
```

## Notas de implementación (para continuar en Claude Code / Windsurf)

- **Auth**: `AppState.cargarSesion()` intenta restaurar la sesión con el token
  guardado en `shared_preferences`. El login usa OTP (ver backend `OTP_DEV_CODE`
  para desarrollo).
- **Pantallas con TODO explícito** (ya marcadas en el código):
  - `player_videos_screen.dart`: falta integrar `image_picker` para subir video real.
  - `player_calendar_screen.dart`: falta vista semanal rápida y aviso de calendario
    desactualizado (>5 días), igual que en el prototipo.
  - `player_plans_screen.dart`: el pago está simulado (crea + confirma en el mismo
    flujo); en producción la confirmación debe llegar por webhook del proveedor.
  - `scout_explore_screen.dart`: falta el bottom sheet de filtros avanzados, la
    vista de mapa y el comparador de hasta 3 jugadores.
  - `scout_favorites_screen.dart`: falta hacer join con `/jugadores/{id}` para
    mostrar nombre/foto reales en vez del ID crudo.
  - `scout_account_screen.dart`: falta el listado de pruebas agendadas con chip
    de estado, y el gestor de alertas de talento.
  - `scout_home_screen.dart`: falta el embudo de conversión con `fl_chart`
    (vistos → contactados → pruebas), igual que en el prototipo.
- **Detalle de perfil de jugador** (vista pública que ve el captador): aún no
  existe como pantalla; falta crearla y conectarla desde `scout_explore_screen.dart`.
- Todos los nombres de campos JSON coinciden 1:1 con los schemas Pydantic del
  backend (snake_case), así que los modelos Dart (`lib/models/`) son el único
  lugar que necesita actualizarse si el backend cambia un contrato.

## Convenciones

- Comentarios y nombres de variables en español, igual que el resto del proyecto.
- Widgets de pantalla completa van en `screens/`; piezas reutilizables en `widgets/`.
- Un modelo Dart por archivo en `models/`, con `fromJson` manual (sin generación
  de código) para mantener el proyecto simple de abrir en cualquier editor.
