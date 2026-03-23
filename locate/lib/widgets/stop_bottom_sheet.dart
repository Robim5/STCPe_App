import 'package:flutter/material.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/eta_info.dart';
import '../services/api_service.dart';

class StopBottomSheet extends StatefulWidget {
  // bus line data
  final BusLine busLine;
  // stop data
  final BusStop stop;
  // direction string
  final String sentido;

  const StopBottomSheet({
    super.key,
    required this.busLine,
    required this.stop,
    required this.sentido,
  });

  @override
  State<StopBottomSheet> createState() => _StopBottomSheetState();
}

class _StopBottomSheetState extends State<StopBottomSheet> {
  final _apiService = ApiService(); // api client
  bool _isLoading = true; // loading state
  List<EtaInfo> _etas = []; // eta results

  @override
  void initState() {
    super.initState();
    _fetchEta(); // load eta
  }

  Future<void> _fetchEta() async {
    // get current etas
    final etas = await _apiService.fetchETA(
      widget.busLine.number,
      widget.stop.codigo,
      widget.sentido,
    );
    if (mounted) {
      setState(() {
        _etas = etas;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(38),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // bus badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.busLine.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Linha ${widget.busLine.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // stop name
            Text(
              widget.stop.nome,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // wait time highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: widget.busLine.color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: widget.busLine.color.withAlpha(38)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _etas.isEmpty
                      ? Column(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: widget.busLine.color, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'Sem previs\u00e3o dispon\u00edvel',
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(153),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Text(
                              'Pr\u00f3ximo autocarro em',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(153),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Icon(Icons.access_time_filled_rounded,
                                    color: widget.busLine.color, size: 36),
                                const SizedBox(width: 12),
                                Text(
                                  '${_etas.first.minutos}',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: widget.busLine.color,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'min',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        widget.busLine.color.withAlpha(180),
                                  ),
                                ),
                              ],
                            ),
                            if (_etas.length > 1) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Seguintes: ${_etas.skip(1).map((e) => '${e.minutos} min').join(', ')}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
            const SizedBox(height: 24),

            // map button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.busLine.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.map_rounded),
                label: const Text(
                  'Ver no Mapa',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
