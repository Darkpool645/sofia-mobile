import 'api_client.dart';
import '../models/task.dart';
import '../models/submission.dart';

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

  Future<List<TeacherTask>> getMyTasks() async {
    final data = await _api.get('/tasks/mine') as List;
    return data
        .map((e) => TeacherTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubmissionRoster> getSubmissions(String taskId) async {
    final data =
        await _api.get('/tasks/$taskId/submissions') as Map<String, dynamic>;
    return SubmissionRoster.fromJson(data);
  }

  Future<void> saveSubmissions(
    String taskId,
    List<SubmissionStudent> students,
  ) async {
    final records = students
        .map(
          (s) => {
            'studentId': s.id,
            'delivered': s.delivered,
            if (s.gradeValue != null) 'grade': s.gradeValue,
          },
        )
        .toList();
    await _api.post('/tasks/$taskId/submissions', {'records': records});
  }

  Future<void> updateTask({
    required String id,
    required String title,
    String? description,
    required String dueDate, // "YYYY-MM-DD"
  }) async {
    await _api.patch('/tasks/$id', {
      'title': title,
      'description': description,
      'dueDate': dueDate,
    });
  }
}
