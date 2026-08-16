import 'package:flutter/material.dart';

class ChipEstadoPrueba extends StatelessWidget {
  final String estado;
  final VoidCallback? onTap;
  final bool small;

  const ChipEstadoPrueba({
    super.key,
    required this.estado,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (estado) {
      'pendiente' => (const Color(0xFF1A231C), const Color(0xFF9FB3A6), 'Pendiente'),
      'confirmada' => (const Color(0x2622C55E), const Color(0xFF22C55E), 'Confirmada'),
      'realizada' => (const Color(0x2638BDF8), const Color(0xFF38BDF8), 'Realizada'),
      _ => (const Color(0xFF1A231C), const Color(0xFF9FB3A6), estado),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: small ? 10 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
