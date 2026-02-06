class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int totalPoints;
  final String? token;
  final List<UserBadge> userBadges;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.totalPoints = 0,
    this.token,
    this.userBadges = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] is Map
          ? json['role']['name']
          : (json['role'] ?? 'Volunteer'),
      totalPoints: json['totalPoints'] ?? 0,
      userBadges:
          (json['userBadges'] as List?)
              ?.map((b) => UserBadge.fromJson(b))
              .toList() ??
          [],
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

class UserBadge {
  final int id;
  final int badgeId;
  final DateTime dateEarned;
  final BadgeInfo badge;

  UserBadge({
    required this.id,
    required this.badgeId,
    required this.dateEarned,
    required this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'],
      badgeId: json['badgeId'],
      dateEarned: DateTime.parse(json['dateEarned']),
      badge: BadgeInfo.fromJson(json['badge']),
    );
  }
}

class BadgeInfo {
  final int id;
  final String name;
  final String description;
  final String? iconUrl;
  final int pointsRequired;
  final String? category;

  BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.pointsRequired,
    this.category,
  });

  factory BadgeInfo.fromJson(Map<String, dynamic> json) {
    return BadgeInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['iconUrl'],
      pointsRequired: json['pointsRequired'] ?? 0,
      category: json['category'],
    );
  }
}
