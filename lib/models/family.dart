class FamilyChild {
  final String id;
  final String name;
  final String groupName;

  FamilyChild({required this.id, required this.name, required this.groupName});

  factory FamilyChild.fromJson(Map<String, dynamic> json) => FamilyChild(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        groupName: (json['group']?['name'])?.toString() ?? 'Sin grupo',
      );
}

class FeedItem {
  final String id;
  final String title;
  final String? description;
  final String type; // TAREA | ACTIVIDAD | EXAMEN
  final String dueDate; // ISO
  final String createdAt; // ISO
  final String teacherName;

  FeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.dueDate,
    required this.createdAt,
    required this.teacherName,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        type: json['type']?.toString() ?? 'TAREA',
        dueDate: json['dueDate']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        teacherName: (json['createdBy']?['name'])?.toString() ?? 'Docente',
      );
}