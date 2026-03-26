import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../data/constants.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/eta_info.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  _CacheEntry(this.data) : timestamp = DateTime.now();
  bool get isValid =>
      DateTime.now().difference(timestamp).inMilliseconds < 5000;
}

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final _client = http.Client();
  static const _timeout = Duration(seconds: 10);

  // cache store keyed by endpoint string
  final _cache = <String, _CacheEntry<dynamic>>{};

  T? _getCache<T>(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isValid) return entry.data as T;
    return null;
  }

  void _setCache<T>(String key, T data) {
    _cache[key] = _CacheEntry<T>(data);
  }

  Future<List<BusLine>> fetchLinhas() async {
    const cacheKey = 'linhas';
    final cached = _getCache<List<BusLine>>(cacheKey);
    if (cached != null) return cached;

    try {
      final url = '$apiBaseUrl/api/linhas';
      dev.log('fetchLinhas request');
      final response =
          await _client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data;
        if (decoded is Map && decoded.containsKey('linhas')) {
          data = decoded['linhas'] as List<dynamic>;
        } else if (decoded is List) {
          data = decoded;
        } else {
          return [];
        }
        final result = data
            .map((e) => BusLine.fromJson(e as Map<String, dynamic>))
            .toList();
        _setCache(cacheKey, result);
        return result;
      }
    } catch (e) {
      dev.log('fetchLinhas error: $e');
    }
    return [];
  }

  Future<Map<String, List<BusStop>>> fetchParagens(String linha) async {
    final cacheKey = 'paragens_$linha';
    final cached = _getCache<Map<String, List<BusStop>>>(cacheKey);
    if (cached != null) return cached;

    try {
      final url = '$apiBaseUrl/api/linhas/$linha/paragens';
      dev.log('fetchParagens linha=$linha');
      final response = await _client
          .get(Uri.parse(url))
          .timeout(_timeout);
      dev.log('fetchParagens status=${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        Map<String, dynamic> linhaData;

        if (decoded is Map<String, dynamic>) {
          // {"linha":"200","paragens":{"ida":[...],"volta":[...]}}
          if (decoded.containsKey('paragens') &&
              decoded['paragens'] is Map<String, dynamic>) {
            linhaData = decoded['paragens'] as Map<String, dynamic>;
          } else if (decoded.containsKey('ida') ||
              decoded.containsKey('volta')) {
            linhaData = decoded;
          } else {
            final inner = decoded[linha] ?? decoded.values.first;
            if (inner is Map<String, dynamic>) {
              linhaData = inner;
            } else {
              linhaData = {};
            }
          }
        } else {
          linhaData = {};
        }

        final idaList = (linhaData['ida'] as List<dynamic>? ?? [])
            .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList();
        final voltaList = (linhaData['volta'] as List<dynamic>? ?? [])
            .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList();
        final result = {'ida': idaList, 'volta': voltaList};
        dev.log('fetchParagens ida=${idaList.length} volta=${voltaList.length}');
        _setCache(cacheKey, result);
        return result;
      }
    } catch (e) {
      dev.log('fetchParagens error: $e');
    }
    return {'ida': [], 'volta': []};
  }

  Future<List<EtaInfo>> fetchETA(
      String linha, String codigoParagem, String sentido) async {
    final cacheKey = 'eta_${linha}_${codigoParagem}_$sentido';
    final cached = _getCache<List<EtaInfo>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client
          .get(Uri.parse(
              '$apiBaseUrl/api/tempo/$linha/$codigoParagem?sentido=$sentido'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<EtaInfo> result;
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('estimativas')) {
          final estimativas = decoded['estimativas'] as List<dynamic>;
          result = estimativas
              .map((e) => EtaInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (decoded is List) {
          result = decoded
              .map((e) => EtaInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          return [];
        }
        _setCache(cacheKey, result);
        return result;
      }
    } catch (e) {
      dev.log('fetchETA error: $e');
    }
    return [];
  }

  Future<List<BusStop>> searchParagens(String query) async {
    if (query.trim().isEmpty) return [];
    final cacheKey = 'search_${query.trim().toLowerCase()}';
    final cached = _getCache<List<BusStop>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client
          .get(Uri.parse(
              '$apiBaseUrl/api/paragens/pesquisa?nome=${Uri.encodeComponent(query)}'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data
            .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList();
        _setCache(cacheKey, result);
        return result;
      }
    } catch (e) {
      dev.log('searchParagens error: $e');
    }
    return [];
  }

  Future<List<EtaInfo>> fetchParagemTempos(String codigo) async {
    final cacheKey = 'paragem_tempos_$codigo';
    final cached = _getCache<List<EtaInfo>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _client
          .get(Uri.parse('$apiBaseUrl/api/paragem/$codigo/tempos'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final result = decoded
              .map((e) => EtaInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _setCache(cacheKey, result);
          return result;
        }
      }
    } catch (e) {
      dev.log('fetchParagemTempos error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchAutocarrosPosicao(String linha,
      {String? sentido}) async {
    final cacheKey = 'posicao_${linha}_${sentido ?? 'all'}';
    final cached = _getCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      var url = '$apiBaseUrl/api/autocarro/$linha/posicao';
      if (sentido != null) url += '?sentido=$sentido';
      final response =
          await _client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        _setCache(cacheKey, result);
        return result;
      }
    } catch (e) {
      dev.log('fetchAutocarrosPosicao error: $e');
    }
    return null;
  }
}
