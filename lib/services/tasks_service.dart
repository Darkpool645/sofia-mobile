import 'api_client.dart';

class TasksService {
  final _api = ApiClient();

  Future<void> createTask({
    required String title,
    String? description,
    required String type, // TAREA | ACTIVIDAD | EXAMEN
    required String dueDate, // "YYYY-MM-DD"
    required List<String> groupIds,
  }) async {
    await _api.post('/tasks', {
      'title': title,
      'description': description,
      'type': type,
      'dueDate': dueDate,
      'groupIds': groupIds,
    });
  }
}