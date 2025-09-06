class DailyPlan {
  final String id;
  final DateTime date;
  final List<String>? planMorning; // JSON array of task IDs
  final List<String>? planAfternoon;
  final List<String>? planEvening;
  final List<String>? actualItems; // JSON array of completed items
  final String? seeNotes; // 일일 회고 메모
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyPlan({
    required this.id,
    required this.date,
    this.planMorning,
    this.planAfternoon,
    this.planEvening,
    this.actualItems,
    this.seeNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyPlan copyWith({
    String? id,
    DateTime? date,
    List<String>? planMorning,
    List<String>? planAfternoon,
    List<String>? planEvening,
    List<String>? actualItems,
    String? seeNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      planMorning: planMorning ?? this.planMorning,
      planAfternoon: planAfternoon ?? this.planAfternoon,
      planEvening: planEvening ?? this.planEvening,
      actualItems: actualItems ?? this.actualItems,
      seeNotes: seeNotes ?? this.seeNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'plan_morning': planMorning != null ? _listToJson(planMorning!) : null,
      'plan_afternoon': planAfternoon != null ? _listToJson(planAfternoon!) : null,
      'plan_evening': planEvening != null ? _listToJson(planEvening!) : null,
      'actual_items': actualItems != null ? _listToJson(actualItems!) : null,
      'see_notes': seeNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    return DailyPlan(
      id: map['id'],
      date: DateTime.parse(map['date']),
      planMorning: map['plan_morning'] != null ? _jsonToList(map['plan_morning']) : null,
      planAfternoon: map['plan_afternoon'] != null ? _jsonToList(map['plan_afternoon']) : null,
      planEvening: map['plan_evening'] != null ? _jsonToList(map['plan_evening']) : null,
      actualItems: map['actual_items'] != null ? _jsonToList(map['actual_items']) : null,
      seeNotes: map['see_notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static String _listToJson(List<String> list) {
    return list.join(',');
  }

  static List<String> _jsonToList(String json) {
    if (json.isEmpty) return [];
    return json.split(',');
  }

  int get totalPlannedItems {
    return (planMorning?.length ?? 0) + 
           (planAfternoon?.length ?? 0) + 
           (planEvening?.length ?? 0);
  }

  int get completedItems {
    return actualItems?.length ?? 0;
  }

  double get completionRate {
    if (totalPlannedItems == 0) return 0.0;
    return completedItems / totalPlannedItems;
  }
}
