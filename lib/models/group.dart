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

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        schoolYearName:
            (json['schoolYear']?['name'])?.toString() ?? 'Sin ciclo',
        // Conversión segura: no fuerza el cast, convierte cualquier num a int.
        studentCount: _asInt(json['_count']?['students']),
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}