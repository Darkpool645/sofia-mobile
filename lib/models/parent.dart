class ParentChild {
  final String id;
  final String name;
  final String groupName;

  ParentChild({
    required this.id,
    required this.name,
    required this.groupName,
  });

  factory ParentChild.fromJson(Map<String, dynamic> json) => ParentChild(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    groupName: (json['group']?['name'])?.toString() ?? 'Sin grupo',
  );
}

class Parent {
  final String id;
  final String name;
  final String username;
  final List<ParentChild> children;

  Parent({
    required this.id,
    required this.name,
    required this.username,
    required this.children,
  });

  factory Parent.fromJson(Map<String, dynamic> json) => Parent(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    children: ((json['children'] as List?) ?? [])
      .map((e) => ParentChild.fromJson(e as Map<String, dynamic>))
      .toList(),
  );
}