import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_line.dart';
import '../services/api_service.dart';
import '../widgets/bento_favorites.dart';
import '../widgets/bus_list_item.dart';
import 'bus_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService(); // api client instance
  List<BusLine> _allLines = []; // full lines data
  List<String> _municipalities = ['Todos']; // filter options
  String _selectedFilter = 'Todos'; // active filter (default)
  bool _isLoading = true; // loading state
  bool _hasError = false; // error state
  Set<String> _favoriteNumbers = {}; // saved favorites

  String _searchQuery = ''; // typed query
  Timer? _debounce; // search debounce timer

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // restore saved favorites
    _fetchData(); // load lines
  }

  @override
  void dispose() {
    _debounce?.cancel(); // clear timer
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
    // fetch all lines
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

    // apply saved favorites
    for (final line in lines) {
      line.isFavorite = _favoriteNumbers.contains(line.number);
    }

    // build municipality filters
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
    var list = _allLines; // start from all
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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 19) return 'Boa tarde';
    return 'Boa noite';
  }

  void _toggleFavorite(BusLine line) {
    // toggle favorite state
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
    // navigate detail page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BusDetailScreen(busLine: line)),
    );
  }

  void _onSearchChanged(String value) {
    // throttled query update
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredLines;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // app bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const Text(
                    'STCPe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: SearchBar(
                leading: Icon(Icons.search_rounded,
                    color: theme.colorScheme.primary),
                hintText: 'Pesquisar linha ou paragem...',
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          // favourites title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Os Teus Favoritos',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),

          // bento grid 
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: BentoFavorites(),
            ),
          ),

          // lines title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: Text(
                'Linhas',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // filters line
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: _municipalities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final name = _municipalities[i];
                  return FilterChip(
                    label: Text(name),
                    selected: _selectedFilter == name,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = name),
                  );
                },
              ),
            ),
          ),

          // loading / error / content
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
                          color:
                              theme.colorScheme.onSurface.withAlpha(77)),
                      const SizedBox(height: 12),
                      Text(
                        'Sem resultados',
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withAlpha(128),
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
                separatorBuilder: (_, _) => const SizedBox(height: 8),
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
      ),
    );
  }
}

