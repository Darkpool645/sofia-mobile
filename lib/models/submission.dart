class SubmissionStudent {
  final String id;
  final String name;
  bool delivered;
  String gradeText; // editable en la UI

  SubmissionStudent({
    required this.id,
    required this.name,
    required this.delivered,
    required this.gradeText,
  });

  // Convierte el texto a número (acepta coma o punto). null si está vacío.
  double? get gradeValue {
    final t = gradeText.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  factory SubmissionStudent.fromJson(Map<String, dynamic> json) {
    final g = json['grade'];
    return SubmissionStudent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      delivered: json['delivered'] == true,
      gradeText: g == null ? '' : g.toString(),
    );
  }
}

class SubmissionRoster {
  final String taskId;
  final String title;
  final String type;
  final String group;
  final List<SubmissionStudent> students;

  SubmissionRoster({
    required this.taskId,
    required this.title,
    required this.type,
    required this.group,
    required this.students,
  });

  factory SubmissionRoster.fromJson(Map<String, dynamic> json) => SubmissionRoster(
        taskId: json['taskId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        type: json['type']?.toString() ?? 'TAREA',
        group: json['group']?.toString() ?? '',
        students: ((json['students'] as List?) ?? [])
            .map((e) => SubmissionStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}