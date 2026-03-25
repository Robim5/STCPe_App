import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/arrival_alert.dart';
import '../../services/metro_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/alert_creation_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> _favBusNumbers = {};
  Set<String> _favMetroLines = {};
  Set<String> _favBusStops = {};
  Set<String> _favMetroStops = {};

  List<ArrivalAlert> _alerts = [];
  bool _stcpAlertEnabled = true;
  bool _metroAlertEnabled = true;

  final _metroDataService = MetroDataService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _metroDataService.loadAll();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favBusNumbers = (prefs.getStringList('favorites') ?? []).toSet();
      _favMetroLines =
          (prefs.getStringList('metro_favorites') ?? []).toSet();
      _favBusStops = (prefs.getStringList('fav_bus_stops') ?? []).toSet();
      _favMetroStops =
          (prefs.getStringList('fav_metro_stops') ?? []).toSet();

      final alertsJson = prefs.getString('arrival_alerts');
      if (alertsJson != null && alertsJson.isNotEmpty) {
        _alerts = ArrivalAlert.decode(alertsJson);
      }
      _stcpAlertEnabled = prefs.getBool('alert_stcp_enabled') ?? true;
      _metroAlertEnabled = prefs.getBool('alert_metro_enabled') ?? true;
    });
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('arrival_alerts', ArrivalAlert.encode(_alerts));
  }

  Future<void> _addAlert() async {
    if (_alerts.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo de 4 avisos atingido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await showAlertCreationModal(
      context,
      metroLines: _metroDataService.lines,
      metroStopsByLine: _metroDataService.stopsByLine,
      metroDirectionsByLine: _metroDataService.directionsByLine,
    );

    if (result != null) {
      setState(() => _alerts.add(result));
      await _saveAlerts();
    }
  }

  Future<void> _editAlert(int index) async {
    final result = await showAlertCreationModal(
      context,
      existing: _alerts[index],
      metroLines: _metroDataService.lines,
      metroStopsByLine: _metroDataService.stopsByLine,
      metroDirectionsByLine: _metroDataService.directionsByLine,
    );

    if (result != null) {
      setState(() => _alerts[index] = result);
      await _saveAlerts();
    }
  }

  Future<void> _deleteAlert(int index) async {
    final alert = _alerts[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remover aviso',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            Text('Queres remover o aviso para "${alert.stopName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _alerts.removeAt(index));
      await _saveAlerts();
    }
  }

  void _showFavoritesHelp() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Favoritos',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Clique no '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.favorite_rounded,
                            size: 18, color: Colors.redAccent),
                      ),
                      const TextSpan(
                        text:
                            ' no seu autocarro ou metro favorito e nas paragens que mais utiliza!',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasBusFav = _favBusNumbers.isNotEmpty;
    final hasMetroFav = _favMetroLines.isNotEmpty;

    final favBusNumber = hasBusFav ? _favBusNumbers.first : null;
    final busStops = _favBusStops
        .where((s) => s.startsWith('${favBusNumber ?? ''}:'))
        .map((s) => s.split(':').last)
        .take(2)
        .toList();

    final favMetroLine = hasMetroFav ? _favMetroLines.first : null;
    final metroStops = _favMetroStops
        .where((s) => s.startsWith('${favMetroLine ?? ''}:'))
        .map((s) => s.split(':').last)
        .take(2)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // stcp favorites
          Text(
            'Autocarros STCP',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _FavoriteBentoCard(
            hasData: hasBusFav,
            label: favBusNumber,
            routeLabel: hasBusFav ? 'STCP' : null,
            stop1: busStops.isNotEmpty ? busStops[0] : null,
            stop2: busStops.length > 1 ? busStops[1] : null,
            gradientColors: _busGradient(theme),
            backgroundIcon: Icons.directions_bus_rounded,
            onPlaceholderTap: _showFavoritesHelp,
          ),
          const SizedBox(height: 28),

          // metro favorites
          Text(
            'Metro do Porto',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _FavoriteBentoCard(
            hasData: hasMetroFav,
            label: favMetroLine != null ? 'Linha $favMetroLine' : null,
            routeLabel: hasMetroFav ? 'Metro' : null,
            stop1: metroStops.isNotEmpty ? metroStops[0] : null,
            stop2: metroStops.length > 1 ? metroStops[1] : null,
            gradientColors: _metroGradient(theme),
            backgroundIcon: Icons.subway_rounded,
            onPlaceholderTap: _showFavoritesHelp,
          ),
          const SizedBox(height: 28),

          // arrival alerts
          Row(
            children: [
              Expanded(
                child: Text(
                  'Avisos de chegada',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_alerts.length < 4)
                IconButton(
                  onPressed: _addAlert,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Novo aviso',
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_alerts.isEmpty)
            _AlertPlaceholder(onTap: _addAlert)
          else
            Column(
              children: [
                for (int i = 0; i < _alerts.length; i++) ...[
                  AlertCard(
                    alert: _alerts[i],
                    enabled: _alerts[i].type == 'stcp'
                        ? _stcpAlertEnabled
                        : _metroAlertEnabled,
                    onEdit: () => _editAlert(i),
                    onDelete: () => _deleteAlert(i),
                  ),
                  if (i < _alerts.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  List<Color> _busGradient(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return isDark
        ? [AppTheme.darkDark, AppTheme.darkMedium]
        : [AppTheme.lightDark, AppTheme.lightMedium];
  }

  List<Color> _metroGradient(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return isDark
        ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
        : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
  }
}

// empty state placeholder for arrival alerts section
class _AlertPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _AlertPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(40),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.notifications_active_outlined,
                size: 36,
                color: theme.colorScheme.primary.withAlpha(130)),
            const SizedBox(height: 8),
            Text(
              'Adicionar aviso de chegada',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Máximo 4 avisos',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// grid bento card with left main plus right 2 stops
// shows placeholder when [hasData] is false
class _FavoriteBentoCard extends StatelessWidget {
  final bool hasData;
  final String? label;
  final String? routeLabel;
  final String? stop1;
  final String? stop2;
  final List<Color> gradientColors;
  final IconData backgroundIcon;
  final VoidCallback onPlaceholderTap;

  const _FavoriteBentoCard({
    required this.hasData,
    required this.label,
    required this.routeLabel,
    required this.stop1,
    required this.stop2,
    required this.gradientColors,
    required this.backgroundIcon,
    required this.onPlaceholderTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          // left card favorito or placeholder
          Expanded(
            child: hasData
                ? _buildMainCard(theme)
                : _buildPlaceholder(theme),
          ),
          const SizedBox(width: 12),
          // right card with 2 stops or placeholders
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildStopCard(
                    theme,
                    stop1,
                    Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildStopCard(
                    theme,
                    stop2,
                    Icons.location_on_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(backgroundIcon,
                size: 110, color: Colors.white.withAlpha(18)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber[300], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Favorito',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    if (routeLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        routeLabel!,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: onPlaceholderTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 40,
                color: theme.colorScheme.primary.withAlpha(128),
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopCard(ThemeData theme, String? stopName, IconData icon) {
    if (stopName == null) {
      return GestureDetector(
        onTap: onPlaceholderTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(51),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 22,
                  color: theme.colorScheme.primary.withAlpha(128),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adicione',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(51),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stopName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
