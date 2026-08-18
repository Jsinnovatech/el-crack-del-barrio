import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/imgbb_service.dart';
import '../../state/app_state.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _edadCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _posicionPrincipal;
  List<String> _posicionesSecundarias = [];
  String? _ciudad;
  bool _guardando = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  void _inicializar() {
    final perfil = context.read<AppState>().miPerfilJugador;
    if (perfil == null) return;
    _edadCtrl.text = perfil.edad?.toString() ?? '';
    _telefonoCtrl.text = perfil.telefono ?? '';
    _whatsappCtrl.text = perfil.whatsapp ?? '';
    _bioCtrl.text = perfil.bio ?? '';
    _posicionPrincipal = perfil.posicionPrincipal;
    _posicionesSecundarias = List.from(perfil.posicionesSecundarias);
    _ciudad = perfil.ciudad;
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    _telefonoCtrl.dispose();
    _whatsappCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Foto ────────────────────────────────────────────────────────────────────

  Future<void> _mostrarOpcionesFoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de galería'),
              onTap: () { Navigator.pop(context); _cambiarFoto(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tomar foto'),
              onTap: () { Navigator.pop(context); _cambiarFoto(ImageSource.camera); },
            ),
            if (context.read<AppState>().miPerfilJugador?.fotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppColors.danger),
                title: const Text('Eliminar foto', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(context);
                  await ApiClient.instance.dio.put('/jugadores/me', data: {'foto_url': null});
                  await context.read<AppState>().recargarPerfil();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarFoto(ImageSource source) async {
    setState(() => _subiendoFoto = true);
    try {
      final url = await ImgBBService.instance.pickAndUpload(source: source);
      if (url != null && mounted) {
        await ApiClient.instance.dio.put('/jugadores/me', data: {'foto_url': url});
        await context.read<AppState>().recargarPerfil();
      }
    } catch (_) {
      if (mounted) _snack('Error al subir la foto');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  // ── Guardar ─────────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.dio.put('/jugadores/me', data: {
        if (_posicionPrincipal != null) 'posicion_principal': _posicionPrincipal,
        'posiciones_secundarias': _posicionesSecundarias,
        if (_ciudad != null) 'ciudad': _ciudad,
        if (_edadCtrl.text.isNotEmpty) 'edad': int.tryParse(_edadCtrl.text),
        'telefono': _telefonoCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        if (_bioCtrl.text.isNotEmpty) 'bio': _bioCtrl.text.trim(),
      });
      await context.read<AppState>().recargarPerfil();
      if (mounted) _snack('Perfil actualizado', ok: true);
    } catch (_) {
      if (mounted) _snack('Error al guardar');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final perfil = app.miPerfilJugador;
    final nombre = app.usuario?.nombre ?? '';
    final fotoUrl = perfil?.fotoUrl;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Información Personal'),
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          _guardando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _guardar,
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [

            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _mostrarOpcionesFoto,
                    child: _subiendoFoto
                        ? Container(
                            width: 100, height: 100,
                            decoration: const BoxDecoration(color: AppColors.bgSurface, shape: BoxShape.circle),
                            child: const Center(child: CircularProgressIndicator()),
                          )
                        : CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.accent,
                            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                            child: fotoUrl == null
                                ? Text(
                                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _mostrarOpcionesFoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            if (perfil?.verificado == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
                      SizedBox(width: 4),
                      Text('Verificado', style: TextStyle(color: AppColors.success, fontSize: 12)),
                    ],
                  ),
                ),
              ),

            // ── Contacto ────────────────────────────────────────────────────
            _Seccion('Contacto'),
            _Campo(
              ctrl: _telefonoCtrl,
              label: 'Teléfono',
              icon: Icons.phone_rounded,
              hint: '+51 999 999 999',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _Campo(
              ctrl: _whatsappCtrl,
              label: 'WhatsApp',
              icon: Icons.chat_rounded,
              hint: '+51 999 999 999',
              keyboard: TextInputType.phone,
            ),

            // ── Datos personales ─────────────────────────────────────────────
            _Seccion('Datos personales'),
            _Campo(
              ctrl: _edadCtrl,
              label: 'Edad',
              icon: Icons.cake_rounded,
              hint: 'Ej: 22',
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 13 || n > 60) return 'Edad entre 13 y 60';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _ciudad,
              decoration: _deco('Ciudad', Icons.location_on_rounded),
              hint: const Text('Selecciona tu ciudad'),
              items: AppConstants.ciudades
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _ciudad = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioCtrl,
              decoration: _deco('Bio', Icons.notes_rounded, hint: 'Cuéntale a los captadores sobre ti...'),
              maxLines: 3,
              maxLength: 200,
            ),

            // ── Posiciones ────────────────────────────────────────────────────
            _Seccion('Posiciones'),
            DropdownButtonFormField<String>(
              value: _posicionPrincipal,
              decoration: _deco('Posición principal', Icons.sports_soccer_rounded),
              hint: const Text('Selecciona tu posición'),
              items: AppConstants.posiciones
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() {
                _posicionPrincipal = v;
                _posicionesSecundarias.remove(v);
              }),
            ),
            const SizedBox(height: 12),
            const Text('Otras posiciones (máx. 2)',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: AppConstants.posiciones
                  .where((p) => p != _posicionPrincipal)
                  .map((p) {
                final sel = _posicionesSecundarias.contains(p);
                return FilterChip(
                  label: Text(p, style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) {
                      if (_posicionesSecundarias.length < 2) _posicionesSecundarias.add(p);
                    } else {
                      _posicionesSecundarias.remove(p);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _Seccion extends StatelessWidget {
  final String label;
  const _Seccion(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.accent, letterSpacing: 0.5)),
      );
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _Campo({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}
