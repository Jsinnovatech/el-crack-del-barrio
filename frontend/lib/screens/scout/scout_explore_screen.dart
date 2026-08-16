import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/jugador_explorar.dart';
import '../../state/app_state.dart';
import '../../widgets/player_card.dart';
import 'scout_player_detail_screen.dart';

class ScoutExploreScreen extends StatefulWidget {
  const ScoutExploreScreen({super.key});

  @override
  State<ScoutExploreScreen> createState() => _ScoutExploreScreenState();
}

class _ScoutExploreScreenState extends State<ScoutExploreScreen> {
  final _busquedaCtrl = TextEditingController();
  List<JugadorExplorar> _jugadores = [];
  bool _cargando = true;

  // Filtros
  String? _posicion;
  String? _ciudad;
  RangeValues _edadRange = const RangeValues(16, 45);
  bool _soloVerificados = false;
  String _orden = 'rating';

  // Comparar
  final List<JugadorExplorar> _comparar = [];

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);
    try {
      final body = {
        if (_busquedaCtrl.text.trim().isNotEmpty) 'busqueda': _busquedaCtrl.text.trim(),
        if (_posicion != null) 'posicion': _posicion,
        if (_ciudad != null) 'ciudad': _ciudad,
        'edad_min': _edadRange.start.round(),
        'edad_max': _edadRange.end.round(),
        'solo_verificados': _soloVerificados,
        'rating_min': 0,
        'orden': _orden,
      };
      final res = await ApiClient.instance.dio.post('/captadores/explorar', data: body);
      setState(() {
        _jugadores = (res.data as List).map((e) => JugadorExplorar.fromJson(e)).toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      isScrollControlled: true,
      builder: (_) => _FiltrosSheet(
        posicion: _posicion,
        ciudad: _ciudad,
        edadRange: _edadRange,
        soloVerificados: _soloVerificados,
        orden: _orden,
        onApply: (p, c, e, sv, o) {
          setState(() {
            _posicion = p;
            _ciudad = c;
            _edadRange = e;
            _soloVerificados = sv;
            _orden = o;
          });
          _buscar();
        },
      ),
    );
  }

  void _toggleComparar(JugadorExplorar jugador) {
    setState(() {
      final idx = _comparar.indexWhere((j) => j.id == jugador.id);
      if (idx >= 0) {
        _comparar.removeAt(idx);
      } else if (_comparar.length < 3) {
        _comparar.add(jugador);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo 3 jugadores para comparar')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritos = context.watch<AppState>().favoritosIds;

    return Stack(
      children: [
        Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _busquedaCtrl,
                      onSubmitted: (_) => _buscar(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar jugador...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                        suffixIcon: _busquedaCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _busquedaCtrl.clear();
                                  _buscar();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _abrirFiltros,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: const Icon(Icons.tune, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            // Lista
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _jugadores.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('Sin resultados', style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _buscar,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              16, 4, 16, _comparar.isNotEmpty ? 80 : 16,
                            ),
                            itemCount: _jugadores.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, i) {
                              final j = _jugadores[i];
                              return PlayerCard(
                                jugador: j,
                                isFavorito: favoritos.contains(j.id),
                                showCompareCheck: true,
                                isCompareChecked: _comparar.any((c) => c.id == j.id),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ScoutPlayerDetailScreen(jugador: j),
                                  ),
                                ),
                                onFavorito: () => context.read<AppState>().toggleFavorito(j.id),
                                onCompareToggle: () => _toggleComparar(j),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        // Barra de comparar flotante
        if (_comparar.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.borderDefault),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comparar ${_comparar.length} jugador${_comparar.length > 1 ? 'es' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {/* TODO: navegar a CompareScreen */},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Comparar', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FiltrosSheet extends StatefulWidget {
  final String? posicion;
  final String? ciudad;
  final RangeValues edadRange;
  final bool soloVerificados;
  final String orden;
  final Function(String?, String?, RangeValues, bool, String) onApply;

  const _FiltrosSheet({
    required this.posicion,
    required this.ciudad,
    required this.edadRange,
    required this.soloVerificados,
    required this.orden,
    required this.onApply,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late String? _posicion;
  late String? _ciudad;
  late RangeValues _edadRange;
  late bool _soloVerificados;
  late String _orden;

  @override
  void initState() {
    super.initState();
    _posicion = widget.posicion;
    _ciudad = widget.ciudad;
    _edadRange = widget.edadRange;
    _soloVerificados = widget.soloVerificados;
    _orden = widget.orden;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Filtros', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _posicion,
              decoration: const InputDecoration(labelText: 'Posición'),
              dropdownColor: AppColors.bgElevated,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...AppConstants.posiciones.map((p) => DropdownMenuItem(value: p, child: Text(p))),
              ],
              onChanged: (v) => setState(() => _posicion = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _ciudad,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              dropdownColor: AppColors.bgElevated,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...AppConstants.ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _ciudad = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Edad: ${_edadRange.start.round()} – ${_edadRange.end.round()} años',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            RangeSlider(
              values: _edadRange,
              min: 16,
              max: 45,
              divisions: 29,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.bgElevated,
              onChanged: (v) => setState(() => _edadRange = v),
            ),
            SwitchListTile(
              value: _soloVerificados,
              onChanged: (v) => setState(() => _soloVerificados = v),
              title: const Text('Solo verificados', style: TextStyle(fontSize: 14)),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            const Text('Ordenar por', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['rating', 'edad', 'verificado'].map((o) {
                final selected = _orden == o;
                return ChoiceChip(
                  label: Text(o[0].toUpperCase() + o.substring(1)),
                  selected: selected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.bgElevated,
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF03150A) : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _orden = o),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_posicion, _ciudad, _edadRange, _soloVerificados, _orden);
              },
              child: const Text('Aplicar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
