import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/stat_card.dart';
import 'player_profile_screen.dart';
import 'player_historial_screen.dart';
import 'player_videos_screen.dart';
import 'player_calendar_screen.dart';
import 'player_fotos_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardTab(onNavegar: (i) => setState(() => _index = i)),
      const PlayerProfileScreen(),
      const PlayerHistorialScreen(),
      const PlayerVideosScreen(),
      const PlayerCalendarScreen(),
      const PlayerFotosScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Horario'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library_rounded), label: 'Fotos'),
        ],
      ),
    );
  }
}

// ─── Dashboard (tab 0) ───────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final void Function(int) onNavegar;
  const _DashboardTab({required this.onNavegar});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _cargando = true;
  int _videos = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/videos');
      setState(() {
        _videos = (res.data as List).length;
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hola,', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  Text(nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
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
                    StatCard(icon: Icons.videocam_rounded, value: '$_videos / 5', label: 'Videos', iconColor: AppColors.info),
                    StatCard(icon: Icons.verified_rounded, value: (perfil?.verificado ?? false) ? 'Sí' : 'No', label: 'Verificado', iconColor: AppColors.success),
                    StatCard(icon: Icons.local_fire_department_rounded, value: '${perfil?.streak ?? 0}', label: 'Días activo', iconColor: AppColors.warning),
                  ],
                ),
          const SectionLabel('Accesos rápidos'),
          Card(
            child: Column(
              children: [
                _AccesoRapido(
                  icon: Icons.person_rounded,
                  label: 'Completar mi perfil',
                  sub: 'Foto, teléfono, bio y posiciones',
                  onTap: () => widget.onNavegar(1),
                ),
                const Divider(height: 1),
                _AccesoRapido(
                  icon: Icons.emoji_events_rounded,
                  label: 'Mi historial deportivo',
                  sub: 'Ligas, torneos y logros',
                  onTap: () => widget.onNavegar(2),
                ),
                const Divider(height: 1),
                _AccesoRapido(
                  icon: Icons.videocam_rounded,
                  label: 'Subir jugadas destacadas',
                  sub: 'Máximo 5 videos',
                  onTap: () => widget.onNavegar(3),
                ),
                const Divider(height: 1),
                _AccesoRapido(
                  icon: Icons.calendar_month_rounded,
                  label: 'Actualizar disponibilidad',
                  sub: 'Franjas ocupado / libre',
                  onTap: () => widget.onNavegar(4),
                ),
                const Divider(height: 1),
                _AccesoRapido(
                  icon: Icons.photo_library_rounded,
                  label: 'Galería de equipos',
                  sub: 'Hasta 8 fotos con reseña',
                  onTap: () => widget.onNavegar(5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Perfil incompleto — aviso
          if (perfil != null && (perfil.telefono == null || perfil.posicionPrincipal == null))
            Container(
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Completa tu perfil para que los captadores puedan contactarte.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavegar(1),
                    child: const Text('Ir'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _AccesoRapido({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
