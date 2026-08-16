import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'models/usuario.dart';
import 'screens/onboarding_screen.dart';
import 'screens/player/player_home_screen.dart';
import 'screens/scout/scout_home_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const CrackDelBarrioApp(),
    ),
  );
}

class CrackDelBarrioApp extends StatefulWidget {
  const CrackDelBarrioApp({super.key});

  @override
  State<CrackDelBarrioApp> createState() => _CrackDelBarrioAppState();
}

class _CrackDelBarrioAppState extends State<CrackDelBarrioApp> {
  @override
  void initState() {
    super.initState();
    // Intenta restaurar sesión guardada (token en SharedPreferences).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().cargarSesion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Crack del Barrio',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _RaizApp(),
    );
  }
}

class _RaizApp extends StatelessWidget {
  const _RaizApp();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!app.autenticado) {
      return const OnboardingScreen();
    }
    if (app.usuario!.rol == Rol.jugador) {
      return const PlayerHomeScreen();
    }
    return const ScoutHomeScreen();
  }
}
