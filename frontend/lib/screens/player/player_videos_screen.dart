import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';

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
    final thumbCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Agregar video'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título del video'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL del video (YouTube, Drive...)',
                  hintText: 'https://youtube.com/watch?v=...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thumbCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de miniatura (opcional)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final titulo = tituloCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (titulo.isEmpty || url.isEmpty) return;

    try {
      await ApiClient.instance.dio.post('/jugadores/me/videos', data: {
        'titulo': titulo,
        'url': url,
        if (thumbCtrl.text.trim().isNotEmpty) 'thumb_url': thumbCtrl.text.trim(),
      });
      _cargar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo agregar el video')));
      }
    }
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
