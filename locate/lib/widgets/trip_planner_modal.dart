import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/metro_data_service.dart';

const _lineColors = <String, Color>{
  'A': Color(0xFF0072CE),
  'B': Color(0xFFE4002B),
  'C': Color(0xFF7CB342),
  'E': Color(0xFF7B1FA2),
  'F': Color(0xFFF57C00),
};

void showTripPlannerModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TripPlannerSheet(),
  );
}

class _TripPlannerSheet extends StatefulWidget {
  const _TripPlannerSheet();

  @override
  State<_TripPlannerSheet> createState() => _TripPlannerSheetState();
}

// bottom sheet modal to plan trip inserting things
class _TripPlannerSheetState extends State<_TripPlannerSheet> {
  final _service = MetroDataService();
  final _resultKey = GlobalKey();

  String? _origin;
  String? _destination;
  TimeOfDay _time = TimeOfDay.now();
  List<TripPlan>? _results;
  bool _calculating = false;

  List<String> get _allStops => _service.allStopNames;

  void _calculate() {
    if (_origin == null || _destination == null) return;
    if (_origin == _destination) return;

    final now = DateTime.now();
    final depTime = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    setState(() {
      _calculating = true;
      _results = null;
    });

    // run synchronously since its a fast in memory operation
    final plans = _service.planTrip(_origin!, _destination!, depTime);
    setState(() {
      _results = plans;
      _calculating = false;
    });
  }

  Future<void> _saveAsImage() async {
    final boundary =
        _resultKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();
    if (!mounted) return;

    // show share dialog
    await _showSaveDialog(bytes);
  }

  Future<void> _showSaveDialog(Uint8List bytes) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagem capturada! Utilize screenshot para partilhar.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.route_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Planear Viagem',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _StopAutocomplete(
                    label: 'Origem',
                    icon: Icons.trip_origin_rounded,
                    stops: _allStops,
                    value: _origin,
                    onSelected: (v) => setState(() => _origin = v),
                  ),
                  const SizedBox(height: 10),
                  _StopAutocomplete(
                    label: 'Destino',
                    icon: Icons.place_rounded,
                    stops: _allStops,
                    value: _destination,
                    onSelected: (v) => setState(() => _destination = v),
                  ),
                  const SizedBox(height: 10),
                  // time picker row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(40),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Partida',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(120),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // calculate button
                      FilledButton.icon(
                        onPressed: _origin != null && _destination != null
                            ? _calculate
                            : null,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Calcular'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // results
            if (_calculating)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_results != null)
              Flexible(
                child: _results!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 36,
                              color: theme.colorScheme.onSurface.withAlpha(80),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nenhuma rota encontrada',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  140,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tente outro horario ou paragens',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  100,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: RepaintBoundary(
                          key: _resultKey,
                          child: Container(
                            color: theme.scaffoldBackgroundColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // save button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _saveAsImage,
                                    icon: const Icon(
                                      Icons.photo_camera_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Guardar'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                for (int i = 0; i < _results!.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _TripPlanCard(plan: _results![i], index: i),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// stop autocomplete input field
class _StopAutocomplete extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> stops;
  final String? value;
  final ValueChanged<String> onSelected;

  const _StopAutocomplete({
    required this.label,
    required this.icon,
    required this.stops,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Autocomplete<String>(
      optionsBuilder: (text) {
        if (text.text.isEmpty) return stops;
        final lower = text.text.toLowerCase();
        return stops.where((s) => s.toLowerCase().contains(lower));
      },
      onSelected: onSelected,
      fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
        if (value != null && controller.text.isEmpty) {
          controller.text = value!;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(40),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(40),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (ctx, onSel, opts) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (_, i) {
                  final opt = opts.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(opt, style: const TextStyle(fontSize: 13)),
                    onTap: () => onSel(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// trip plan card widget
class _TripPlanCard extends StatelessWidget {
  final TripPlan plan;
  final int index;

  const _TripPlanCard({required this.plan, required this.index});

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _durationStr(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}min';
    return '${m ~/ 60}h${(m % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row with duration and transfers
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Opcao ${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
              const SizedBox(width: 4),
              Text(
                _durationStr(plan.totalDuration),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
              if (plan.transfers > 0) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
                const SizedBox(width: 4),
                Text(
                  '${plan.transfers} transf.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // legs
          for (int i = 0; i < plan.legs.length; i++) ...[
            if (i > 0) _buildTransfer(theme, plan.legs[i - 1], plan.legs[i]),
            _buildLeg(theme, plan.legs[i]),
          ],

          const SizedBox(height: 8),
          // total times
          Row(
            children: [
              Text(
                '${_fmt(plan.departureTime)} \u2192 ${_fmt(plan.arrivalTime)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeg(ThemeData theme, TripLeg leg) {
    final color = _lineColors[leg.lineId] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // line badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              leg.lineId,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _fmt(leg.boardTime),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leg.boardStop,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 2, bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 16,
                        color: color.withAlpha(80),
                      ),
                      const SizedBox(width: 10),
                      if (leg.service.isExpress)
                        _serviceBadge('Expresso', Colors.orange)
                      else if (leg.service.isPartial)
                        _serviceBadge(leg.service.nome, Colors.amber.shade700),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _fmt(leg.alightTime),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leg.alightStop,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransfer(ThemeData theme, TripLeg prev, TripLeg next) {
    final waitMins = next.boardTime.difference(prev.alightTime).inMinutes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.swap_horiz_rounded,
            size: 16,
            color: theme.colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(width: 8),
          Text(
            'Transbordo em ${prev.alightStop} ($waitMins min)',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
