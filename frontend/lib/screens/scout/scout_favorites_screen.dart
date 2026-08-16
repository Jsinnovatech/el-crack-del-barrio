import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../models/jugador_explorar.dart';
import '../../state/app_state.dart';
import '../../widgets/player_card.dart';
import 'scout_player_detail_screen.dart';

class ScoutFavoritesScreen extends StatefulWidget {
  const ScoutFavoritesScreen({super.key});

  @override
  State<ScoutFavoritesScreen> createState() => _ScoutFavoritesScreenState();
}

class _ScoutFavoritesScreenState extends State<ScoutFavoritesScreen> {
  List<JugadorExplorar> _favoritos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/captadores/me/favoritos');
      setState(() {
        _favoritos = (res.data as List).map((e) => JugadorExplorar.fromJson(e)).toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favIds = context.watch<AppState>().favoritosIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Text('Favoritos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _favoritos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('Aún no guardaste favoritos',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                          SizedBox(height: 6),
                          Text('Explora jugadores y guarda los que te interesen.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _favoritos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final j = _favoritos[i];
                          return Dismissible(
                            key: Key(j.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_rounded, color: AppColors.danger),
                            ),
                            onDismissed: (_) async {
                              setState(() => _favoritos.removeAt(i));
                              try {
                                await ApiClient.instance.dio
                                    .delete('/captadores/me/favoritos/${j.id}');
                                context.read<AppState>().quitarFavorito(j.id);
                              } catch (_) {
                                // Recargar si falla
                                _cargar();
                              }
                            },
                            child: PlayerCard(
                              jugador: j,
                              isFavorito: favIds.contains(j.id),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ScoutPlayerDetailScreen(jugador: j),
                                ),
                              ),
                              onFavorito: () => context.read<AppState>().toggleFavorito(j.id),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
