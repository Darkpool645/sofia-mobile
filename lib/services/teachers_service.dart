import 'api_client.dart';
import '../models/teacher.dart';

class TeachersService {
  final _api = ApiClient();

  Future<List<Teacher>> getTeachers() async {
    final data = await _api.get('/teachers') as List;
    return data
        .map((e) => Teacher.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Teacher> getTeacher(String id) async {
    final data = await _api.get('/teachers/$id') as Map<String, dynamic>;
    return Teacher.fromJson(data);
  }

  /// assignments: cada elemento es
  /// { groupId, subject, dayOfWeek, startTime, endTime }
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
      'assignments': assignments,
    });
  }

  /// assignments: las existentes llevan 'id'; las nuevas no.
  /// password: opcional (solo si se quiere cambiar).
  Future<void> updateTeacher({
    required String id,
    required String name,
    required String email,
    String? password,
    required List<Map<String, dynamic>> assignments,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'assignments': assignments,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    await _api.patch('/teachers/$id', body);
  }
}