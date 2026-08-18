import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/historial.dart';

class PlayerHistorialScreen extends StatefulWidget {
  const PlayerHistorialScreen({super.key});

  @override
  State<PlayerHistorialScreen> createState() => _PlayerHistorialScreenState();
}

class _PlayerHistorialScreenState extends State<PlayerHistorialScreen> {
  bool _cargando = true;
  List<Historial> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/historial');
      setState(() {
        _historial = (res.data as List).map((j) => Historial.fromJson(j)).toList();
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
        title: const Text('¿Eliminar entrada?'),
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
    await ApiClient.instance.dio.delete('/jugadores/me/historial/$id');
    _cargar();
  }

  void _agregar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgregarHistorialSheet(onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Historial Deportivo'),
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
              ? _EstadoVacio(onAgregar: _agregar)
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _historial.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TarjetaHistorial(
                      item: _historial[i],
                      onEliminar: () => _eliminar(_historial[i].id),
                    ),
                  ),
                ),
    );
  }
}

// ─── Tarjeta ────────────────────────────────────────────────────────────────

class _TarjetaHistorial extends StatelessWidget {
  final Historial item;
  final VoidCallback onEliminar;

  const _TarjetaHistorial({required this.item, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.torneo,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.equipo,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.anio != null) _Chip('${item.anio}', Icons.calendar_today_rounded),
                      if (item.posicion != null) _Chip(item.posicion!, Icons.sports_soccer_rounded),
                      if (item.logro != null) _Chip(item.logro!, Icons.military_tech_rounded, color: AppColors.gold),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
              onPressed: onEliminar,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _Chip(this.label, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
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
              const Icon(Icons.emoji_events_outlined, size: 72, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('Sin historial aún',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Agrega las ligas, torneos y campeonatos donde has participado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add),
                label: const Text('Agregar torneo'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              ),
            ],
          ),
        ),
      );
}

// ─── Sheet para agregar ─────────────────────────────────────────────────────

class _AgregarHistorialSheet extends StatefulWidget {
  final VoidCallback onGuardado;
  const _AgregarHistorialSheet({required this.onGuardado});

  @override
  State<_AgregarHistorialSheet> createState() => _AgregarHistorialSheetState();
}

class _AgregarHistorialSheetState extends State<_AgregarHistorialSheet> {
  final _formKey = GlobalKey<FormState>();
  final _torneoCtrl = TextEditingController();
  final _equipoCtrl = TextEditingController();
  final _logroCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  String? _posicion;
  bool _guardando = false;

  @override
  void dispose() {
    _torneoCtrl.dispose();
    _equipoCtrl.dispose();
    _logroCtrl.dispose();
    _anioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ApiClient.instance.dio.post('/jugadores/me/historial', data: {
        'torneo': _torneoCtrl.text.trim(),
        'equipo': _equipoCtrl.text.trim(),
        if (_anioCtrl.text.isNotEmpty) 'anio': int.tryParse(_anioCtrl.text),
        if (_posicion != null) 'posicion': _posicion,
        if (_logroCtrl.text.isNotEmpty) 'logro': _logroCtrl.text.trim(),
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Agregar torneo / liga',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _torneoCtrl,
                decoration: _deco('Nombre del torneo / liga *', Icons.emoji_events_rounded),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _equipoCtrl,
                decoration: _deco('Equipo / Club *', Icons.group_rounded),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _anioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _deco('Año', Icons.calendar_today_rounded),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 1970 || n > 2100) return 'Año inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _posicion,
                      decoration: _deco('Posición', Icons.sports_soccer_rounded),
                      hint: const Text('Pos.', style: TextStyle(fontSize: 12)),
                      items: AppConstants.posiciones
                          .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => setState(() => _posicion = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logroCtrl,
                decoration: _deco('Logro (opcional)', Icons.military_tech_rounded,
                    hint: 'Ej: Campeón, Goleador, MVP...'),
              ),
              const SizedBox(height: 20),
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
                      : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      );
}
