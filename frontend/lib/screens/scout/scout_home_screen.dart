import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../models/jugador_explorar.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';
import 'scout_account_screen.dart';
import 'scout_explore_screen.dart';
import 'scout_favorites_screen.dart';
import 'scout_player_detail_screen.dart';

class ScoutHomeScreen extends StatefulWidget {
  const ScoutHomeScreen({super.key});

  @override
  State<ScoutHomeScreen> createState() => _ScoutHomeScreenState();
}

class _ScoutHomeScreenState extends State<ScoutHomeScreen> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _ScoutHomeTab(onGoToExplorar: () => setState(() => _index = 1)),
      const ScoutExploreScreen(),
      const ScoutFavoritesScreen(),
      const ScoutAccountScreen(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Cuenta'),
        ],
      ),
    );
  }
}

class _ScoutHomeTab extends StatefulWidget {
  final VoidCallback onGoToExplorar;
  const _ScoutHomeTab({required this.onGoToExplorar});

  @override
  State<_ScoutHomeTab> createState() => _ScoutHomeTabState();
}

class _ScoutHomeTabState extends State<_ScoutHomeTab> {
  List<JugadorExplorar> _recomendados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.instance.dio.post('/captadores/explorar', data: {
        'orden': 'rating',
        'edad_min': 16,
        'edad_max': 40,
        'solo_verificados': false,
        'rating_min': 0,
      });
      setState(() {
        _recomendados = (res.data as List)
            .take(10)
            .map((e) => JugadorExplorar.fromJson(e))
            .toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final nombre = app.usuario?.nombre.split(' ').first ?? '';

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Top bar
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
                onPressed: () => app.cerrarSesion(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Banner hero
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x28F5B400), Color(0x0D22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: const Color(0x3AF5B400)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Descubre el próximo talento',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Explora jugadores verificados de todo el país.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: widget.onGoToExplorar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF1C1300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Explorar ahora', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SectionLabel('Acciones rápidas'),

          // Quick actions grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _QAItem(Icons.search_rounded, 'Explorar', AppColors.accent, widget.onGoToExplorar),
              _QAItem(Icons.favorite_rounded, 'Favoritos', const Color(0xFFFF4D6D), () {}),
              _QAItem(Icons.calendar_month_rounded, 'Pruebas', AppColors.gold, () {}),
              _QAItem(Icons.notifications_rounded, 'Alertas', AppColors.info, () {}),
            ],
          ),

          // Recomendados
          const SectionLabel('Recomendados hoy'),
          if (_cargando)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.accent)))
          else if (_recomendados.isEmpty)
            const Text('No hay recomendados aún.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recomendados.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final j = _recomendados[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ScoutPlayerDetailScreen(jugador: j)),
                    ),
                    child: Container(
                      width: 132,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: j.fotoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: j.fotoUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(color: AppColors.bgElevated),
                                    errorWidget: (_, __, ___) =>
                                        Container(color: AppColors.bgElevated),
                                  )
                                : Container(color: AppColors.bgElevated),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(j.nombreUsuario,
                                    style: const TextStyle(
                                        fontSize: 12.5, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(j.posicionPrincipal ?? '',
                                    style: const TextStyle(
                                        fontSize: 10.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _QAItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QAItem(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 5),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
