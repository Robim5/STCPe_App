import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bus_line.dart';
import '../../services/api_service.dart';
import '../secondscreens/bus_detail_screen.dart';

class StcpScreen extends StatefulWidget {
  const StcpScreen({super.key});

  @override
  State<StcpScreen> createState() => _StcpScreenState();
}

class _StcpScreenState extends State<StcpScreen> {
  final _apiService = ApiService();
  List<BusLine> _allLines = [];
  List<String> _municipalities = ['Todos'];
  String _selectedFilter = 'Todos';
  bool _isLoading = true;
  bool _hasError = false;
  Set<String> _favoriteNumbers = {};

  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteNumbers = (prefs.getStringList('favorites') ?? []).toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteNumbers.toList());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final lines = await _apiService.fetchLinhas();

    if (!mounted) return;

    if (lines.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    // sort numerically
    lines.sort((a, b) {
      final na = int.tryParse(a.number) ?? 9999;
      final nb = int.tryParse(b.number) ?? 9999;
      return na.compareTo(nb);
    });

    for (final line in lines) {
      line.isFavorite = _favoriteNumbers.contains(line.number);
    }

    final muniSet = lines.map((l) => l.municipality).toSet();
    final muniList = muniSet.toList()..sort();
    muniList.insert(0, 'Todos');

    setState(() {
      _allLines = lines;
      _municipalities = muniList;
      _isLoading = false;
    });
  }

  List<BusLine> get _filteredLines {
    var list = _allLines;
    if (_selectedFilter != 'Todos') {
      list = list.where((l) => l.municipality == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((l) =>
              l.number.toLowerCase().contains(q) ||
              l.origin.toLowerCase().contains(q) ||
              l.destination.toLowerCase().contains(q) ||
              l.municipality.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _toggleFavorite(BusLine line) {
    setState(() {
      line.isFavorite = !line.isFavorite;
      if (line.isFavorite) {
        _favoriteNumbers.add(line.number);
      } else {
        _favoriteNumbers.remove(line.number);
      }
    });
    _saveFavorites();
  }

  void _openDetail(BusLine line) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BusDetailScreen(busLine: line)),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredLines;

    return CustomScrollView(
      slivers: [
        // search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SearchBar(
              leading:
                  Icon(Icons.search_rounded, color: theme.colorScheme.primary),
              hintText: 'Pesquisar linha ou paragem...',
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),

        // municipality filters
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: _municipalities.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final name = _municipalities[i];
                return FilterChip(
                  label: Text(name),
                  selected: _selectedFilter == name,
                  onSelected: (_) => setState(() => _selectedFilter = name),
                );
              },
            ),
          ),
        ),

        // section title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Linhas de Autocarro',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // content
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hasError)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurface.withAlpha(100)),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar linhas',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: _fetchData,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final line = filtered[i];
                return _BusLineTile(
                  line: line,
                  onTap: () => _openDetail(line),
                  onToggleFav: () => _toggleFavorite(line),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BusLineTile extends StatelessWidget {
  final BusLine line;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;

  const _BusLineTile({
    required this.line,
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
              // line number badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: line.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  line.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // directions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Linha ${line.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primaryContainer.withAlpha(100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            line.municipality,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            line.origin,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withAlpha(160),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 16,
                            color: line.color.withAlpha(180),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            line.destination,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withAlpha(160),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // favorite heart
              IconButton(
                onPressed: onToggleFav,
                icon: Icon(
                  line.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: line.isFavorite
                      ? Colors.redAccent
                      : line.color.withAlpha(130),
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
