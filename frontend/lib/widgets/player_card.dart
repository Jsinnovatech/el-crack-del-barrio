import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/jugador_explorar.dart';

const _kBgSurface = Color(0xFF121814);
const _kBgElevated = Color(0xFF1A231C);
const _kAccentGreen = Color(0xFF22C55E);
const _kAccentGold = Color(0xFFF5B400);
const _kTextPrimary = Color(0xFFF2F7F3);
const _kTextSecondary = Color(0xFF9FB3A6);
const _kTextMuted = Color(0xFF5F7268);
const _kBorderSubtle = Color(0x0FFFFFFF);

class PlayerCard extends StatelessWidget {
  final JugadorExplorar jugador;
  final bool isFavorito;
  final VoidCallback? onTap;
  final VoidCallback? onFavorito;
  final bool showCompareCheck;
  final bool isCompareChecked;
  final VoidCallback? onCompareToggle;

  const PlayerCard({
    super.key,
    required this.jugador,
    this.isFavorito = false,
    this.onTap,
    this.onFavorito,
    this.showCompareCheck = false,
    this.isCompareChecked = false,
    this.onCompareToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kBgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorderSubtle),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Foto con overlays ──
            SizedBox(
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto
                  jugador.fotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: jugador.fotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: _kBgElevated),
                          errorWidget: (_, __, ___) => Container(
                            color: _kBgElevated,
                            child: const Icon(Icons.person, color: _kTextMuted, size: 48),
                          ),
                        )
                      : Container(
                          color: _kBgElevated,
                          child: const Icon(Icons.person, color: _kTextMuted, size: 48),
                        ),
                  // Gradiente inferior
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.4, 1.0],
                        colors: [Colors.transparent, Color(0xEA05100A)],
                      ),
                    ),
                  ),
                  // Badge posición (top-left)
                  if (jugador.posicionPrincipal != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          jugador.posicionPrincipal!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  // Badge verificado (top-right)
                  if (jugador.verificado)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: _kAccentGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Color(0xFF1C1300), size: 14),
                      ),
                    ),
                  // Compare checkbox (top-left sobre el badge de posición, si está activo)
                  if (showCompareCheck)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: onCompareToggle,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isCompareChecked ? _kAccentGreen : Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompareChecked ? _kAccentGreen : Colors.white60,
                              width: 2,
                            ),
                          ),
                          child: isCompareChecked
                              ? const Icon(Icons.check, color: Color(0xFF03150A), size: 14)
                              : null,
                        ),
                      ),
                    ),
                  // Nombre y meta (bottom)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jugador.nombreUsuario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFD5E6DA), size: 11),
                            const SizedBox(width: 2),
                            Text(
                              '${jugador.ciudad ?? '—'} · ${jugador.edad ?? '?'} años',
                              style: const TextStyle(color: Color(0xFFD5E6DA), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Fila inferior: tags + favorito ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        // Rating
                        _Tag('★ ${jugador.rating.toStringAsFixed(1)}', color: _kAccentGold),
                        // Posiciones secundarias
                        ...jugador.posicionesSecundarias
                            .take(2)
                            .map((p) => _Tag(p)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón favorito
                  GestureDetector(
                    onTap: onFavorito,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFavorito ? const Color(0x1FFF4D6D) : _kBgElevated,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFavorito ? const Color(0x66FF4D6D) : const Color(0x1FFFFFFF),
                        ),
                      ),
                      child: Icon(
                        isFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorito ? const Color(0xFFFF4D6D) : _kTextMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, {this.color = _kTextSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kBgElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kBorderSubtle),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
