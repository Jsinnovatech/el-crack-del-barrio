import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/jugador_explorar.dart';
import '../../widgets/rating_stars.dart';
import 'scout_player_detail_screen.dart';

class ScoutCompareScreen extends StatelessWidget {
  final List<JugadorExplorar> jugadores;

  const ScoutCompareScreen({super.key, required this.jugadores});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: const Text('Comparar jugadores',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Cabeceras de jugadores
              Row(
                children: [
                  const SizedBox(width: 110), // espacio para etiquetas
                  ...jugadores.map((j) => Expanded(child: _HeaderJugador(jugador: j))),
                ],
              ),
              const SizedBox(height: 20),
              _FilaComparacion(
                label: 'Rating',
                valores: jugadores.map((j) => j.rating.toStringAsFixed(1)).toList(),
                destacar: _indexMayor(jugadores.map((j) => j.rating).toList()),
                icono: Icons.star_rounded,
                iconColor: AppColors.gold,
              ),
              _FilaComparacion(
                label: 'Posición',
                valores: jugadores.map((j) => j.posicionPrincipal ?? '—').toList(),
                icono: Icons.sports_soccer_rounded,
                iconColor: AppColors.accent,
              ),
              _FilaComparacion(
                label: 'Edad',
                valores: jugadores.map((j) => j.edad != null ? '${j.edad} años' : '—').toList(),
                destacar: _indexMenor(jugadores.map((j) => j.edad?.toDouble() ?? 99).toList()),
                icono: Icons.cake_rounded,
                iconColor: AppColors.info,
              ),
              _FilaComparacion(
                label: 'Ciudad',
                valores: jugadores.map((j) => j.ciudad ?? '—').toList(),
                icono: Icons.location_on_rounded,
                iconColor: AppColors.textMuted,
              ),
              _FilaComparacion(
                label: 'Verificado',
                valores: jugadores.map((j) => j.verificado ? '✓ Sí' : '✗ No').toList(),
                destacar: _indexVerificado(jugadores),
                icono: Icons.verified_rounded,
                iconColor: AppColors.gold,
              ),
              _FilaComparacion(
                label: 'Plan',
                valores: jugadores.map((j) => _labelPlan(j.planId)).toList(),
                icono: Icons.workspace_premium_rounded,
                iconColor: AppColors.accent,
              ),
              const SizedBox(height: 24),
              // Botones para ver perfil de cada jugador
              Row(
                children: [
                  const SizedBox(width: 110),
                  ...jugadores.map(
                    (j) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScoutPlayerDetailScreen(jugador: j),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Ver perfil',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _indexMayor(List<double> valores) {
    if (valores.isEmpty) return null;
    double max = valores[0];
    int idx = 0;
    for (int i = 1; i < valores.length; i++) {
      if (valores[i] > max) {
        max = valores[i];
        idx = i;
      }
    }
    return max > 0 ? idx : null;
  }

  int? _indexMenor(List<double> valores) {
    if (valores.isEmpty) return null;
    double min = valores[0];
    int idx = 0;
    for (int i = 1; i < valores.length; i++) {
      if (valores[i] < min) {
        min = valores[i];
        idx = i;
      }
    }
    return min < 99 ? idx : null;
  }

  int? _indexVerificado(List<JugadorExplorar> jugadores) {
    final idx = jugadores.indexWhere((j) => j.verificado);
    return idx >= 0 ? idx : null;
  }

  String _labelPlan(String? planId) {
    if (planId == null) return 'Gratis';
    return 'Premium';
  }
}

class _HeaderJugador extends StatelessWidget {
  final JugadorExplorar jugador;
  const _HeaderJugador({required this.jugador});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: AppColors.bgElevated,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: jugador.fotoUrl != null
                ? CachedNetworkImage(
                    imageUrl: jugador.fotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 32),
                  )
                : const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            jugador.nombreUsuario,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          RatingStars(rating: jugador.rating, size: 12),
        ],
      ),
    );
  }
}

class _FilaComparacion extends StatelessWidget {
  final String label;
  final List<String> valores;
  final int? destacar; // índice del mejor valor
  final IconData icono;
  final Color iconColor;

  const _FilaComparacion({
    required this.label,
    required this.valores,
    this.destacar,
    required this.icono,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icono, size: 14, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...valores.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            final esMejor = destacar == i;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: esMejor ? AppColors.accent.withOpacity(0.1) : null,
                  border: Border(
                    left: BorderSide(color: AppColors.borderSubtle),
                    right: i < valores.length - 1
                        ? BorderSide.none
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  v,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: esMejor ? FontWeight.w700 : FontWeight.w400,
                    color: esMejor ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
