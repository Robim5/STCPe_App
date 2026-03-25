import 'dart:convert';

/// arrival alert by user confiiguration
class ArrivalAlert {
  final String id;
  final String type; // stcp or metro
  final String stopName; // not optional for both
  final String? lineNumber; // optional for both
  final String? direction; // optional for both
  final String startTime; // HH:mm
  final String endTime; // HH:mm

  const ArrivalAlert({
    required this.id,
    required this.type,
    required this.stopName,
    this.lineNumber,
    this.direction,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'stopName': stopName,
    'lineNumber': lineNumber,
    'direction': direction,
    'startTime': startTime,
    'endTime': endTime,
  };

  factory ArrivalAlert.fromJson(Map<String, dynamic> json) => ArrivalAlert(
    id: json['id'] as String,
    type: json['type'] as String,
    stopName: json['stopName'] as String,
    lineNumber: json['lineNumber'] as String?,
    direction: json['direction'] as String?,
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
  );

  static String encode(List<ArrivalAlert> alerts) =>
      json.encode(alerts.map((a) => a.toJson()).toList());

  static List<ArrivalAlert> decode(String source) =>
      (json.decode(source) as List)
          .map((e) => ArrivalAlert.fromJson(e as Map<String, dynamic>))
          .toList();

  String get displayLabel {
    final buf = StringBuffer(stopName);
    if (lineNumber != null && lineNumber!.isNotEmpty) {
      buf.write(' \u2022 $lineNumber');
    }
    return buf.toString();
  }

  String get timeRange => '$startTime - $endTime';
}
