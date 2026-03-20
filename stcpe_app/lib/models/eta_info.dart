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
    return EtaInfo(
      linha: (json['linha'] ?? json['line'] ?? '').toString(),
      destino: (json['destino'] ?? json['destination'] ?? '').toString(),
      minutos: (json['minutos'] ?? json['eta_min'] ?? json['tempo'] ?? 0) as int,
      matricula: json['matricula'] as String?,
    );
  }
}
