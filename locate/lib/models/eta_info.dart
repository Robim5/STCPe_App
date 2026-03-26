class EtaInfo {
  final String linha;
  final String destino;
  final int minutos;
  final String? matricula;

  const EtaInfo({
    required this.linha,
    required this.destino,
    required this.minutos,
    this.matricula,
  });

  factory EtaInfo.fromJson(Map<String, dynamic> json) {
    // tempo_estimado_min comes as double (e.g. 7.0)
    final rawMin = json['tempo_estimado_min'] ??
        json['minutos'] ??
        json['eta_min'] ??
        json['tempo'] ??
        0;
    return EtaInfo(
      linha: (json['linha'] ?? json['line'] ?? '').toString(),
      destino: (json['destino'] ?? json['destination'] ?? '').toString(),
      minutos: (rawMin is double) ? rawMin.round() : (rawMin as int),
      matricula: (json['veiculo_id'] ?? json['matricula'])?.toString(),
    );
  }
}
