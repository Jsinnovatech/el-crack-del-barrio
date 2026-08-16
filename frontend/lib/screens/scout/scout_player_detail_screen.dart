import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../models/jugador_explorar.dart';
import '../../state/app_state.dart';
import '../../widgets/rating_stars.dart';

class ScoutPlayerDetailScreen extends StatefulWidget {
  final JugadorExplorar jugador;

  const ScoutPlayerDetailScreen({super.key, required this.jugador});

  @override
  State<ScoutPlayerDetailScreen> createState() => _ScoutPlayerDetailScreenState();
}

class _ScoutPlayerDetailScreenState extends State<ScoutPlayerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _perfilCompleto;
  List<dynamic> _videos = [];
  List<dynamic> _disponibilidad = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final id = widget.jugador.id;
      final res = await Future.wait([
        ApiClient.instance.dio.get('/jugadores/$id'),
        ApiClient.instance.dio.get('/jugadores/$id/videos'),
        ApiClient.instance.dio.get('/jugadores/$id/disponibilidad'),
      ]);
      setState(() {
        _perfilCompleto = res[0].data;
        _videos = res[1].data;
        _disponibilidad = res[2].data;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  void _contactarWhatsApp() async {
    final celular = _perfilCompleto?['celular'] ?? '';
    final nombre = widget.jugador.nombreUsuario;
    final posicion = widget.jugador.posicionPrincipal ?? '';
    final mensaje = Uri.encodeComponent(
        '¡Hola $nombre! Vi tu perfil en Vitrina Deportiva. Soy captador y me interesa tu perfil como $posicion. ¿Podemos hablar?');
    final url = Uri.parse('https://wa.me/$celular?text=$mensaje');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      // Registrar contacto
      try {
        await ApiClient.instance.dio
            .post('/captadores/me/contactos', data: {'jugador_id': widget.jugador.id});
      } catch (_) {}
    }
  }

  void _agendarPrueba() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _AgendarPruebaSheet(jugadorId: widget.jugador.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<AppState>().favoritosIds.contains(widget.jugador.id);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // Hero photo
          SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.jugador.fotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.jugador.fotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.bgElevated),
                        errorWidget: (_, __, ___) => Container(color: AppColors.bgElevated),
                      )
                    : Container(color: AppColors.bgElevated),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A000000), Color(0x18060A08), Color(0xFA060A08)],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // Top: botón volver + favorito
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.black38),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<AppState>().toggleFavorito(widget.jugador.id),
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFFF4D6D) : Colors.white,
                          ),
                          style: IconButton.styleFrom(backgroundColor: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom: nombre, posición, datos
                Positioned(
                  bottom: 16,
                  left: 18,
                  right: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.jugador.nombreUsuario,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (widget.jugador.verificado)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '✓ Verificado',
                                style: TextStyle(color: Color(0xFF1C1300), fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (widget.jugador.posicionPrincipal != null)
                            Text(widget.jugador.posicionPrincipal!,
                                style: const TextStyle(color: Color(0xFFCFE4D6), fontSize: 12)),
                          if (widget.jugador.ciudad != null)
                            Text('· ${widget.jugador.ciudad}',
                                style: const TextStyle(color: Color(0xFFCFE4D6), fontSize: 12)),
                          if (widget.jugador.edad != null)
                            Text('· ${widget.jugador.edad} años',
                                style: const TextStyle(color: Color(0xFFCFE4D6), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RatingStars(rating: widget.jugador.rating, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // TabBar
          Container(
            color: AppColors.bgBase,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Videos'),
                Tab(text: 'Calendario'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _TabInfo(perfil: _perfilCompleto, jugador: widget.jugador),
                      _TabVideos(videos: _videos),
                      _TabCalendario(disponibilidad: _disponibilidad),
                    ],
                  ),
          ),
          // Botones de acción
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _agendarPrueba,
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text('Agendar prueba'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderDefault),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _contactarWhatsApp,
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabInfo extends StatelessWidget {
  final Map<String, dynamic>? perfil;
  final JugadorExplorar jugador;

  const _TabInfo({this.perfil, required this.jugador});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (perfil?['bio'] != null) ...[
          const Text('Bio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(perfil!['bio'], style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
        ],
        const Text('Posiciones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (jugador.posicionPrincipal != null)
              _Chip(jugador.posicionPrincipal!, green: true),
            ...jugador.posicionesSecundarias.map((p) => _Chip(p)),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool green;
  const _Chip(this.label, {this.green = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: green ? const Color(0x2222C55E) : AppColors.bgElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: green ? AppColors.accent : AppColors.borderSubtle),
      ),
      child: Text(label,
          style: TextStyle(
              color: green ? AppColors.accent : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _TabVideos extends StatelessWidget {
  final List<dynamic> videos;
  const _TabVideos({required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 40, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text('Sin videos', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        final v = videos[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.bgElevated),
              if (v['thumb_url'] != null)
                CachedNetworkImage(imageUrl: v['thumb_url'], fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xBF000000)],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                      color: Color(0xEBFFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.bgBase, size: 22),
                ),
              ),
              if (v['destacado'] == true)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  v['titulo'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabCalendario extends StatelessWidget {
  final List<dynamic> disponibilidad;
  const _TabCalendario({required this.disponibilidad});

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'disponible':
        return AppColors.accent;
      case 'contratado':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (disponibilidad.isEmpty) {
      return const Center(
        child: Text('Sin disponibilidad registrada', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: disponibilidad.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
      itemBuilder: (context, i) {
        final d = disponibilidad[i];
        final estado = d['estado'] as String;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _colorEstado(estado),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(d['fecha'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: Text(
            estado,
            style: TextStyle(color: _colorEstado(estado), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}

class _AgendarPruebaSheet extends StatefulWidget {
  final String jugadorId;
  const _AgendarPruebaSheet({required this.jugadorId});

  @override
  State<_AgendarPruebaSheet> createState() => _AgendarPruebaSheetState();
}

class _AgendarPruebaSheetState extends State<_AgendarPruebaSheet> {
  DateTime? _fecha;
  TimeOfDay? _hora;
  final _lugarCtrl = TextEditingController();
  bool _guardando = false;

  Future<void> _confirmar() async {
    setState(() => _guardando = true);
    try {
      final body = {
        'jugador_id': widget.jugadorId,
        if (_fecha != null)
          'fecha':
              '${_fecha!.year.toString().padLeft(4, '0')}-${_fecha!.month.toString().padLeft(2, '0')}-${_fecha!.day.toString().padLeft(2, '0')}',
        if (_hora != null) 'hora': '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
        if (_lugarCtrl.text.trim().isNotEmpty) 'lugar': _lugarCtrl.text.trim(),
      };
      await ApiClient.instance.dio.post('/captadores/me/pruebas', data: body);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Prueba agendada!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agendar la prueba')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: AppColors.borderDefault, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Agendar prueba', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _fecha = d);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_fecha == null
                      ? 'Fecha'
                      : '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setState(() => _hora = t);
                  },
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_hora == null ? 'Hora' : _hora!.format(context)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lugarCtrl,
            decoration: const InputDecoration(
              labelText: 'Lugar (campo, dirección...)',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando ? null : _confirmar,
              child: _guardando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirmar prueba'),
            ),
          ),
        ],
      ),
    );
  }
}
