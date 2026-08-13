class Group {
  final String id;
  final String name;
  final String schoolYearName;
  final int studentCount;

  Group({
    required this.id,
    required this.name,
    required this.schoolYearName,
    required this.studentCount,
  });

  factory Group.formJson(Map<String, dynamic> json) => Group(
    id: json['id'] as String,
    name: json['name'] as String,
    schoolYearName: (json['schooYear']?['name'] as String),
    studentCount: (json['_count']?['students'] as int?) ?? 0
  );
}