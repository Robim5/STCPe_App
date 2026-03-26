import 'package:flutter/material.dart';

class BusLine {
  final String number;
  final Color color;
  final String origin;
  final String destination;
  final String municipality;
  final bool hasVolta;
  bool isFavorite;

  BusLine({
    required this.number,
    required this.color,
    required this.origin,
    required this.destination,
    required this.municipality,
    this.hasVolta = false,
    this.isFavorite = false,
  });

  List<String> get directions => [origin, destination];

  static const Map<String, Color> colorMap = {
    'azul': Color(0xFF052659),
    'amarelo': Color(0xFFF9A825),
    'verde': Color(0xFF2E7D32),
    'vermelho': Color(0xFFC62828),
    'roxo': Color(0xFF6A1B9A),
    'laranja': Color(0xFFE65100),
    'preto': Color(0xFF212121),
  };

  factory BusLine.fromJson(Map<String, dynamic> json) {
    final sentidos = json['sentidos'] as Map<String, dynamic>? ?? {};
    final ida = sentidos['ida'] as Map<String, dynamic>? ?? {};
    final volta = sentidos['volta'] as Map<String, dynamic>?;

    final corStr = (json['cor'] as String?)?.toLowerCase() ?? '';

    return BusLine(
      number: json['linha'] as String? ?? '',
      color: colorMap[corStr] ?? const Color(0xFF052659),
      origin: ida['origem'] as String? ?? '',
      destination: ida['destino'] as String? ?? '',
      municipality: json['municipio'] as String? ?? '',
      hasVolta: volta != null,
    );
  }

  String get routeLabel => '$origin \u2194 $destination';
  String get forwardLabel => '$origin \u2192 $destination';
  String get reverseLabel => '$destination \u2192 $origin';
}
