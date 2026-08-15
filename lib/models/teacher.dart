int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class TeacherClass {
  final String subject;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String groupName;

  TeacherClass({
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.groupName,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) => TeacherClass(
    subject: json['subject']?.toString() ?? '',
    dayOfWeek: _asInt(json['dayOfWeek']),
    startTime: json['startTime']?.toString() ?? '',
    endTime: json['endTime']?.toString() ?? '',
    groupName: (json['group']?['name'])?.toString() ?? '',
  );
}

class Teacher {
  final String id;
  final String name;
  final String email;
  final List<TeacherClass> classes;

  Teacher({ 
    required this.id,
    required this.name,
    required this.email,
    required this.classes,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    classes: ((json['classes'] as List)).map((e) => TeacherClass.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

const dayNames = {
  1: 'Lunes',
  2: 'Martes',
  3: 'Miércoles',
  4: 'Jueves',
  5: 'Viernes',
  6: 'Sábado',
  7: 'Domingo'
};