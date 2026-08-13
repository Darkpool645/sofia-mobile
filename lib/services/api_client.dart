import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();

  static const _kToken = 'sofia_token';

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: _kToken);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) => _send(
    () async => http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    ),
  );

  Future<dynamic> post(String path, Map<String, dynamic> body) => _send(
    () async => http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    ),
  );

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 60));
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor.', 0);
    }

    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final rawMsg = decoded is Map ? decoded['message'] : null;
    final message = rawMsg is List
        ? rawMsg.join('\n')
        : (rawMsg?.toString() ?? 'Error ${res.statusCode}');

    throw ApiException(message, res.statusCode);
  }
}
