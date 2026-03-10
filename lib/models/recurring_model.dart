class RecurringSettings {
  final int? id;
  final String frequency; // 'daily', 'weekly', 'biweekly', 'monthly'
  final int? dayOfWeek; // 0-6
  final int? dayOfMonth; // 1-31
  final String? timeOfDay; // "HH:mm"
  final DateTime? endDate;
  final bool isActive;

  RecurringSettings({
    this.id,
    required this.frequency,
    this.dayOfWeek,
    this.dayOfMonth,
    this.timeOfDay,
    this.endDate,
    this.isActive = true,
  });

  factory RecurringSettings.fromJson(Map<String, dynamic> json) {
    return RecurringSettings(
      id: json['id'],
      frequency: json['frequency'],
      dayOfWeek: json['dayOfWeek'],
      dayOfMonth: json['dayOfMonth'],
      timeOfDay: json['timeOfDay'],
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate']).toLocal()
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'timeOfDay': timeOfDay,
      'endDate': endDate?.toUtc().toIso8601String(),
      'isActive': isActive,
    };
  }
}
