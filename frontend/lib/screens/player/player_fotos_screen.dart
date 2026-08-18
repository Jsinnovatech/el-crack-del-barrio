import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/imgbb_service.dart';
import '../../models/foto_equipo.dart';

class PlayerFotosScreen extends StatefulWidget {
  const PlayerFotosScreen({super.key});

  @override
  State<PlayerFotosScreen> createState() => _PlayerFotosScreenState();
}

class _PlayerFotosScreenState extends State<PlayerFotosScreen> {
  static const _maxFotos = 8;

  bool _cargando = true;
  List<FotoEquipo> _fotos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/fotos');
      setState(() {
        _fotos = (res.data as List).map((j) => FotoEquipo.fromJson(j)).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar foto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ApiClient.instance.dio.delete('/jugadores/me/fotos/$id');
    _cargar();
  }

  void _verFoto(FotoEquipo foto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: foto.urlFoto,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            if (foto.resena != null && foto.resena!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Text(foto.resena!,
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  void _agregar() {
    if (_fotos.length >= _maxFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 8 fotos permitidas')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgregarFotoSheet(onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text('Fotos en Equipos  (${_fotos.length}/$_maxFotos)'),
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: _fotos.length < _maxFotos
          ? FloatingActionButton.extended(
              onPressed: _agregar,
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              label: const Text('Agregar foto', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _fotos.isEmpty
              ? _EstadoVacio(onAgregar: _agregar)
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _fotos.length,
                    itemBuilder: (_, i) => _FotoCard(
                      foto: _fotos[i],
                      onTap: () => _verFoto(_fotos[i]),
                      onEliminar: () => _eliminar(_fotos[i].id),
                    ),
                  ),
                ),
    );
  }
}

// ─── Tarjeta de foto ─────────────────────────────────────────────────────────

class _FotoCard extends StatelessWidget {
  final FotoEquipo foto;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const _FotoCard({
    required this.foto,
    required this.onTap,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            CachedNetworkImage(
              imageUrl: foto.urlFoto,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.bgSurface,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.bgSurface,
                child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
              ),
            ),

            // Gradiente inferior
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Reseña abajo
            if (foto.resena != null && foto.resena!.isNotEmpty)
              Positioned(
                bottom: 34,
                left: 8,
                right: 8,
                child: Text(
                  foto.resena!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Botón eliminar
            Positioned(
              bottom: 6,
              right: 6,
              child: GestureDetector(
                onTap: onEliminar,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),

            // Icono de expandir
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.open_in_full_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vacío ───────────────────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  final VoidCallback onAgregar;
  const _EstadoVacio({required this.onAgregar});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined, size: 72, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('Sin fotos aún',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Sube fotos de los equipos y torneos en los que has jugado (máx. 8).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Agregar foto'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              ),
            ],
          ),
        ),
      );
}

// ─── Sheet para agregar foto ─────────────────────────────────────────────────

class _AgregarFotoSheet extends StatefulWidget {
  final VoidCallback onGuardado;
  const _AgregarFotoSheet({required this.onGuardado});

  @override
  State<_AgregarFotoSheet> createState() => _AgregarFotoSheetState();
}

class _AgregarFotoSheetState extends State<_AgregarFotoSheet> {
  final _resenaCtrl = TextEditingController();
  String? _urlFoto;
  bool _subiendoFoto = false;
  bool _guardando = false;

  @override
  void dispose() {
    _resenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto(ImageSource source) async {
    setState(() => _subiendoFoto = true);
    try {
      final url = await ImgBBService.instance.pickAndUpload(source: source);
      if (url != null && mounted) setState(() => _urlFoto = url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la foto')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _guardar() async {
    if (_urlFoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero sube una foto')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.dio.post('/jugadores/me/fotos', data: {
        'url_foto': _urlFoto,
        if (_resenaCtrl.text.trim().isNotEmpty) 'resena': _resenaCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Agregar foto de equipo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Preview / selector de foto
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library_rounded),
                        title: const Text('Elegir de galería'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickFoto(ImageSource.gallery);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt_rounded),
                        title: const Text('Tomar foto'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickFoto(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                      style: BorderStyle.solid),
                ),
                clipBehavior: Clip.antiAlias,
                child: _subiendoFoto
                    ? const Center(child: CircularProgressIndicator())
                    : _urlFoto != null
                        ? CachedNetworkImage(
                            imageUrl: _urlFoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 40, color: AppColors.accent),
                              SizedBox(height: 8),
                              Text('Toca para seleccionar foto',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Reseña
            TextField(
              controller: _resenaCtrl,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: 'Reseña (opcional)',
                hintText: 'Ej: Liga Distrital 2024 con el Club Deportivo Perú...',
                prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar foto',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
