import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bus_line.dart';
import '../../models/bus_stop.dart';
import '../../models/eta_info.dart';
import '../../services/api_service.dart';

class BusDetailScreen extends StatefulWidget {
  final BusLine busLine;

  const BusDetailScreen({super.key, required this.busLine});

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  final _apiService = ApiService();
  int _selectedDir = 0;
  bool _isLoading = true;
  bool _hasError = false;
  List<BusStop> _stopsIda = [];
  List<BusStop> _stopsVolta = [];
  Set<String> _favStops = {};
  Set<String> _busAtStops = {};
  Timer? _posTimer;

  List<BusStop> get _currentStops =>
      _selectedDir == 0 ? _stopsIda : _stopsVolta;

  String get _currentSentido => _selectedDir == 0 ? 'ida' : 'volta';

  List<String> get _directions => [
        '${widget.busLine.origin} \u2192 ${widget.busLine.destination}',
        '${widget.busLine.destination} \u2192 ${widget.busLine.origin}',
      ];

  @override
  void initState() {
    super.initState();
    _loadFavs();
    _fetchStops();
  }

  @override
  void dispose() {
    _posTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favStops = (prefs.getStringList('fav_bus_stops') ?? []).toSet();
    });
  }

  Future<void> _toggleFavStop(String stopCode) async {
    final key = '${widget.busLine.number}:$stopCode';
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favStops.contains(key)) {
        _favStops.remove(key);
      } else {
        _favStops.add(key);
      }
    });
    await prefs.setStringList('fav_bus_stops', _favStops.toList());
  }

  Future<void> _fetchStops() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final paragens = await _apiService.fetchParagens(widget.busLine.number);

    if (!mounted) return;

    final ida = paragens['ida'] ?? [];
    final volta = paragens['volta'] ?? [];

    if (ida.isEmpty && volta.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _stopsIda = ida;
      _stopsVolta = volta;
      _isLoading = false;
    });

    _refreshPositions();
    _posTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshPositions(),
    );
  }

  Future<void> _refreshPositions() async {
    final data = await _apiService.fetchAutocarrosPosicao(
      widget.busLine.number,
      sentido: _currentSentido,
    );
    if (!mounted || data == null) return;

    final stops = _currentStops;
    final matched = <String>{};

    // try to match bus positions to nearest stop
    final autocarros = data['autocarros'] as List<dynamic>? ?? [];
    for (final bus in autocarros) {
      if (bus is! Map<String, dynamic>) continue;
      final busLat = (bus['lat'] as num?)?.toDouble();
      final busLon = (bus['lon'] as num?)?.toDouble();
      final proxParagem = bus['proxima_paragem'] as String?;

      if (proxParagem != null) {
        matched.add(proxParagem);
        continue;
      }

      if (busLat == null || busLon == null) continue;

      // find nearest stop
      double minDist = double.infinity;
      String? nearest;
      for (final s in stops) {
        final dx = s.lat - busLat;
        final dy = s.lon - busLon;
        final d = dx * dx + dy * dy;
        if (d < minDist) {
          minDist = d;
          nearest = s.codigo;
        }
      }
      if (nearest != null) matched.add(nearest);
    }

    if (mounted) setState(() => _busAtStops = matched);
  }

  void _onDirectionChanged(int i) {
    setState(() {
      _selectedDir = i;
      _busAtStops = {};
    });
    _refreshPositions();
  }

  void _showArrivalModal(BusStop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArrivalSheet(
        busLine: widget.busLine,
        stop: stop,
        sentido: _currentSentido,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stops = _currentStops;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.busLine.color,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.busLine.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Linha ${widget.busLine.number}'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withAlpha(100)),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar paragens',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withAlpha(150)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _fetchStops,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Direction selector
                    if (widget.busLine.hasVolta)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: _DirectionSelector(
                          directions: _directions,
                          selectedIndex: _selectedDir,
                          lineColor: widget.busLine.color,
                          onChanged: _onDirectionChanged,
                        ),
                      ),

                    // Direction header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: widget.busLine.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _directions[_selectedDir],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(180),
                              ),
                            ),
                          ),
                          Text(
                            '${stops.length} paragens',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(120),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Stop list
                    Expanded(
                      child: stops.isEmpty
                          ? Center(
                              child: Text(
                                'Sem paragens neste sentido',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(120)),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 0, 12, 100),
                              itemCount: stops.length,
                              itemBuilder: (_, i) {
                                final stop = stops[i];
                                final favKey =
                                    '${widget.busLine.number}:${stop.codigo}';
                                final isFav = _favStops.contains(favKey);
                                final hasBus =
                                    _busAtStops.contains(stop.codigo);

                                return _BusStopTimelineItem(
                                  stop: stop,
                                  lineColor: widget.busLine.color,
                                  isFavorite: isFav,
                                  isFirst: i == 0,
                                  isLast: i == stops.length - 1,
                                  hasBus: hasBus,
                                  onTap: () => _showArrivalModal(stop),
                                  onToggleFav: () =>
                                      _toggleFavStop(stop.codigo),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

// --- Direction selector widget ---

class _DirectionSelector extends StatelessWidget {
  final List<String> directions;
  final int selectedIndex;
  final Color lineColor;
  final ValueChanged<int> onChanged;

  const _DirectionSelector({
    required this.directions,
    required this.selectedIndex,
    required this.lineColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(40),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(directions.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? lineColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: lineColor.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withAlpha(100),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        directions[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withAlpha(150),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// --- Stop timeline item ---

class _BusStopTimelineItem extends StatefulWidget {
  final BusStop stop;
  final Color lineColor;
  final bool isFavorite;
  final bool isFirst;
  final bool isLast;
  final bool hasBus;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;

  const _BusStopTimelineItem({
    required this.stop,
    required this.lineColor,
    required this.isFavorite,
    required this.isFirst,
    required this.isLast,
    required this.hasBus,
    required this.onTap,
    required this.onToggleFav,
  });

  @override
  State<_BusStopTimelineItem> createState() => _BusStopTimelineItemState();
}

class _BusStopTimelineItemState extends State<_BusStopTimelineItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.hasBus) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BusStopTimelineItem old) {
    super.didUpdateWidget(old);
    if (widget.hasBus && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.hasBus && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dotSize = 14.0;
    const trackWidth = 3.0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // timeline track
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: trackWidth,
                        color: widget.isFirst
                            ? Colors.transparent
                            : widget.lineColor.withAlpha(100),
                      ),
                    ),
                    // dot with pulsing bus indicator
                    if (widget.hasBus)
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Container(
                          width: dotSize + 6,
                          height: dotSize + 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.lineColor
                                .withAlpha((200 * _pulseAnim.value).round()),
                            boxShadow: [
                              BoxShadow(
                                color: widget.lineColor.withAlpha(
                                    (120 * _pulseAnim.value).round()),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (widget.isFirst || widget.isLast)
                              ? widget.lineColor
                              : theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: widget.lineColor,
                            width:
                                (widget.isFirst || widget.isLast) ? 0 : 2.5,
                          ),
                          boxShadow: (widget.isFirst || widget.isLast)
                              ? [
                                  BoxShadow(
                                    color: widget.lineColor.withAlpha(80),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    Expanded(
                      child: Container(
                        width: trackWidth,
                        color: widget.isLast
                            ? Colors.transparent
                            : widget.lineColor.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // stop name + bus badge
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.stop.nome,
                          style: TextStyle(
                            fontWeight: (widget.isFirst || widget.isLast)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (widget.hasBus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.lineColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_bus_rounded,
                                  size: 11, color: widget.lineColor),
                              const SizedBox(width: 3),
                              Text(
                                'A chegar',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.lineColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // favorite button
              IconButton(
                onPressed: widget.onToggleFav,
                icon: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: widget.isFavorite
                      ? Colors.redAccent
                      : theme.colorScheme.onSurface.withAlpha(80),
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// arrival bottom shett
class _ArrivalSheet extends StatefulWidget {
  final BusLine busLine;
  final BusStop stop;
  final String sentido;

  const _ArrivalSheet({
    required this.busLine,
    required this.stop,
    required this.sentido,
  });

  @override
  State<_ArrivalSheet> createState() => _ArrivalSheetState();
}

class _ArrivalSheetState extends State<_ArrivalSheet> {
  final _api = ApiService();
  bool _loading = true;
  List<EtaInfo> _etas = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final etas = await _api.fetchETA(
      widget.busLine.number,
      widget.stop.codigo,
      widget.sentido,
    );
    if (mounted) {
      setState(() {
        _etas = etas;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.busLine.color;
    final hasNext = _etas.isNotEmpty;
    final first = hasNext ? _etas.first : null;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // line badge + stop name
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.busLine.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stop.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: color),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.sentido == 'ida'
                                    ? widget.busLine.destination
                                    : widget.busLine.origin,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(140),
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
              const SizedBox(height: 24),

              // main card
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                )
              else if (!hasNext)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: color, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Sem previsão disponível',
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // hero card with next arrival
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withAlpha(180)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_bus_rounded,
                              color: Colors.white.withAlpha(200), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Linha ${widget.busLine.number}',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Próximo',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${first!.minutos}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            first.minutos == 1 ? 'minuto' : 'minutos',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (first.matricula != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          first.matricula!,
                          style: TextStyle(
                            color: Colors.white.withAlpha(140),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // additional arrivals
                if (_etas.length > 1) ...[
                  const SizedBox(height: 16),
                  ...List.generate(_etas.length - 1, (i) {
                    final eta = _etas[i + 1];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(40),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 18, color: color),
                          const SizedBox(width: 12),
                          Text(
                            '${eta.minutos} min',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              eta.destino,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(150),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (eta.matricula != null)
                            Text(
                              eta.matricula!,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(100),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
