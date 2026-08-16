int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class ClassGroup {
  final String id;
  final String name;
  final int studentCount;

  ClassGroup({required this.id, required this.name, required this.studentCount});

  factory ClassGroup.fromJson(Map<String, dynamic> json) => ClassGroup(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        studentCount: _asInt(json['_count']?['students']),
      );
}

class ClassSlot {
  final String id;
  final String subject;
  final int dayOfWeek; // 1 = lunes ... 7 = domingo
  final String startTime; // "09:00"
  final String endTime; // "09:50"
  final ClassGroup group;

  ClassSlot({
    required this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.group,
  });

  factory ClassSlot.fromJson(Map<String, dynamic> json) => ClassSlot(
        id: json['id']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        dayOfWeek: _asInt(json['dayOfWeek']),
        startTime: json['startTime']?.toString() ?? '',
        endTime: json['endTime']?.toString() ?? '',
        group: ClassGroup.fromJson(json['group'] as Map<String, dynamic>),
      );
}