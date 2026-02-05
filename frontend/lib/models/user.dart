// Qaabdhismeedka macluumaadka qofka (User data model)
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  // Habka looga dhigo xogta mid la fahmi karo (Factory method to create User from JSON)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      role: (json['role'] ?? 'user').toString().toLowerCase(),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
    };
  }
}
