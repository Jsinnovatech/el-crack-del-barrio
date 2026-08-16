import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/usuario.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  final Rol rol;
  const LoginScreen({super.key, required this.rol});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nombreCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  bool _esRegistro = true;
  bool _cargando = false;
  String? _error;

  Future<void> _continuar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final app = context.read<AppState>();
      if (_esRegistro) {
        await app.registrar(_nombreCtrl.text.trim(), _celularCtrl.text.trim(), widget.rol);
      } else {
        await app.login(_celularCtrl.text.trim(), _codigoCtrl.text.trim());
      }
    } catch (e) {
      setState(() => _error = 'No se pudo continuar. Revisa tus datos e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esJugador = widget.rol == Rol.jugador;
    return Scaffold(
      appBar: AppBar(title: Text(esJugador ? 'Jugador' : 'Captador / DT')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: [_esRegistro, !_esRegistro],
                onPressed: (i) => setState(() => _esRegistro = i == 0),
                borderRadius: BorderRadius.circular(AppRadius.md),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Registrarme')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text('Ya tengo cuenta')),
                ],
              ),
              const SizedBox(height: 20),
              if (_esRegistro) ...[
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _celularCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Celular'),
              ),
              if (!_esRegistro) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _codigoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código OTP',
                    helperText: 'En desarrollo, usa el código de app/.env (OTP_DEV_CODE)',
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _continuar,
                child: _cargando
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
