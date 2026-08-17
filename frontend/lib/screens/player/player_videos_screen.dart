import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/imgbb_service.dart';

class PlayerVideosScreen extends StatefulWidget {
  const PlayerVideosScreen({super.key});

  @override
  State<PlayerVideosScreen> createState() => _PlayerVideosScreenState();
}

class _PlayerVideosScreenState extends State<PlayerVideosScreen> {
  List<dynamic> _videos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/videos');
      setState(() {
        _videos = List.from(res.data);
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregarVideo() async {
    final tituloCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String? thumbUrl;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) => _AgregarVideoSheet(
        tituloCtrl: tituloCtrl,
        urlCtrl: urlCtrl,
        onThumbChanged: (url) => thumbUrl = url,
        onGuardar: () async {
          final titulo = tituloCtrl.text.trim();
          final url = urlCtrl.text.trim();
          if (titulo.isEmpty || url.isEmpty) return;
          Navigator.pop(sheetCtx);
          try {
            await ApiClient.instance.dio.post('/jugadores/me/videos', data: {
              'titulo': titulo,
              'url': url,
              if (thumbUrl != null) 'thumb_url': thumbUrl,
            });
            _cargar();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo agregar el video')));
            }
          }
        },
      ),
    );
  }

  Future<void> _destacar(String videoId, bool esDestacado) async {
    if (esDestacado) return; // ya está destacado
    try {
      await ApiClient.instance.dio.post('/jugadores/me/videos/$videoId/destacar');
      _cargar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo destacar el video')));
      }
    }
  }

  Future<void> _eliminar(String videoId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Eliminar video'),
        content: const Text('¿Seguro que quieres eliminar este video?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.dio.delete('/jugadores/me/videos/$videoId');
      _cargar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo eliminar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis videos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                onPressed: _agregarVideo,
              ),
            ],
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _videos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_off_rounded,
                              size: 52, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('Aún no tienes videos',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('Agrega tus mejores jugadas para destacar',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Agregar video'),
                            onPressed: _agregarVideo,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _videos.length,
                        itemBuilder: (context, i) {
                          final v = _videos[i];
                          final esDestacado = v['destacado'] == true;
                          return _VideoCard(
                            video: v,
                            esDestacado: esDestacado,
                            onDestacar: () => _destacar(v['id'], esDestacado),
                            onEliminar: () => _eliminar(v['id']),
                            onAbrir: () async {
                              final url = Uri.tryParse(v['url'] ?? '');
                              if (url != null && await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final dynamic video;
  final bool esDestacado;
  final VoidCallback onDestacar;
  final VoidCallback onEliminar;
  final VoidCallback onAbrir;

  const _VideoCard({
    required this.video,
    required this.esDestacado,
    required this.onDestacar,
    required this.onEliminar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAbrir,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            video['thumb_url'] != null
                ? CachedNetworkImage(
                    imageUrl: video['thumb_url'],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bgElevated),
                    errorWidget: (_, __, ___) => Container(color: AppColors.bgElevated),
                  )
                : Container(
                    color: AppColors.bgElevated,
                    child: const Icon(Icons.play_circle_outline_rounded,
                        size: 40, color: AppColors.textMuted),
                  ),
            // Gradiente inferior
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Icono play centrado
            const Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white54, size: 36),
            ),
            // Título abajo
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                video['titulo'] ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badge destacado
            if (esDestacado)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 10, color: Colors.black),
                      SizedBox(width: 2),
                      Text('Destacado',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    ],
                  ),
                ),
              ),
            // Botones (destacar / eliminar)
            Positioned(
              top: 4,
              right: 4,
              child: Column(
                children: [
                  if (!esDestacado)
                    _IconBtn(
                      icon: Icons.star_border_rounded,
                      color: AppColors.gold,
                      tooltip: 'Destacar',
                      onTap: onDestacar,
                    ),
                  _IconBtn(
                    icon: Icons.delete_rounded,
                    color: AppColors.danger,
                    tooltip: 'Eliminar',
                    onTap: onEliminar,
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Sheet para agregar video con miniatura desde ImgBB ───────────────────────

class _AgregarVideoSheet extends StatefulWidget {
  final TextEditingController tituloCtrl;
  final TextEditingController urlCtrl;
  final ValueChanged<String?> onThumbChanged;
  final VoidCallback onGuardar;

  const _AgregarVideoSheet({
    required this.tituloCtrl,
    required this.urlCtrl,
    required this.onThumbChanged,
    required this.onGuardar,
  });

  @override
  State<_AgregarVideoSheet> createState() => _AgregarVideoSheetState();
}

class _AgregarVideoSheetState extends State<_AgregarVideoSheet> {
  String? _thumbUrl;
  bool _subiendoThumb = false;

  Future<void> _pickThumb(ImageSource source) async {
    setState(() => _subiendoThumb = true);
    final url = await ImgBBService.instance.pickAndUpload(source: source);
    setState(() {
      _thumbUrl = url;
      _subiendoThumb = false;
    });
    widget.onThumbChanged(url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agregar video',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // Título
          TextField(
            controller: widget.tituloCtrl,
            decoration: const InputDecoration(
              labelText: 'Título del video',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),

          // URL del video
          TextField(
            controller: widget.urlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL del video (YouTube, Drive...)',
              hintText: 'https://youtube.com/watch?v=...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Miniatura desde ImgBB
          const Text('Miniatura',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Preview de la miniatura
              GestureDetector(
                onTap: () => _pickThumb(ImageSource.gallery),
                child: Container(
                  width: 80,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: _thumbUrl != null
                            ? AppColors.accent
                            : AppColors.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _subiendoThumb
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2))
                      : _thumbUrl != null
                          ? Image.network(_thumbUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.image_rounded,
                              color: AppColors.textMuted, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded, size: 16),
                    label: const Text('Galería',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed:
                        _subiendoThumb ? null : () => _pickThumb(ImageSource.gallery),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text('Cámara',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed:
                        _subiendoThumb ? null : () => _pickThumb(ImageSource.camera),
                  ),
                ],
              ),
              if (_thumbUrl != null) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.danger, size: 18),
                  onPressed: () {
                    setState(() => _thumbUrl = null);
                    widget.onThumbChanged(null);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.borderDefault),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onGuardar,
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
