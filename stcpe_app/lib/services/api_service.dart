import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../data/constants.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/eta_info.dart';

class ApiService {
  // singleton instance
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final _client = http.Client(); // http client
  static const _timeout = Duration(seconds: 10); // request timeout

  Future<List<BusLine>> fetchLinhas() async {
    // fetch line list
    try {
      final url = '$apiBaseUrl/api/linhas';
      dev.log('fetchLinhas → $url (baseUrl="$apiBaseUrl")');
      final response = await _client
          .get(Uri.parse(url))
          .timeout(_timeout);
      dev.log('fetchLinhas status=${response.statusCode} body=${response.body.length} chars');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data;
        if (decoded is Map && decoded.containsKey('linhas')) {
          data = decoded['linhas'] as List<dynamic>;
        } else if (decoded is List) {
          data = decoded;
        } else {
          dev.log('fetchLinhas unexpected format: ${decoded.runtimeType}');
          return [];
        }
        return data
            .map((e) => BusLine.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      dev.log('fetchLinhas error: $e');
    }
    return [];
  }

  Future<Map<String, List<BusStop>>> fetchParagens(String linha) async {
    // get line stops
    try {
      final response = await _client
          .get(Uri.parse('$apiBaseUrl/api/linhas/$linha/paragens'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        // The JSON has the line number as root key: {"200": {"ida": [...], "volta": [...]}}
        final Map<String, dynamic> linhaData =
            body[linha] as Map<String, dynamic>? ?? body.values.first as Map<String, dynamic>;
        final idaList = (linhaData['ida'] as List<dynamic>? ?? [])
            .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList();
        final voltaList = (linhaData['volta'] as List<dynamic>? ?? [])
            .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList();

        return {'ida': idaList, 'volta': voltaList};
      }
    } catch (_) {}
    return {'ida': [], 'volta': []};
  }

  Future<List<EtaInfo>> fetchETA(
      String linha, String codigoParagem, String sentido) async {
    // get eta for stop
    try {
      final response = await _client
          .get(Uri.parse(
              '$apiBaseUrl/api/tempo/$linha/$codigoParagem?sentido=$sentido'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => EtaInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (decoded is Map<String, dynamic>) {
          return [EtaInfo.fromJson(decoded)];
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<BusStop>> searchParagens(String query) async {
    // search stops by name
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client
          .get(Uri.parse(
              '$apiBaseUrl/api/paragens/pesquisa?nome=${Uri.encodeComponent(query)}'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<EtaInfo>> fetchParagemTempos(String codigo) async {
    // get stop arrival times
    try {
      final response = await _client
          .get(Uri.parse('$apiBaseUrl/api/paragem/$codigo/tempos'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => EtaInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> fetchAutocarrosPosicao(String linha,
      {String? sentido}) async {
    // get bus position
    try {
      var url = '$apiBaseUrl/api/autocarro/$linha/posicao';
      if (sentido != null) url += '?sentido=$sentido';
      final response =
          await _client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
