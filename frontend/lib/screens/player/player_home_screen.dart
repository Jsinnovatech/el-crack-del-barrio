import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/stat_card.dart';
import 'player_calendar_screen.dart';
import 'player_plans_screen.dart';
import 'player_profile_screen.dart';
import 'player_videos_screen.dart';

/// Contenedor con la navegación inferior del rol Jugador.
/// Refleja 1:1 la barra inferior del prototipo: Inicio, Perfil, Videos, Calendario, Plan.
class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _index = 0;

  final _pages = const [
    _PlayerHomeTab(),
    PlayerProfileScreen(),
    PlayerVideosScreen(),
    PlayerCalendarScreen(),
    PlayerPlansScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Plan'),
        ],
      ),
    );
  }
}

class _PlayerHomeTab extends StatefulWidget {
  const _PlayerHomeTab();

  @override
  State<_PlayerHomeTab> createState() => _PlayerHomeTabState();
}

class _PlayerHomeTabState extends State<_PlayerHomeTab> {
  bool _cargando = true;
  List<dynamic> _videos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/videos');
      setState(() {
        _videos = res.data;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final perfil = app.miPerfilJugador;
    final nombre = app.usuario?.nombre.split(' ').first ?? '';

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hola, $nombre 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => context.read<AppState>().cerrarSesion(),
              ),
            ],
          ),
          const SectionLabel('Tu resumen'),
          _cargando
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    StatCard(icon: Icons.star_rounded, value: (perfil?.rating ?? 0).toStringAsFixed(1), label: 'Calificación', iconColor: AppColors.gold),
                    StatCard(icon: Icons.videocam_rounded, value: '${_videos.length}', label: 'Videos subidos', iconColor: AppColors.info),
                    StatCard(icon: Icons.verified_rounded, value: (perfil?.verificado ?? false) ? 'Sí' : 'No', label: 'Verificado', iconColor: AppColors.success),
                    StatCard(icon: Icons.local_fire_department_rounded, value: '${perfil?.streak ?? 0}', label: 'Días activo', iconColor: AppColors.warning),
                  ],
                ),
          const SectionLabel('Accesos rápidos'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.videocam_rounded, color: AppColors.accent),
                  title: const Text('Subir jugadas destacadas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: navegar a la pestaña de Videos
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.accent),
                  title: const Text('Actualizar disponibilidad'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: navegar a la pestaña de Calendario
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
