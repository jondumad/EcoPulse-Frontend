class Mission {
  final int id;
  final String title;
  final String description;
  final String locationName;
  final String? locationGps;
  final DateTime startTime;
  final DateTime endTime;
  final int pointsValue;
  final int? maxVolunteers;
  final int currentVolunteers;
  final String priority; // 'Low', 'Normal', 'High', 'Critical'
  final bool isEmergency;
  final String? emergencyJustification;
  final bool isTemplate;
  final String status; // 'Open', 'InProgress', 'Completed', 'Cancelled'
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final List<Category> categories;
  final bool isRegistered; // Helper for UI state
  final String?
  registrationStatus; // 'Registered', 'CheckedIn', 'Completed', 'Cancelled'
  final DateTime? registeredAt;
  final String? creatorName;
  final int createdBy;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.locationName,
    this.locationGps,
    required this.startTime,
    required this.endTime,
    required this.pointsValue,
    this.maxVolunteers,
    required this.currentVolunteers,
    required this.priority,
    required this.isEmergency,
    this.emergencyJustification,
    this.isTemplate = false,
    required this.status,
    this.actualStartTime,
    this.actualEndTime,
    required this.categories,
    this.isRegistered = false,
    this.registrationStatus,
    this.registeredAt,
    this.creatorName,
    required this.createdBy,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    String? regStatus;
    DateTime? regAt;
    if (json['registrations'] != null &&
        (json['registrations'] as List).isNotEmpty) {
      regStatus = json['registrations'][0]['status'];
      final regDate = json['registrations'][0]['createdAt'];
      if (regDate != null) {
        regAt = DateTime.parse(regDate);
      }
    }

    return Mission(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      locationName: json['locationName'],
      locationGps: json['locationGps'],
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      pointsValue: json['pointsValue'],
      maxVolunteers: json['maxVolunteers'],
      currentVolunteers: json['currentVolunteers'] ?? 0,
      priority: json['priority'] ?? 'Normal',
      isEmergency: json['isEmergency'] ?? false,
      emergencyJustification: json['emergencyJustification'],
      isTemplate: json['isTemplate'] ?? false,
      status: json['status'] ?? 'Open',
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime']).toLocal()
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime']).toLocal()
          : null,
      categories:
          (json['missionCategories'] as List?)
              ?.map((mc) => Category.fromJson(mc['category']))
              .toList() ??
          [],
      isRegistered: regStatus != null && regStatus != 'Cancelled',
      registrationStatus: regStatus,
      registeredAt: regAt,
      creatorName: json['creator'] != null ? json['creator']['name'] : null,
      createdBy: json['createdBy'] ?? 0,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String color; // Hex string
  final String icon; // Emoji or icon name

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#3498DB',
      icon: json['icon'] ?? '🌱',
    );
  }
}
