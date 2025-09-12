enum ItemType {
  goal,
  project,
  task,
  note,
  area,
  resource,
}

enum ItemStatus {
  inbox,
  clarified,
  active,
  completed,
  archived,
  someday,
  waiting,
}

enum Context {
  home,
  office,
  computer,
  errands,
  calls,
  anywhere,
}

enum EnergyLevel {
  high,
  medium,
  low,
}

enum ClarificationType {
  schedule,
  nextAction,
  waitingFor,
  someday,
  reference,
  project,
}

class Item {
  final String id;
  final ItemType type;
  final String title;
  final String? content;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  final int? estimatedDuration; // 분 단위
  final int? actualDuration; // 분 단위
  final int priority; // 1-5
  final EnergyLevel? energyLevel;
  final Context? context;
  final String? delegatedTo;
  final String? waitingFor;
  final DateTime? completionDate;

  Item({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.reminderDate,
    this.estimatedDuration,
    this.actualDuration,
    this.priority = 3,
    this.energyLevel,
    this.context,
    this.delegatedTo,
    this.waitingFor,
    this.completionDate,
  });

  Item copyWith({
    String? id,
    ItemType? type,
    String? title,
    String? content,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? reminderDate,
    int? estimatedDuration,
    int? actualDuration,
    int? priority,
    EnergyLevel? energyLevel,
    Context? context,
    String? delegatedTo,
    String? waitingFor,
    DateTime? completionDate,
  }) {
    return Item(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      priority: priority ?? this.priority,
      energyLevel: energyLevel ?? this.energyLevel,
      context: context ?? this.context,
      delegatedTo: delegatedTo ?? this.delegatedTo,
      waitingFor: waitingFor ?? this.waitingFor,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'estimated_duration': estimatedDuration,
      'actual_duration': actualDuration,
      'priority': priority,
      'energy_level': energyLevel?.name,
      'context': context?.name,
      'delegated_to': delegatedTo,
      'waiting_for': waitingFor,
      'completion_date': completionDate?.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      type: ItemType.values.firstWhere((e) => e.name == map['type']),
      title: map['title'],
      content: map['content'],
      status: ItemStatus.values.firstWhere((e) => e.name == map['status']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      reminderDate: map['reminder_date'] != null ? DateTime.parse(map['reminder_date']) : null,
      estimatedDuration: map['estimated_duration'],
      actualDuration: map['actual_duration'],
      priority: map['priority'] ?? 3,
      energyLevel: map['energy_level'] != null 
          ? EnergyLevel.values.firstWhere((e) => e.name == map['energy_level'])
          : null,
      context: map['context'] != null 
          ? Context.values.firstWhere((e) => e.name == map['context'])
          : null,
      delegatedTo: map['delegated_to'],
      waitingFor: map['waiting_for'],
      completionDate: map['completion_date'] != null 
          ? DateTime.parse(map['completion_date'])
          : null,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == ItemStatus.completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  String get formattedDuration {
    if (estimatedDuration == null) return '시간 미정';
    final hours = estimatedDuration! ~/ 60;
    final minutes = estimatedDuration! % 60;
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }
    return '${minutes}분';
  }
}



