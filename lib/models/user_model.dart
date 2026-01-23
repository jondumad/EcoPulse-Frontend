class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int totalPoints;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.totalPoints = 0,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      totalPoints: json['totalPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'totalPoints': totalPoints,
    };
  }
}
