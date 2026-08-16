import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';

/// Pantalla de Calendario / disponibilidad del Jugador.
/// Usa table_calendar; los días marcados vienen de GET /jugadores/me/disponibilidad
/// y se guardan con PUT /jugadores/me/disponibilidad.
/// TODO: vista semanal rápida (ver prototipo) y aviso si no se actualiza hace +5 días.
class PlayerCalendarScreen extends StatefulWidget {
  const PlayerCalendarScreen({super.key});

  @override
  State<PlayerCalendarScreen> createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends State<PlayerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, String> _disponibilidad = {}; // fecha (sin hora) -> estado

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.instance.dio.get('/jugadores/me/disponibilidad');
      final mapa = <DateTime, String>{};
      for (final item in res.data) {
        final fecha = DateTime.parse(item['fecha']);
        mapa[DateTime(fecha.year, fecha.month, fecha.day)] = item['estado'];
      }
      setState(() => _disponibilidad = mapa);
    } catch (_) {
      // Sin conexión al backend todavía: se deja el calendario vacío.
    }
  }

  Future<void> _marcarDia(DateTime dia, String estado) async {
    try {
      await ApiClient.instance.dio.put('/jugadores/me/disponibilidad', data: {
        'fecha': '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}',
        'estado': estado,
      });
      setState(() => _disponibilidad[DateTime(dia.year, dia.month, dia.day)] = estado);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar')));
      }
    }
  }

  void _abrirSelectorEstado(DateTime dia) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.circle, color: AppColors.accent),
              title: const Text('Disponible'),
              onTap: () { Navigator.pop(context); _marcarDia(dia, 'disponible'); },
            ),
            ListTile(
              leading: const Icon(Icons.circle, color: AppColors.danger),
              title: const Text('Contratado'),
              onTap: () { Navigator.pop(context); _marcarDia(dia, 'contratado'); },
            ),
            ListTile(
              leading: const Icon(Icons.circle, color: AppColors.textMuted),
              title: const Text('No disponible'),
              onTap: () { Navigator.pop(context); _marcarDia(dia, 'no_disponible'); },
            ),
          ],
        ),
      ),
    );
  }

  Color? _colorDelDia(DateTime dia) {
    final estado = _disponibilidad[DateTime(dia.year, dia.month, dia.day)];
    switch (estado) {
      case 'disponible':
        return AppColors.accent;
      case 'contratado':
        return AppColors.danger;
      case 'no_disponible':
        return AppColors.textMuted;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Text('Disponibilidad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
            _abrirSelectorEstado(selected);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final color = _colorDelDia(day);
              if (color == null) return null;
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color.withOpacity(0.25), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${day.day}'),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Toca un día para marcar tu disponibilidad', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      ],
    );
  }
}
