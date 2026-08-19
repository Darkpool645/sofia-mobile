import 'api_client.dart';
import '../models/parent.dart';

class ParentsService {
  final _api = ApiClient();

  Future<List<Parent>> getParents() async {
    final data = await _api.get('/parents') as List;
    return data.map((e) => Parent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createParent({
    required String name,
    required String username,
    required String password,
    required List<Map<String, dynamic>> children,
  }) async {
    await _api.post('/parents', {
      'name': name,
      'username': username,
      'password': password,
      'children': children
    });
  }
}