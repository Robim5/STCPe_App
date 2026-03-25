import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/metro_data_service.dart';
import '../../widgets/trip_planner_modal.dart';
import '../secondscreens/metro_detail_screen.dart';

class MetroScreen extends StatefulWidget {
  const MetroScreen({super.key});

  @override
  State<MetroScreen> createState() => _MetroScreenState();
}

class _MetroScreenState extends State<MetroScreen> {
  static const _lineColors = <String, Color>{
    'A': Color(0xFF0072CE),
    'B': Color(0xFFE4002B),
    'C': Color(0xFF7CB342),
    'E': Color(0xFF7B1FA2),
    'F': Color(0xFFF57C00),
  };

  final _service = MetroDataService();
  Set<String> _favLines = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.loadAll();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favLines = (prefs.getStringList('metro_favorites') ?? []).toSet();
      _loaded = true;
    });
  }

  Future<void> _toggleFav(String lineId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favLines.contains(lineId)) {
        _favLines.remove(lineId);
      } else {
        _favLines.add(lineId);
      }
    });
    await prefs.setStringList('metro_favorites', _favLines.toList());
  }

  void _openLine(String lineId) {
    final dirs = _service.getDirections(lineId);
    if (dirs.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MetroDetailScreen(
          lineId: lineId,
          lineColor: _lineColors[lineId] ?? Colors.grey,
          directions: dirs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // trip planned card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showTripPlannerModal(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withAlpha(180),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Planear Viagem',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Encontrar a melhor rota entre paragens',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withAlpha(160), size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Linhas de Metro',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList.separated(
            itemCount: _service.lines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final id = _service.lines[i];
              final dirs = _service.getDirections(id);
              final dirLabel = dirs.length == 2
                  ? '${dirs[0]}  ${dirs[1]}'
                  : dirs.join(', ');
              final isFav = _favLines.contains(id);

              return _MetroLineTile(
                lineId: id,
                color: _lineColors[id] ?? Colors.grey,
                directionLabel: dirLabel,
                directions: dirs,
                isFavorite: isFav,
                onTap: () => _openLine(id),
                onToggleFav: () => _toggleFav(id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetroLineTile extends StatelessWidget {
  final String lineId;
  final Color color;
  final String directionLabel;
  final List<String> directions;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;

  const _MetroLineTile({
    required this.lineId,
    required this.color,
    required this.directionLabel,
    required this.directions,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(51),
            ),
          ),
          child: Row(
            children: [
              // line icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  lineId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // line name + directions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linha $lineId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (directions.length == 2)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              directions[0],
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(160),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.compare_arrows_rounded,
                              size: 16,
                              color: color.withAlpha(180),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              directions[1],
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(160),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        directionLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              theme.colorScheme.onSurface.withAlpha(160),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // favorite heart
              IconButton(
                onPressed: onToggleFav,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : color.withAlpha(130),
                  size: 22,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
