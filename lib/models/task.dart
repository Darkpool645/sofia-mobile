int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class TeacherTask {
  final String id;
  final String title;
  final String type; // TAREA | ACTIVIDAD | EXAMEN
  final String dueDate; // ISO
  final String groupName;
  final int submissionCount;

  TeacherTask({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    required this.groupName,
    required this.submissionCount,
  });

  factory TeacherTask.fromJson(Map<String, dynamic> json) => TeacherTask(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        type: json['type']?.toString() ?? 'TAREA',
        dueDate: json['dueDate']?.toString() ?? '',
        groupName: (json['group']?['name'])?.toString() ?? '',
        submissionCount: _asInt(json['_count']?['submissions']),
      );
}