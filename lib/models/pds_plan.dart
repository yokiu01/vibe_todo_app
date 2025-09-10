class PDSPlan {
  final String id;
  final DateTime date;
  final Map<String, String>? freeformPlans; // {"03:00": "계획 내용", "04:00": "..."}
  final Map<String, String>? actualActivities; // {"03:00": "실제 한 일", "04:00": "..."}
  final String? seeNotes; // 하루 회고 메모
  final DateTime createdAt;
  final DateTime updatedAt;

  PDSPlan({
    required this.id,
    required this.date,
    this.freeformPlans,
    this.actualActivities,
    this.seeNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  PDSPlan copyWith({
    String? id,
    DateTime? date,
    Map<String, String>? freeformPlans,
    Map<String, String>? actualActivities,
    String? seeNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PDSPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      freeformPlans: freeformPlans ?? this.freeformPlans,
      actualActivities: actualActivities ?? this.actualActivities,
      seeNotes: seeNotes ?? this.seeNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'freeform_plans': freeformPlans != null ? _mapToJson(freeformPlans!) : null,
      'actual_activities': actualActivities != null ? _mapToJson(actualActivities!) : null,
      'see_notes': seeNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PDSPlan.fromMap(Map<String, dynamic> map) {
    return PDSPlan(
      id: map['id'],
      date: DateTime.parse(map['date']),
      freeformPlans: map['freeform_plans'] != null ? _jsonToMap(map['freeform_plans']) : null,
      actualActivities: map['actual_activities'] != null ? _jsonToMap(map['actual_activities']) : null,
      seeNotes: map['see_notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static String _mapToJson(Map<String, String> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  static Map<String, String> _jsonToMap(String json) {
    if (json.isEmpty) return {};
    final Map<String, String> result = {};
    final entries = json.split('|');
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length >= 2) {
        result[parts[0]] = parts.sublist(1).join(':');
      }
    }
    return result;
  }

  // 3AM부터 시작하는 24시간 시간 슬롯 생성
  static List<TimeSlot> generateTimeSlots() {
    final slots = <TimeSlot>[];
    for (int i = 0; i < 24; i++) {
      final hour = (3 + i) % 24;
      final displayHour = hour == 0 ? 24 : hour;
      final ampm = hour < 12 ? 'AM' : 'PM';
      final displayHour12 = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
      
      slots.add(TimeSlot(
        hour24: hour,
        display: '${displayHour.toString().padLeft(2, '0')}:00',
        display12: '${displayHour12}:00 $ampm',
        key: '${hour.toString().padLeft(2, '0')}:00',
      ));
    }
    return slots;
  }

  // 특정 시간 슬롯의 계획 내용 가져오기
  String? getFreeformPlan(String timeKey) {
    return freeformPlans?[timeKey];
  }

  // 특정 시간 슬롯의 실제 활동 내용 가져오기
  String? getActualActivity(String timeKey) {
    return actualActivities?[timeKey];
  }

  // 계획된 내용이 있는 시간 슬롯 수
  int get plannedSlotsCount {
    return freeformPlans?.values.where((v) => v.isNotEmpty).length ?? 0;
  }

  // 실제 활동이 있는 시간 슬롯 수
  int get actualSlotsCount {
    return actualActivities?.values.where((v) => v.isNotEmpty).length ?? 0;
  }

  // 계획 대비 실행률 (0.0 ~ 1.0)
  double get executionRate {
    if (plannedSlotsCount == 0) return 0.0;
    return actualSlotsCount / plannedSlotsCount;
  }
}

class TimeSlot {
  final int hour24;
  final String display;
  final String display12;
  final String key;

  TimeSlot({
    required this.hour24,
    required this.display,
    required this.display12,
    required this.key,
  });
}

