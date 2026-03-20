class BusStop {
  final String codigo;
  final String nome;
  final double lat;
  final double lon;

  const BusStop({
    required this.codigo,
    required this.nome,
    required this.lat,
    required this.lon,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}
