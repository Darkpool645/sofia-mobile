class SchoolYear { 
  final String id;
  final String name;

  SchoolYear({ required this.id, required this.name });

  factory SchoolYear.fromJson(Map<String, dynamic> json) => SchoolYear(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}