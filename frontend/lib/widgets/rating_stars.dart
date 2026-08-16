import 'package:flutter/material.dart';

const _kGold = Color(0xFFF5B400);
const _kMuted = Color(0xFF5F7268);

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRate;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 20,
    this.interactive = false,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final filled = i < rating.round();
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? _kGold : _kMuted,
          size: size,
        );
        if (interactive) {
          return GestureDetector(
            onTap: () => onRate?.call(i + 1),
            child: star,
          );
        }
        return star;
      }),
    );
  }
}
