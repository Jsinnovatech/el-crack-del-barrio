import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';

/// Pantalla de Perfil del Jugador.
/// TODO: subir foto/DNI real (image_picker + endpoint de upload o storage externo).
/// TODO: selector de posiciones secundarias (chips múltiples, máx. 2).
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  String? _posicion;
  bool _guardando = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<AppState>().miPerfilJugador;
    _bioCtrl.text = perfil?.bio ?? '';
    _ciudadCtrl.text = perfil?.ciudad ?? '';
    _posicion = perfil?.posicionPrincipal;
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _mensaje = null;
    });
    try {
      await ApiClient.instance.dio.put('/jugadores/me', data: {
        'bio': _bioCtrl.text.trim(),
        'ciudad': _ciudadCtrl.text.trim(),
        'posicion_principal': _posicion,
      });
      setState(() => _mensaje = 'Perfil guardado correctamente');
    } catch (_) {
      setState(() => _mensaje = 'No se pudo guardar. Intenta de nuevo.');
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SectionLabel('Datos deportivos'),
        DropdownButtonFormField<String>(
          value: _posicion,
          decoration: const InputDecoration(labelText: 'Posición principal'),
          items: AppConstants.posiciones
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _posicion = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ciudadCtrl,
          decoration: const InputDecoration(labelText: 'Ciudad / distrito'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Bio (mín. 10 caracteres)'),
        ),
        if (_mensaje != null) ...[
          const SizedBox(height: 12),
          Text(_mensaje!),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }
}
