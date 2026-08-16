import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../models/notificacion.dart';
import '../../models/prueba.dart';
import '../../state/app_state.dart';
import '../../widgets/chip_estado_prueba.dart';

class ScoutAccountScreen extends StatefulWidget {
  const ScoutAccountScreen({super.key});

  @override
  State<ScoutAccountScreen> createState() => _ScoutAccountScreenState();
}

class _ScoutAccountScreenState extends State<ScoutAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezado con avatar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.bgElevated,
                child: Text(
                  (context.watch<AppState>().usuario?.nombre.isNotEmpty ?? false)
                      ? context.watch<AppState>().usuario!.nombre[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.watch<AppState>().usuario?.nombre ?? '',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      context.watch<AppState>().usuario?.celular ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Cuenta'),
            Tab(text: 'Pruebas'),
            Tab(text: 'Notificaciones'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _TabCuenta(),
              _TabPruebas(),
              _TabNotificaciones(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabCuenta extends StatefulWidget {
  const _TabCuenta();

  @override
  State<_TabCuenta> createState() => _TabCuentaState();
}

class _TabCuentaState extends State<_TabCuenta> {
  final _clubCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.instance.dio.get('/captadores/me');
      _clubCtrl.text = res.data['club_representa'] ?? '';
      _zonaCtrl.text = res.data['zona_interes'] ?? '';
      setState(() {});
    } catch (_) {}
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.dio.put('/captadores/me', data: {
        'club_representa': _clubCtrl.text.trim(),
        'zona_interes': _zonaCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error al guardar')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: _clubCtrl,
          decoration: const InputDecoration(
            labelText: 'Club que representa',
            prefixIcon: Icon(Icons.sports_soccer),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _zonaCtrl,
          decoration: const InputDecoration(
            labelText: 'Zona de interés',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Guardar cambios'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.read<AppState>().cerrarSesion(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _TabPruebas extends StatefulWidget {
  const _TabPruebas();

  @override
  State<_TabPruebas> createState() => _TabPruebasState();
}

class _TabPruebasState extends State<_TabPruebas> {
  List<Prueba> _pruebas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/captadores/me/pruebas');
      setState(() {
        _pruebas = (res.data as List).map((e) => Prueba.fromJson(e)).toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _ciclarEstado(Prueba prueba) async {
    try {
      final siguiente = prueba.siguienteEstado;
      await ApiClient.instance.dio.put(
        '/captadores/me/pruebas/${prueba.id}/estado',
        data: {'estado': siguiente},
      );
      _cargar();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: AppColors.accent));

    if (_pruebas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, size: 40, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text('Sin pruebas agendadas', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pruebas.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
        itemBuilder: (context, i) {
          final p = _pruebas[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fecha != null
                            ? '${p.fecha!.day}/${p.fecha!.month}/${p.fecha!.year}'
                            : 'Fecha pendiente',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      if (p.hora != null)
                        Text('${p.hora}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      if (p.lugar != null)
                        Text(p.lugar!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                ChipEstadoPrueba(estado: p.estado, onTap: () => _ciclarEstado(p)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabNotificaciones extends StatefulWidget {
  const _TabNotificaciones();

  @override
  State<_TabNotificaciones> createState() => _TabNotificacionesState();
}

class _TabNotificacionesState extends State<_TabNotificaciones> {
  List<Notificacion> _notificaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/notificaciones');
      setState(() {
        _notificaciones = (res.data as List).map((e) => Notificacion.fromJson(e)).toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _marcarTodas() async {
    try {
      await ApiClient.instance.dio.post('/notificaciones/leer-todas');
      _cargar();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: AppColors.accent));

    final noLeidas = _notificaciones.where((n) => !n.leido).length;

    return Column(
      children: [
        if (noLeidas > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _marcarTodas,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
                child: const Text('Marcar todas como leídas'),
              ),
            ),
          ),
        Expanded(
          child: _notificaciones.isEmpty
              ? const Center(
                  child: Text('Sin notificaciones', style: TextStyle(color: AppColors.textMuted)))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notificaciones.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.borderSubtle, height: 1),
                    itemBuilder: (context, i) {
                      final n = _notificaciones[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: n.leido ? AppColors.bgElevated : const Color(0x2222C55E),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: n.leido ? AppColors.textMuted : AppColors.accent,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          n.texto,
                          style: TextStyle(
                            fontSize: 13,
                            color: n.leido ? AppColors.textSecondary : AppColors.textPrimary,
                            fontWeight: n.leido ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _timeAgo(n.creadoEn),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }
}
