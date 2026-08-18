import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../models/franja.dart';

class PlayerCalendarScreen extends StatefulWidget {
  const PlayerCalendarScreen({super.key});

  @override
  State<PlayerCalendarScreen> createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends State<PlayerCalendarScreen> {
  bool _cargando = true;
  DateTime _focusMes = DateTime.now();
  DateTime _diaSeleccionado = DateTime.now();
  List<Franja> _todasFranjas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/disponibilidad');
      setState(() {
        _todasFranjas = (res.data as List).map((j) => Franja.fromJson(j)).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Franja> get _franjasDelDia {
    final d = _diaSeleccionado;
    return _todasFranjas.where((f) {
      return f.fecha.year == d.year &&
          f.fecha.month == d.month &&
          f.fecha.day == d.day;
    }).toList()
      ..sort((a, b) => (a.horaInicio ?? '').compareTo(b.horaInicio ?? ''));
  }

  List<Franja> _franjasEn(DateTime dia) {
    return _todasFranjas.where((f) {
      return f.fecha.year == dia.year &&
          f.fecha.month == dia.month &&
          f.fecha.day == dia.day;
    }).toList();
  }

  Future<void> _eliminarFranja(String id) async {
    await ApiClient.instance.dio.delete('/jugadores/me/disponibilidad/$id');
    _cargar();
  }

  void _agregarFranja() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgregarFranjaSheet(
        fecha: _diaSeleccionado,
        onGuardado: _cargar,
      ),
    );
  }

  String _formatFecha(DateTime d) {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${d.day} de ${meses[d.month]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final franjasDia = _franjasDelDia;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Mi Disponibilidad'),
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarFranja,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar franja', style: TextStyle(color: Colors.white)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendario
                Container(
                  color: AppColors.bgSurface,
                  child: TableCalendar<Franja>(
                    firstDay: DateTime(2024),
                    lastDay: DateTime(2030),
                    focusedDay: _focusMes,
                    selectedDayPredicate: (d) => isSameDay(d, _diaSeleccionado),
                    eventLoader: _franjasEn,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.3),
                          shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(
                          color: AppColors.warning, shape: BoxShape.circle),
                    ),
                    headerStyle: const HeaderStyle(
                        formatButtonVisible: false, titleCentered: true),
                    onDaySelected: (sel, foc) => setState(() {
                      _diaSeleccionado = sel;
                      _focusMes = foc;
                    }),
                    onPageChanged: (foc) => setState(() => _focusMes = foc),
                  ),
                ),

                // Encabezado día seleccionado
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(_formatFecha(_diaSeleccionado),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      Text('${franjasDia.length} franja(s)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),

                // Lista de franjas
                Expanded(
                  child: franjasDia.isEmpty
                      ? const Center(
                          child: Text(
                              'Sin franjas para este día.\nToca + para agregar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted)),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: franjasDia.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _TarjetaFranja(
                              franja: franjasDia[i],
                              onEliminar: () =>
                                  _eliminarFranja(franjasDia[i].id),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─── Tarjeta de franja ───────────────────────────────────────────────────────

class _TarjetaFranja extends StatelessWidget {
  final Franja franja;
  final VoidCallback onEliminar;
  const _TarjetaFranja({required this.franja, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final esOcupado = franja.esOcupado;
    final color = esOcupado ? AppColors.danger : AppColors.success;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(
            esOcupado ? Icons.block_rounded : Icons.check_circle_rounded,
            color: color,
          ),
        ),
        title: Text(esOcupado ? 'Ocupado' : 'Libre',
            style:
                TextStyle(fontWeight: FontWeight.w700, color: color)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (franja.horaInicio != null || franja.horaFin != null)
              Text(
                '${franja.horaInicio ?? '--:--'}  →  ${franja.horaFin ?? '--:--'}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            if (franja.descripcion != null &&
                franja.descripcion!.isNotEmpty)
              Text(franja.descripcion!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.textMuted, size: 20),
          onPressed: onEliminar,
        ),
      ),
    );
  }
}

// ─── Sheet para agregar franja ───────────────────────────────────────────────

class _AgregarFranjaSheet extends StatefulWidget {
  final DateTime fecha;
  final VoidCallback onGuardado;
  const _AgregarFranjaSheet({required this.fecha, required this.onGuardado});

  @override
  State<_AgregarFranjaSheet> createState() => _AgregarFranjaSheetState();
}

class _AgregarFranjaSheetState extends State<_AgregarFranjaSheet> {
  String _estado = 'libre';
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final _descCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatHora(TimeOfDay? t) {
    if (t == null) return 'Seleccionar';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickHora(bool esInicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime: esInicio
          ? (_horaInicio ?? const TimeOfDay(hour: 8, minute: 0))
          : (_horaFin ?? const TimeOfDay(hour: 9, minute: 0)),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() => esInicio ? _horaInicio = t : _horaFin = t);
    }
  }

  Future<void> _guardar() async {
    if (_horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona hora de inicio y fin')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final d = widget.fecha;
      final fechaStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await ApiClient.instance.dio.post('/jugadores/me/disponibilidad', data: {
        'fecha': fechaStr,
        'hora_inicio': _formatHora(_horaInicio),
        'hora_fin': _formatHora(_horaFin),
        'estado': _estado,
        if (_descCtrl.text.trim().isNotEmpty)
          'descripcion': _descCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final d = widget.fecha;
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final fechaLabel = '${d.day} de ${meses[d.month]} de ${d.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
          color: AppColors.bgSurface, borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Agregar franja — $fechaLabel',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Estado
            const Text('Estado',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _EstadoBtn(
                        label: 'Libre',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        sel: _estado == 'libre',
                        onTap: () => setState(() => _estado = 'libre'))),
                const SizedBox(width: 10),
                Expanded(
                    child: _EstadoBtn(
                        label: 'Ocupado',
                        icon: Icons.block_rounded,
                        color: AppColors.danger,
                        sel: _estado == 'ocupado',
                        onTap: () =>
                            setState(() => _estado = 'ocupado'))),
              ],
            ),
            const SizedBox(height: 16),

            // Horas
            const Text('Horario',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _HoraSelector(
                        label: 'Inicio',
                        hora: _formatHora(_horaInicio),
                        onTap: () => _pickHora(true))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.textMuted),
                ),
                Expanded(
                    child: _HoraSelector(
                        label: 'Fin',
                        hora: _formatHora(_horaFin),
                        onTap: () => _pickHora(false))),
              ],
            ),
            const SizedBox(height: 16),

            // Descripción
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej: Liga Distrital, Entreno, Libre...',
                prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar franja',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool sel;
  final VoidCallback onTap;
  const _EstadoBtn({
    required this.label, required this.icon,
    required this.color, required this.sel, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.15) : AppColors.bgBase,
          border: Border.all(
              color: sel ? color : AppColors.textMuted.withOpacity(0.3),
              width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: sel ? color : AppColors.textMuted, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sel ? color : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _HoraSelector extends StatelessWidget {
  final String label;
  final String hora;
  final VoidCallback onTap;
  const _HoraSelector(
      {required this.label, required this.hora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.accent.withOpacity(0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(hora,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
