import 'dart:convert';
import 'dart:math' show min;
import 'package:flutter/services.dart';

// single stop with its departure times
class MetroStopSchedule {
  final String nome;
  final List<String> horarios;
  const MetroStopSchedule({required this.nome, required this.horarios});
}

// variant metro service (normal, express, parcial)
class MetroService {
  final String tipo;
  final String nome;
  final String descricao;
  final List<MetroStopSchedule> stops;

  const MetroService({
    required this.tipo,
    required this.nome,
    required this.descricao,
    required this.stops,
  });

  bool get isExpress => tipo.endsWith('X');
  bool get isNormal => tipo.length == 1;
  bool get isPartial => !isNormal && !isExpress;
  String get firstStop => stops.isNotEmpty ? stops.first.nome : '';
  String get lastStop => stops.isNotEmpty ? stops.last.nome : '';
}

// info about an arrival at a stop
class ArrivalInfo {
  final DateTime time;
  final String lineId;
  final String direction;
  final MetroService service;
  final int departureIndex;

  const ArrivalInfo({
    required this.time,
    required this.lineId,
    required this.direction,
    required this.service,
    required this.departureIndex,
  });

  int minutesFrom(DateTime now) => time.difference(now).inMinutes;

  String get serviceLabel {
    if (service.isExpress) return 'Expresso';
    if (service.isPartial) return service.nome;
    return 'Normal';
  }

  String get routeLabel => '${service.firstStop} \u2192 ${service.lastStop}';
}

// a leg of a planned trip
class TripLeg {
  final String lineId;
  final String direction;
  final String boardStop;
  final String alightStop;
  final DateTime boardTime;
  final DateTime alightTime;
  final MetroService service;

  const TripLeg({
    required this.lineId,
    required this.direction,
    required this.boardStop,
    required this.alightStop,
    required this.boardTime,
    required this.alightTime,
    required this.service,
  });

  Duration get duration => alightTime.difference(boardTime);
}

// a complete trip plan
class TripPlan {
  final List<TripLeg> legs;
  const TripPlan({required this.legs});

  DateTime get departureTime => legs.first.boardTime;
  DateTime get arrivalTime => legs.last.alightTime;
  Duration get totalDuration => arrivalTime.difference(departureTime);
  int get transfers => legs.length - 1;
}

// load metro data from json
class MetroDataService {
  MetroDataService._();
  static final MetroDataService _instance = MetroDataService._();
  factory MetroDataService() => _instance;

  static const _lineIds = ['A', 'B', 'C', 'E', 'F'];

  static const _fileMap = <String, Map<String, List<String>>>{
    'A': {
      'DU': [
        'lib/data/metroData/LinhaA/DU_SrM.json',
        'lib/data/metroData/LinhaA/DU_EstDrag.json',
      ],
      'Sab': [
        'lib/data/metroData/LinhaA/Sab_SrM.json',
        'lib/data/metroData/LinhaA/Sab_EstDrag.json',
      ],
      'DF': [
        'lib/data/metroData/LinhaA/DF_SrM.json',
        'lib/data/metroData/LinhaA/DF_EstDrag.json',
      ],
    },
    'B': {
      'DU': [
        'lib/data/metroData/LinhaB/DU_Povoa.json',
        'lib/data/metroData/LinhaB/DU_EstDrag.json',
      ],
      'Sab': [
        'lib/data/metroData/LinhaB/Sab_Povoa.json',
        'lib/data/metroData/LinhaB/Sab_EstDrag.json',
      ],
      'DF': [
        'lib/data/metroData/LinhaB/DF_Povoa.json',
        'lib/data/metroData/LinhaB/DF_EstDragao.json',
      ],
    },
    'C': {
      'DU': [
        'lib/data/metroData/LinhaC/DU_IsmaiFor.json',
        'lib/data/metroData/LinhaC/DU_EstCamp.json',
      ],
      'Sab': [
        'lib/data/metroData/LinhaC/Sab_IsmaiFor.json',
        'lib/data/metroData/LinhaC/Sab_Camp.json',
      ],
      'DF': [
        'lib/data/metroData/LinhaC/DF_IsmaiFor.json',
        'lib/data/metroData/LinhaC/DF_Campanha.json',
      ],
    },
    'E': {
      'DU': [
        'lib/data/metroData/LinhaE/DU_Aero.json',
        'lib/data/metroData/LinhaE/DU_EstDrag.json',
      ],
      'Sab': [
        'lib/data/metroData/LinhaE/Sab_Aero.json',
        'lib/data/metroData/LinhaE/Sab_EstDrag.json',
      ],
      'DF': [
        'lib/data/metroData/LinhaE/DF_Aero.json',
        'lib/data/metroData/LinhaE/DF_EstDrag.json',
      ],
    },
    'F': {
      'DU': [
        'lib/data/metroData/LinhaF/DU_Fanz.json',
        'lib/data/metroData/LinhaF/DU_SraHora.json',
      ],
      'Sab': [
        'lib/data/metroData/LinhaF/Sab_Fanz.json',
        'lib/data/metroData/LinhaF/Sab_SraHora.json',
      ],
      'DF': [
        'lib/data/metroData/LinhaF/DF_Fanz.json',
        'lib/data/metroData/LinhaF/DF_SraHora.json',
      ],
    },
  };

  // backwards compact
  final Map<String, List<String>> _stopsByLine = {};
  final Map<String, List<String>> _directionsByLine = {};
  final Map<String, Map<String, List<MetroStopSchedule>>> _schedule = {};

  // all services per line + direction
  final Map<String, Map<String, List<MetroService>>> _allServices = {};

  // all unique stops sorted
  List<String> _allStopsSorted = [];

  List<String> get lines => _lineIds;

  Map<String, List<String>> get stopsByLine => Map.unmodifiable(_stopsByLine);

  Map<String, List<String>> get directionsByLine =>
      Map.unmodifiable(_directionsByLine);

  // all unique stop names across all lines sorted
  List<String> get allStopNames => _allStopsSorted;

  List<String> getDirections(String lineId) => _directionsByLine[lineId] ?? [];

  // normal service stop schedules for a line plus direction
  List<MetroStopSchedule> getStops(String lineId, String direction) =>
      _schedule[lineId]?[direction] ?? [];

  List<String> getStopNames(String lineId, String direction) =>
      getStops(lineId, direction).map((s) => s.nome).toList();

  // all services line plus direction
  List<MetroService> getServices(String lineId, String direction) =>
      _allServices[lineId]?[direction] ?? [];

  // the normal service for a line plus direction, or if not available the first one
  MetroService? getNormalService(String lineId, String direction) {
    final svcs = getServices(lineId, direction);
    return svcs.where((s) => s.isNormal).firstOrNull ?? svcs.firstOrNull;
  }

  // arrivals

  // detailed arrival info
  List<ArrivalInfo> getNextArrivalsDetailed(
    String lineId,
    String direction,
    String stopName, {
    int count = 6,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final services = getServices(lineId, direction);
    final arrivals = <ArrivalInfo>[];

    for (final svc in services) {
      final stop = svc.stops.where((s) => s.nome == stopName).firstOrNull;
      if (stop == null) continue;

      for (int k = 0; k < stop.horarios.length; k++) {
        final dt = _parseTime(stop.horarios[k], n);
        if (dt != null && dt.isAfter(n)) {
          arrivals.add(
            ArrivalInfo(
              time: dt,
              lineId: lineId,
              direction: direction,
              service: svc,
              departureIndex: k,
            ),
          );
        }
      }
    }

    arrivals.sort((a, b) => a.time.compareTo(b.time));
    return arrivals.take(count).toList();
  }

  // backward compact
  List<DateTime> getNextArrivals(
    String lineId,
    String direction,
    String stopName, {
    int count = 2,
    DateTime? now,
  }) => getNextArrivalsDetailed(
    lineId,
    direction,
    stopName,
    count: count,
    now: now,
  ).map((a) => a.time).toList();

  // metro position tracking

  /// return stop indices where a train on [lineId] and [direction]
  Set<int> getMetroPositions(String lineId, String direction, {DateTime? now}) {
    final normalStops = getStops(lineId, direction);
    if (normalStops.isEmpty) return {};
    final n = now ?? DateTime.now();
    final positions = <int>{};

    for (final svc in getServices(lineId, direction)) {
      if (svc.stops.length < 2) continue;
      final depCount = svc.stops.map((s) => s.horarios.length).reduce(min);
      for (int k = 0; k < depCount; k++) {
        for (int j = 0; j < svc.stops.length - 1; j++) {
          final tJ = _parseTime(svc.stops[j].horarios[k], n);
          final tJ1 = _parseTime(svc.stops[j + 1].horarios[k], n);
          if (tJ == null || tJ1 == null) continue;

          if (!n.isBefore(tJ) && n.isBefore(tJ1)) {
            // train k is between stop j and j+1 → next stop is j+1
            final nextName = svc.stops[j + 1].nome;
            final idx = normalStops.indexWhere((s) => s.nome == nextName);
            if (idx >= 0) positions.add(idx);
            break; // found this train's position
          }
        }
      }
    }
    return positions;
  }

  // trip planning
  /// plan a trip from [origin] to [destination] departing at [depTime]
  List<TripPlan> planTrip(String origin, String destination, DateTime depTime) {
    if (origin == destination) return [];
    final results = <TripPlan>[];

    // phase 1 direct routes
    for (final line in _lineIds) {
      for (final dir in getDirections(line)) {
        for (final svc in getServices(line, dir)) {
          final names = svc.stops.map((s) => s.nome).toList();
          final oi = names.indexOf(origin);
          final di = names.indexOf(destination);
          if (oi < 0 || di < 0 || oi >= di) continue;

          for (int k = 0; k < svc.stops[oi].horarios.length; k++) {
            final bt = _parseTime(svc.stops[oi].horarios[k], depTime);
            if (bt == null || bt.isBefore(depTime)) continue;
            if (k >= svc.stops[di].horarios.length) continue;
            final at = _parseTime(svc.stops[di].horarios[k], depTime);
            if (at == null) continue;
            results.add(
              TripPlan(
                legs: [
                  TripLeg(
                    lineId: line,
                    direction: dir,
                    boardStop: origin,
                    alightStop: destination,
                    boardTime: bt,
                    alightTime: at,
                    service: svc,
                  ),
                ],
              ),
            );
            break;
          }
        }
      }
    }

    // phase 2 one-transfer routes
    for (final l1 in _lineIds) {
      for (final d1 in getDirections(l1)) {
        final svc1 = getNormalService(l1, d1);
        if (svc1 == null) continue;
        final n1 = svc1.stops.map((s) => s.nome).toList();
        final oi1 = n1.indexOf(origin);
        if (oi1 < 0) continue;

        for (final l2 in _lineIds) {
          for (final d2 in getDirections(l2)) {
            if (l1 == l2 && d1 == d2) continue;
            final svc2 = getNormalService(l2, d2);
            if (svc2 == null) continue;
            final n2 = svc2.stops.map((s) => s.nome).toList();
            final di2 = n2.indexOf(destination);
            if (di2 < 0) continue;

            // find best transfer stop
            for (int ti1 = oi1 + 1; ti1 < n1.length; ti1++) {
              final xfer = n1[ti1];
              final ti2 = n2.indexOf(xfer);
              if (ti2 < 0 || ti2 >= di2) continue;

              // origin -> xfer on line1
              DateTime? bt1, at1;
              int? k1;
              for (int k = 0; k < svc1.stops[oi1].horarios.length; k++) {
                final t = _parseTime(svc1.stops[oi1].horarios[k], depTime);
                if (t == null || t.isBefore(depTime)) continue;
                if (k >= svc1.stops[ti1].horarios.length) continue;
                final a = _parseTime(svc1.stops[ti1].horarios[k], depTime);
                if (a == null) continue;
                bt1 = t;
                at1 = a;
                k1 = k;
                break;
              }
              if (bt1 == null || at1 == null || k1 == null) continue;

              final xferReady = at1.add(const Duration(minutes: 3));

              // xfer -> destination on line2
              DateTime? bt2, at2;
              for (int k = 0; k < svc2.stops[ti2].horarios.length; k++) {
                final t = _parseTime(svc2.stops[ti2].horarios[k], depTime);
                if (t == null || t.isBefore(xferReady)) continue;
                if (k >= svc2.stops[di2].horarios.length) continue;
                final a = _parseTime(svc2.stops[di2].horarios[k], depTime);
                if (a == null) continue;
                bt2 = t;
                at2 = a;
                break;
              }
              if (bt2 == null || at2 == null) continue;

              results.add(
                TripPlan(
                  legs: [
                    TripLeg(
                      lineId: l1,
                      direction: d1,
                      boardStop: origin,
                      alightStop: xfer,
                      boardTime: bt1,
                      alightTime: at1,
                      service: svc1,
                    ),
                    TripLeg(
                      lineId: l2,
                      direction: d2,
                      boardStop: xfer,
                      alightStop: destination,
                      boardTime: bt2,
                      alightTime: at2,
                      service: svc2,
                    ),
                  ],
                ),
              );
              break; // first valid transfer for this pair
            }
          }
        }
      }
    }

    results.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    // deduplicate by route shape
    final seen = <String>{};
    final deduped = <TripPlan>[];
    for (final p in results) {
      final key = p.legs
          .map((l) => '${l.lineId}:${l.direction}:${l.boardStop}')
          .join('|');
      if (seen.add(key)) deduped.add(p);
    }
    return deduped.take(5).toList();
  }

  // helpers
  DateTime? _parseTime(String timeStr, DateTime ref) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    var dt = DateTime(ref.year, ref.month, ref.day, h, m);
    if (h < 4 && ref.hour >= 4) dt = dt.add(const Duration(days: 1));
    return dt;
  }

  String _currentDayType() {
    final weekday = DateTime.now().weekday;
    if (weekday == 7) return 'DF';
    if (weekday == 6) return 'Sab';
    return 'DU';
  }

  // loader
  Future<void> loadAll() async {
    if (_stopsByLine.isNotEmpty) return;

    final dayType = _currentDayType();
    final allStops = <String>{};

    for (final line in _lineIds) {
      final dayFiles = _fileMap[line]?[dayType] ?? [];
      final stopSet = <String>{};
      final dirSet = <String>{};
      final lineSchedule = <String, List<MetroStopSchedule>>{};
      final lineServices = <String, List<MetroService>>{};

      for (final path in dayFiles) {
        try {
          final raw = await rootBundle.loadString(path);
          final data = json.decode(raw) as Map<String, dynamic>;
          final sentido = data['sentido'] as String? ?? '';
          if (sentido.isEmpty) continue;
          dirSet.add(sentido);

          final services = <MetroService>[];

          if (data.containsKey('servicos')) {
            final svcList = data['servicos'] as List<dynamic>;
            var first = true;
            for (final svcData in svcList) {
              final m = svcData as Map<String, dynamic>;
              final tipo = m['tipo'] as String? ?? line;
              final nome = m['nome'] as String? ?? 'Normal';
              final desc = m['descricao'] as String? ?? '';
              final pars = m['paragens'] as List<dynamic>? ?? [];
              final stops = <MetroStopSchedule>[];
              for (final p in pars) {
                final pm = p as Map<String, dynamic>;
                final pn = pm['nome'] as String? ?? '';
                if (pn.isEmpty) continue;
                stopSet.add(pn);
                allStops.add(pn);
                final h =
                    (pm['horarios_partida'] as List<dynamic>?)
                        ?.cast<String>() ??
                    [];
                stops.add(MetroStopSchedule(nome: pn, horarios: h));
              }
              services.add(
                MetroService(
                  tipo: tipo,
                  nome: nome,
                  descricao: desc,
                  stops: stops,
                ),
              );
              if (first) {
                lineSchedule[sentido] = stops;
                first = false;
              }
            }
          } else {
            final pars = data['paragens'] as List<dynamic>? ?? [];
            final stops = <MetroStopSchedule>[];
            for (final p in pars) {
              final pm = p as Map<String, dynamic>;
              final pn = pm['nome'] as String? ?? '';
              if (pn.isEmpty) continue;
              stopSet.add(pn);
              allStops.add(pn);
              final h =
                  (pm['horarios_partida'] as List<dynamic>?)?.cast<String>() ??
                  [];
              stops.add(MetroStopSchedule(nome: pn, horarios: h));
            }
            services.add(
              MetroService(
                tipo: line,
                nome: 'Normal',
                descricao: 'Todas as paragens',
                stops: stops,
              ),
            );
            lineSchedule[sentido] = stops;
          }

          lineServices[sentido] = services;
        } catch (_) {
          // skip
        }
      }

      _stopsByLine[line] = stopSet.toList()..sort();
      _directionsByLine[line] = dirSet.toList();
      _schedule[line] = lineSchedule;
      _allServices[line] = lineServices;
    }

    _allStopsSorted = allStops.toList()..sort();
  }
}
