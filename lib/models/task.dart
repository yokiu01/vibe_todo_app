class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final TaskCategory category;
  final TaskStatus status;
  final String? colorTag;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFromExternal; // 노션/구글캘린더에서 가져온 일정인지
  final String? externalId; // 외부 서비스의 ID
  final int? score; // 별점 (1-5)
  final String? doRecord; // 한일 기록

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.status = TaskStatus.planned,
    this.colorTag,
    required this.createdAt,
    required this.updatedAt,
    this.isFromExternal = false,
    this.externalId,
    this.score,
    this.doRecord,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    TaskCategory? category,
    TaskStatus? status,
    String? colorTag,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFromExternal,
    String? externalId,
    int? score,
    String? doRecord,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      status: status ?? this.status,
      colorTag: colorTag ?? this.colorTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFromExternal: isFromExternal ?? this.isFromExternal,
      externalId: externalId ?? this.externalId,
      score: score ?? this.score,
      doRecord: doRecord ?? this.doRecord,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'category': category.name,
      'status': status.name,
      'colorTag': colorTag,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFromExternal': isFromExternal,
      'externalId': externalId,
      'score': score,
      'doRecord': doRecord,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.work,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.planned,
      ),
      colorTag: json['colorTag'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isFromExternal: json['isFromExternal'] ?? false,
      externalId: json['externalId'],
      score: json['score'],
      doRecord: json['doRecord'],
    );
  }
}

enum TaskCategory {
  sleep('수면', '#4A90E2'),
  rest('휴식', '#7ED321'),
  work('업무', '#F5A623'),
  study('학습', '#9013FE'),
  exercise('운동', '#50E3C2'),
  personal('개인', '#B8E986'),
  other('기타', '#D0021B');

  const TaskCategory(this.displayName, this.color);
  final String displayName;
  final String color;
}

enum TaskStatus {
  planned('계획됨'),
  inProgress('진행중'),
  completed('완료'),
  cancelled('취소됨');

  const TaskStatus(this.displayName);
  final String displayName;
}

