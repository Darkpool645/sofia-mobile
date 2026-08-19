class User{
  final String id;
  final String username;
  final String name;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.role
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    username: json['username'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'role': role
  };
}