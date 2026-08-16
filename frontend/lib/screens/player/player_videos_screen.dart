import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';

/// Pantalla de Videos del Jugador.
/// TODO: integrar image_picker para grabar/seleccionar video y subirlo a storage.
/// TODO: reordenar por drag & drop o botones ↑↓ (ver endpoint PUT /jugadores/me/videos/orden).
/// TODO: marcar video como destacado (POST /jugadores/me/videos/{id}/destacar).
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
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/videos');
      setState(() {
        _videos = res.data;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
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
              const Text('Mis videos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.accent),
                onPressed: () {
                  // TODO: abrir image_picker / grabador y subir el video
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _videos.isEmpty
                  ? const Center(child: Text('Aún no hay videos subidos', style: TextStyle(color: AppColors.textMuted)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(18),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _videos.length,
                      itemBuilder: (context, i) {
                        final v = _videos[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: AppColors.bgElevated),
                              if (v['thumb_url'] != null)
                                Image.network(v['thumb_url'], fit: BoxFit.cover),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  v['titulo'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                              if (v['destacado'] == true)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
