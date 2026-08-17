import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/imgbb_service.dart';
import '../../state/app_state.dart';
import '../../widgets/section_label.dart';

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
  bool _subiendoFoto = false;
  String? _mensaje;
  bool _exito = false;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<AppState>().miPerfilJugador;
    _bioCtrl.text = perfil?.bio ?? '';
    _ciudadCtrl.text = perfil?.ciudad ?? '';
    _edadCtrl.text = perfil?.edad != null ? '${perfil!.edad}' : '';
    _posicion = perfil?.posicionPrincipal;
    _posicionesSecundarias = List<String>.from(perfil?.posicionesSecundarias ?? []);
    _fotoUrl = perfil?.fotoUrl;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _ciudadCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  // ── Foto de perfil ───────────────────────────────────────────────────────
  Future<void> _cambiarFoto(ImageSource source) async {
    setState(() => _subiendoFoto = true);
    try {
      final url = await ImgBBService.instance.pickAndUpload(source: source);
      if (url == null) {
        setState(() => _subiendoFoto = false);
        return;
      }
      // Guardar URL en backend
      await ApiClient.instance.dio.put('/jugadores/me', data: {'foto_url': url});
      setState(() {
        _fotoUrl = url;
        _subiendoFoto = false;
        _mensaje = 'Foto actualizada';
        _exito = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _subiendoFoto = false;
          _mensaje = 'No se pudo subir la foto';
          _exito = false;
        });
      }
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Text('Foto de perfil',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _cambiarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _cambiarFoto(ImageSource.camera);
              },
            ),
            if (_fotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppColors.danger),
                title: const Text('Eliminar foto', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(context);
                  await ApiClient.instance.dio.put('/jugadores/me', data: {'foto_url': null});
                  if (mounted) setState(() => _fotoUrl = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Datos del perfil ─────────────────────────────────────────────────────
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
    if (pos == _posicion) return;
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
    final nombre = context.watch<AppState>().usuario?.nombre ?? '';

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        // ── Avatar ──────────────────────────────────────────────────────
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _mostrarOpcionesFoto,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgElevated,
                    border: Border.all(color: AppColors.borderDefault, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _subiendoFoto
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2))
                      : _fotoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _fotoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.accent, strokeWidth: 2)),
                              errorWidget: (_, __, ___) => _InitialAvatar(nombre),
                            )
                          : _InitialAvatar(nombre),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _mostrarOpcionesFoto,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgBase, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(nombre,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 20),

        // ── Datos deportivos ────────────────────────────────────────────
        const SectionLabel('Datos deportivos'),

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
              label: Text(p,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: disabled ? AppColors.textMuted : null)),
              selected: sel,
              onSelected: disabled ? null : (_) => _togglePosicionSecundaria(p),
              selectedColor: AppColors.accent.withOpacity(0.2),
              checkmarkColor: AppColors.accent,
              side: BorderSide(
                  color: sel ? AppColors.accent : AppColors.borderSubtle),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _edadCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Edad',
            prefixIcon: Icon(Icons.cake_rounded),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: AppConstants.ciudades.contains(_ciudadCtrl.text)
              ? _ciudadCtrl.text
              : null,
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
              Expanded(
                child: Text(
                  _mensaje!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _exito ? AppColors.success : AppColors.danger,
                  ),
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

class _InitialAvatar extends StatelessWidget {
  final String nombre;
  const _InitialAvatar(this.nombre);

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return Center(
      child: Text(
        inicial,
        style: const TextStyle(
            fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.accent),
      ),
    );
  }
}
