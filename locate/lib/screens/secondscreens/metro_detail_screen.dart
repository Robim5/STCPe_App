import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/metro_data_service.dart';

class MetroDetailScreen extends StatefulWidget {
  final String lineId;
  final Color lineColor;
  final List<String> directions;

  const MetroDetailScreen({
    super.key,
    required this.lineId,
    required this.lineColor,
    required this.directions,
  });

  @override
  State<MetroDetailScreen> createState() => _MetroDetailScreenState();
}

class _MetroDetailScreenState extends State<MetroDetailScreen> {
  final _service = MetroDataService();
  int _selectedDir = 0;
  Set<String> _favStops = {};
  Set<int> _metroPositions = {};
  Timer? _posTimer;

  @override
  void initState() {
    super.initState();
    _loadFavs();
    _refreshPositions();
    _posTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshPositions(),
    );
  }

  @override
  void dispose() {
    _posTimer?.cancel();
    super.dispose();
  }

  void _refreshPositions() {
    final pos = _service.getMetroPositions(
        widget.lineId, _currentDirection);
    if (mounted) setState(() => _metroPositions = pos);
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favStops = (prefs.getStringList('fav_metro_stops') ?? []).toSet();
    });
  }

  Future<void> _toggleFavStop(String stopName) async {
    final key = '${widget.lineId}:$stopName';
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favStops.contains(key)) {
        _favStops.remove(key);
      } else {
        _favStops.add(key);
      }
    });
    await prefs.setStringList('fav_metro_stops', _favStops.toList());
  }

  String get _currentDirection => widget.directions[_selectedDir];

  List<MetroStopSchedule> get _stops =>
      _service.getStops(widget.lineId, _currentDirection);

  void _onDirectionChanged(int i) {
    setState(() => _selectedDir = i);
    _refreshPositions();
  }

  void _showArrivalModal(MetroStopSchedule stop) {
    final now = DateTime.now();
    final arrivals = _service.getNextArrivalsDetailed(
      widget.lineId,
      _currentDirection,
      stop.nome,
      count: 4,
      now: now,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArrivalSheet(
        stopName: stop.nome,
        lineId: widget.lineId,
        lineColor: widget.lineColor,
        direction: _currentDirection,
        arrivals: arrivals,
        now: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stops = _stops;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.lineColor,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.lineId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Linha ${widget.lineId}'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Direction selector
          if (widget.directions.length == 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _DirectionSelector(
                directions: widget.directions,
                selectedIndex: _selectedDir,
                lineColor: widget.lineColor,
                onChanged: _onDirectionChanged,
              ),
            ),

          // Direction header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: widget.lineColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentDirection,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                ),
                Text(
                  '${stops.length} paragens',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Stop list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              itemCount: stops.length,
              itemBuilder: (_, i) {
                final stop = stops[i];
                final favKey = '${widget.lineId}:${stop.nome}';
                final isFav = _favStops.contains(favKey);
                final isFirst = i == 0;
                final isLast = i == stops.length - 1;
                final hasMetro = _metroPositions.contains(i);

                return _StopTimelineItem(
                  stop: stop,
                  lineColor: widget.lineColor,
                  isFavorite: isFav,
                  isFirst: isFirst,
                  isLast: isLast,
                  hasMetro: hasMetro,
                  onTap: () => _showArrivalModal(stop),
                  onToggleFav: () => _toggleFavStop(stop.nome),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// diretion selector
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

// stop timeline item

class _StopTimelineItem extends StatefulWidget {
  final MetroStopSchedule stop;
  final Color lineColor;
  final bool isFavorite;
  final bool isFirst;
  final bool isLast;
  final bool hasMetro;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;

  const _StopTimelineItem({
    required this.stop,
    required this.lineColor,
    required this.isFavorite,
    required this.isFirst,
    required this.isLast,
    required this.hasMetro,
    required this.onTap,
    required this.onToggleFav,
  });

  @override
  State<_StopTimelineItem> createState() => _StopTimelineItemState();
}

class _StopTimelineItemState extends State<_StopTimelineItem>
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
    if (widget.hasMetro) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StopTimelineItem old) {
    super.didUpdateWidget(old);
    if (widget.hasMetro && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.hasMetro && _pulseCtrl.isAnimating) {
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
              // time line track
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    // top line
                    Expanded(
                      child: Container(
                        width: trackWidth,
                        color: widget.isFirst
                            ? Colors.transparent
                            : widget.lineColor.withAlpha(100),
                      ),
                    ),
                    // dot with pulsin metro
                    if (widget.hasMetro)
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
                                color: widget.lineColor
                                    .withAlpha((120 * _pulseAnim.value).round()),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.subway_rounded,
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
                            width: (widget.isFirst || widget.isLast) ? 0 : 2.5,
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
                    // bottom line
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
              // stop name + metro icon if has metro
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
                      if (widget.hasMetro)
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
                              Icon(Icons.subway_rounded,
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

// arrival info bottom

class _ArrivalSheet extends StatelessWidget {
  final String stopName;
  final String lineId;
  final Color lineColor;
  final String direction;
  final List<ArrivalInfo> arrivals;
  final DateTime now;

  const _ArrivalSheet({
    required this.stopName,
    required this.lineId,
    required this.lineColor,
    required this.direction,
    required this.arrivals,
    required this.now,
  });

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return 'agora';
    if (minutes == 1) return '1 minuto';
    return '$minutes minutos';
  }

  Widget _buildServiceBadge(ArrivalInfo a, ThemeData theme) {
    if (a.service.isNormal) return const SizedBox.shrink();
    final color = a.service.isExpress
        ? Colors.orange
        : Colors.amber.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        a.serviceLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNext = arrivals.isNotEmpty;
    final first = hasNext ? arrivals[0] : null;
    final nextMin = first?.minutesFrom(now) ?? 0;

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

              // line icon + stop name + direction
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lineId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: lineColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                direction,
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

              // next arrival info with hero card
              if (hasNext && first != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        lineColor,
                        lineColor.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: lineColor.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.subway_rounded,
                              color: Colors.white.withAlpha(200),
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Linha $lineId',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!first.service.isNormal)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                first.serviceLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          if (nextMin <= 0)
                            const Text(
                              'A chegar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            )
                          else
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$nextMin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 36,
                                      height: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' min',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // route info
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          first.routeLabel,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // service warning
                      if (first.service.isExpress)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.bolt_rounded,
                                  size: 14,
                                  color: Colors.amber.shade200),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Expresso \u2013 nao para em todas as estacoes',
                                  style: TextStyle(
                                    color: Colors.amber.shade100,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (first.service.isPartial)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 14,
                                  color: Colors.amber.shade200),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  first.service.descricao.isNotEmpty
                                      ? first.service.descricao
                                      : '${first.service.nome} \u2013 servico parcial',
                                  style: TextStyle(
                                    color: Colors.amber.shade100,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.subway_rounded,
                          size: 36,
                          color: theme.colorScheme.onSurface.withAlpha(80)),
                      const SizedBox(height: 8),
                      Text(
                        'Sem mais metros hoje',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),

              // following arrivals
              if (arrivals.length > 1) ...[
                const SizedBox(height: 14),
                ...arrivals.skip(1).map((a) {
                  final mins = a.minutesFrom(now);
                  final timeStr =
                      '${a.time.hour.toString().padLeft(2, '0')}:${a.time.minute.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(40),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 16, color: lineColor.withAlpha(160)),
                          const SizedBox(width: 8),
                          Text(
                            mins <= 0
                                ? 'a chegar'
                                : 'em ${_formatMinutes(mins)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(180),
                            ),
                          ),
                          _buildServiceBadge(a, theme),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
