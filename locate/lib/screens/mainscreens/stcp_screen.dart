import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bus_line.dart';
import '../../services/api_service.dart';
import '../../widgets/bus_list_item.dart';
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

        // filters
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
                      color: theme.colorScheme.onSurface.withAlpha(77)),
                  const SizedBox(height: 12),
                  Text(
                    'Sem liga\u00e7\u00e3o',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(128),
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
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurface.withAlpha(77)),
                    const SizedBox(height: 12),
                    Text(
                      'Sem resultados',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final line = filtered[i];
                return BusListItem(
                  busLine: line,
                  onTap: () => _openDetail(line),
                  onFavoriteToggle: () => _toggleFavorite(line),
                );
              },
            ),
          ),
      ],
    );
  }
}
