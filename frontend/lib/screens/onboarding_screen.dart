import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/usuario.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFF0A3D1F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: const [BoxShadow(color: Color(0x47022C12), blurRadius: 16)],
                    ),
                    child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'El Crack ',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        TextSpan(
                          text: 'del Barrio',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Hero title
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tu próximo ',
                      style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.05),
                    ),
                    TextSpan(
                      text: 'crack ',
                      style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          height: 1.05),
                    ),
                    TextSpan(
                      text: 'ya está jugando en el barrio',
                      style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.05),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Conecta jugadores de barrio con captadores y clubes que buscan nuevo talento.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const Spacer(),
              // Cards de rol
              _RolCard(
                titulo: 'Soy Jugador',
                subtitulo: 'Crea tu perfil y consigue tu oportunidad',
                icono: Icons.person_rounded,
                esJugador: true,
                onTap: () => _irALogin(context, Rol.jugador),
              ),
              const SizedBox(height: 14),
              _RolCard(
                titulo: 'Soy Captador / DT',
                subtitulo: 'Descubre talentos y agenda pruebas',
                icono: Icons.search_rounded,
                esJugador: false,
                onTap: () => _irALogin(context, Rol.captador),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _irALogin(BuildContext context, Rol rol) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(rol: rol)),
    );
  }
}

class _RolCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool esJugador;
  final VoidCallback onTap;

  const _RolCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.esJugador,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = esJugador ? AppColors.accent : AppColors.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: esJugador ? const Color(0x40F2F7F3) : const Color(0x40F5B400),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icono, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitulo,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
