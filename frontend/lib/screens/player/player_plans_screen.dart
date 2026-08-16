import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../models/plan.dart';

/// Pantalla de Planes del Jugador.
/// TODO: integrar pasarela real (Culqi/Niubiz o agregador Yape/Plin) en vez del
/// flujo simulado; la confirmación de pago debe llegar por webhook, no desde el cliente.
class PlayerPlansScreen extends StatefulWidget {
  const PlayerPlansScreen({super.key});

  @override
  State<PlayerPlansScreen> createState() => _PlayerPlansScreenState();
}

class _PlayerPlansScreenState extends State<PlayerPlansScreen> {
  List<Plan> _planes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.instance.dio.get('/planes');
      setState(() {
        _planes = (res.data as List).map((e) => Plan.fromJson(e)).toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _elegirPlan(Plan plan) async {
    try {
      final pago = await ApiClient.instance.dio.post('/planes/pagos', data: {
        'plan_id': plan.id,
        'metodo': 'yape',
      });
      // TODO: reemplazar por la redirección real a la pasarela de pago.
      await ApiClient.instance.dio.post('/planes/pagos/${pago.data['id']}/confirmar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan "${plan.nombre}" activado')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo procesar el pago')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Planes de visibilidad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._planes.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        if (p.destacado)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Text('MEJOR VALOR', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('S/ ${p.precio.toStringAsFixed(2)} · ${p.unidad}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    const SizedBox(height: 10),
                    ...p.beneficios.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            const Icon(Icons.check_circle, size: 15, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Expanded(child: Text(b, style: const TextStyle(fontSize: 12.5))),
                          ]),
                        )),
                    const SizedBox(height: 12),
                    if (p.precio > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _elegirPlan(p),
                          child: const Text('Activar plan'),
                        ),
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
