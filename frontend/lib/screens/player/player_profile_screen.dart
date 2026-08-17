import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';
// ignore_for_file: use_build_context_synchronously

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  String? _posicion;
  List<String> _posicionesSecundarias = [];
  bool _guardando = false;
  String? _mensaje;
  bool _exito = false;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<AppState>().miPerfilJugador;
    _bioCtrl.text = perfil?.bio ?? '';
    _ciudadCtrl.text = perfil?.ciudad ?? '';
    _edadCtrl.text = perfil?.edad != null ? '${perfil!.edad}' : '';
    _posicion = perfil?.posicionPrincipal;
    _posicionesSecundarias = List<String>.from(perfil?.posicionesSecundarias ?? []);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _ciudadCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final edadVal = int.tryParse(_edadCtrl.text.trim());
    setState(() {
      _guardando = true;
      _mensaje = null;
    });
    try {
      await ApiClient.instance.dio.put('/jugadores/me', data: {
        'bio': _bioCtrl.text.trim(),
        'ciudad': _ciudadCtrl.text.trim(),
        'posicion_principal': _posicion,
        'posiciones_secundarias': _posicionesSecundarias,
        if (edadVal != null) 'edad': edadVal,
      });
      if (mounted) {
        setState(() {
          _mensaje = 'Perfil guardado correctamente';
          _exito = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mensaje = 'No se pudo guardar. Intenta de nuevo.';
          _exito = false;
        });
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _togglePosicionSecundaria(String pos) {
    if (pos == _posicion) return; // no puede ser principal y secundaria
    setState(() {
      if (_posicionesSecundarias.contains(pos)) {
        _posicionesSecundarias.remove(pos);
      } else if (_posicionesSecundarias.length < 2) {
        _posicionesSecundarias.add(pos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SectionLabel('Datos deportivos'),

        // Posición principal
        DropdownButtonFormField<String>(
          value: _posicion,
          decoration: const InputDecoration(
            labelText: 'Posición principal',
            prefixIcon: Icon(Icons.sports_soccer_rounded),
          ),
          items: AppConstants.posiciones
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _posicion = v;
              _posicionesSecundarias.remove(v);
            });
          },
        ),
        const SizedBox(height: 14),

        // Posiciones secundarias (chips)
        const Text('Posiciones secundarias (máx. 2)',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: AppConstants.posiciones
              .where((p) => p != _posicion)
              .map((p) {
            final sel = _posicionesSecundarias.contains(p);
            final disabled = !sel && _posicionesSecundarias.length >= 2;
            return FilterChip(
              label: Text(p, style: TextStyle(fontSize: 11.5, color: disabled ? AppColors.textMuted : null)),
              selected: sel,
              onSelected: disabled ? null : (_) => _togglePosicionSecundaria(p),
              selectedColor: AppColors.accent.withOpacity(0.2),
              checkmarkColor: AppColors.accent,
              side: BorderSide(
                color: sel ? AppColors.accent : AppColors.borderSubtle,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Edad
        TextField(
          controller: _edadCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Edad',
            prefixIcon: Icon(Icons.cake_rounded),
          ),
        ),
        const SizedBox(height: 12),

        // Ciudad
        DropdownButtonFormField<String>(
          value: AppConstants.ciudades.contains(_ciudadCtrl.text) ? _ciudadCtrl.text : null,
          decoration: const InputDecoration(
            labelText: 'Ciudad / distrito',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
          items: AppConstants.ciudades
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => _ciudadCtrl.text = v ?? '',
        ),
        const SizedBox(height: 12),

        // Bio
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Cuéntale a los captadores quién eres...',
            alignLabelWithHint: true,
          ),
        ),

        // Mensaje de feedback
        if (_mensaje != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _exito ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 16,
                color: _exito ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 6),
              Text(
                _mensaje!,
                style: TextStyle(
                  fontSize: 13,
                  color: _exito ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }
}
