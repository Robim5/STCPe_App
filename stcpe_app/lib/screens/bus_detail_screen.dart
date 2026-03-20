import 'package:flutter/material.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../services/api_service.dart';
import '../widgets/stop_bottom_sheet.dart';
import '../widgets/stop_timeline_item.dart';

// bus line model data
class BusDetailScreen extends StatefulWidget {
  final BusLine busLine;

  const BusDetailScreen({super.key, required this.busLine});

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  final _apiService = ApiService();
  bool _isForward = true; // current direction flag
  bool _isLoading = true; // loading indicator state
  bool _hasError = false; // error indicator state
  List<BusStop> _stopsIda = []; // forward stops
  List<BusStop> _stopsVolta = []; // reverse stops

  List<BusStop> get _currentStops =>
      _isForward ? _stopsIda : _stopsVolta; // current list

  String get _currentDirection => _isForward
      ? widget.busLine.forwardLabel
      : widget.busLine.reverseLabel; // direction text

  String get _currentSentido => _isForward ? 'ida' : 'volta'; // direction code

  @override
  void initState() {
    super.initState();
    _fetchStops();
  }

  // fetch stops data
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
  }

  // switch direction state
  void _toggleDirection() {
    setState(() => _isForward = !_isForward);
  }

  // open bottom sheet
  void _showStopDetails(BusStop stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StopBottomSheet(
        busLine: widget.busLine,
        stop: stop,
        sentido: _currentSentido,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.busLine.color,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.busLine.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentDirection,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(230),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurface.withAlpha(77),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sem liga\u00e7\u00e3o',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: _fetchStops,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _currentStops.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurface.withAlpha(77),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sem paragens neste sentido',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _currentStops.length,
              itemBuilder: (_, i) {
                final stop = _currentStops[i];
                return StopTimelineItem(
                  stopName: stop.nome,
                  lineColor: widget.busLine.color,
                  isFirst: i == 0,
                  isLast: i == _currentStops.length - 1,
                  onTap: () => _showStopDetails(stop),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleDirection,
        backgroundColor: widget.busLine.color,
        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
        label: const Text(
          'Trocar Sentido',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
