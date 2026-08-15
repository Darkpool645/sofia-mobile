import 'api_client.dart';
import '../models/teacher.dart';

class TeachersService {
  final _api = ApiClient();

  Future<List<Teacher>> getTeachers() async {
    final data = await _api.get('/teachers') as List;
    return data.map((e) => Teacher.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createTeacher({
    required String name,
    required String email,
    required String password,
    required List<Map<String, dynamic>> assignments,
  }) async {
    await _api.post('/teachers', {
      'name': name,
      'email': email,
      'password': password,
      'assignments': assignments
    });
  }
}