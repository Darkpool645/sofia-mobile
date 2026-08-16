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
  final String date; // ISO
  final bool editable;
  final List<RosterStudent> students;

  Roster({
    required this.classId,
    required this.subject,
    required this.group,
    required this.date,
    required this.editable,
    required this.students,
  });

  factory Roster.fromJson(Map<String, dynamic> json) => Roster(
        classId: json['classId']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        editable: json['editable'] == true,
        students: ((json['students'] as List?) ?? [])
            .map((e) => RosterStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AttendanceService {
  final _api = ApiClient();

  // date: "YYYY-MM-DD" (opcional; el backend usa hoy si se omite)
  Future<Roster> getRoster(String classId, {String? date}) async {
    final q = date != null ? '&date=$date' : '';
    final data = await _api.get('/attendance/roster?classId=$classId$q')
        as Map<String, dynamic>;
    return Roster.fromJson(data);
  }

  Future<void> save(String classId, List<RosterStudent> students,
      {String? date}) async {
    final records = students
        .where((s) => s.status != null)
        .map((s) => {'studentId': s.id, 'status': s.status})
        .toList();
    final body = <String, dynamic>{'classId': classId, 'records': records};
    if (date != null) body['date'] = date;
    await _api.post('/attendance', body);
  }
}