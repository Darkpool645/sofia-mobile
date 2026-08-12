import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class AuthApi {

  /// POST /api/auth/login -> { accessToken, user: { id, email, name, role } }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json' },
        body: jsonEncode({ 'email': email, 'password': password }),
      )
      .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor', 0);
    }

    final Map<String, dynamic> body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : {};

    if (res.statusCode == 200) return body;

    final rawMessage = body['message'];
    final message = rawMessage is List ? rawMessage.join('\n') : (rawMessage?.toString() ?? 'Error de autenticación');

    throw ApiException(message, res.statusCode);
  }
}