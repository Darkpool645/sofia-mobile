import 'api_client.dart';

class RosterStudent {
  final String id;
  final String name;
  String? status; // PRESENTE | AUSENTE | RETARDO | null

  RosterStudent({required this.id, required this.name, this.status});

  factory RosterStudent.fromJson(Map<String, dynamic> json) => RosterStudent(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        status: json['status']?.toString(),
      );
}

class Roster {
  final String classId;
  final String subject;
  final String group;
  final List<RosterStudent> students;

  Roster({
    required this.classId,
    required this.subject,
    required this.group,
    required this.students,
  });

  factory Roster.fromJson(Map<String, dynamic> json) => Roster(
        classId: json['classId']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        students: ((json['students'] as List?) ?? [])
            .map((e) => RosterStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AttendanceService {
  final _api = ApiClient();

  Future<Roster> getRoster(String classId) async {
    final data =
        await _api.get('/attendance/roster?classId=$classId') as Map<String, dynamic>;
    return Roster.fromJson(data);
  }

  Future<void> save(String classId, List<RosterStudent> students) async {
    final records = students
        .where((s) => s.status != null)
        .map((s) => {'studentId': s.id, 'status': s.status})
        .toList();
    await _api.post('/attendance', {'classId': classId, 'records': records});
  }
}