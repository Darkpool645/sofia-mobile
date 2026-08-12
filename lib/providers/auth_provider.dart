import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _api = AuthApi();

  User? _user;
  String? _token;
  bool _loading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null && _user != null;

  static const _kToken = 'sofia_token';
  static const _kUser = 'sofia_user';

  Future<void> init() async {
    _token = await _storage.read(key: _kToken);
    final userJson = await _storage.read(key: _kUser);
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.login(email.trim(), password);
      _token = data['accessToken'] as String;
      _user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _storage.write(key: _kToken, value: _token);
      await _storage.write(key: _kUser, value: jsonEncode(_user!.toJson()));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}