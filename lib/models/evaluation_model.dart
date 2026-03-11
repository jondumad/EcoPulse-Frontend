class EvaluationCategory {
  final int id;
  final String name;
  final String? description;
  final int scale;
  final bool isActive;

  EvaluationCategory({
    required this.id,
    required this.name,
    this.description,
    required this.scale,
    required this.isActive,
  });

  factory EvaluationCategory.fromJson(Map<String, dynamic> json) {
    return EvaluationCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      scale: json['scale'] ?? 5,
      isActive: json['isActive'] ?? true,
    );
  }
}

class EvaluationItem {
  final int categoryId;
  final int score;
  final EvaluationCategory? category;

  EvaluationItem({
    required this.categoryId,
    required this.score,
    this.category,
  });

  factory EvaluationItem.fromJson(Map<String, dynamic> json) {
    return EvaluationItem(
      categoryId: json['categoryId'],
      score: json['score'],
      category: json['category'] != null 
          ? EvaluationCategory.fromJson(json['category']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'score': score,
    };
  }
}

class EvaluationSession {
  final int id;
  final int evaluatorId;
  final int evaluateeId;
  final int? missionId;
  final String? comments;
  final DateTime createdAt;
  final List<EvaluationItem> items;
  final String? evaluatorName;
  final String? missionTitle;

  EvaluationSession({
    required this.id,
    required this.evaluatorId,
    required this.evaluateeId,
    this.missionId,
    this.comments,
    required this.createdAt,
    required this.items,
    this.evaluatorName,
    this.missionTitle,
  });

  factory EvaluationSession.fromJson(Map<String, dynamic> json) {
    return EvaluationSession(
      id: json['id'],
      evaluatorId: json['evaluatorId'],
      evaluateeId: json['evaluateeId'],
      missionId: json['missionId'],
      comments: json['comments'],
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List)
          .map((item) => EvaluationItem.fromJson(item))
          .toList(),
      evaluatorName: json['evaluator']?['name'],
      missionTitle: json['mission']?['title'],
    );
  }
}

class VolunteerSummary {
  final int id;
  final String name;
  final String email;
  final int totalPoints;

  VolunteerSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.totalPoints,
  });

  factory VolunteerSummary.fromJson(Map<String, dynamic> json) {
    return VolunteerSummary(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      totalPoints: json['totalPoints'] ?? 0,
    );
  }
}
