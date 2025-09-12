enum ReviewType {
  daily,
  weekly,
  monthly,
}

class Review {
  final String id;
  final DateTime reviewDate;
  final ReviewType type;
  final bool emptyInboxCompleted;
  final bool clarifyCompleted;
  final bool mindSweepCompleted;
  final bool nextActionsReviewed;
  final bool projectsUpdated;
  final bool goalsChecked;
  final bool calendarPlanned;
  final bool somedayReviewed;
  final bool newGoalsAdded;
  final String? notes;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewDate,
    required this.type,
    this.emptyInboxCompleted = false,
    this.clarifyCompleted = false,
    this.mindSweepCompleted = false,
    this.nextActionsReviewed = false,
    this.projectsUpdated = false,
    this.goalsChecked = false,
    this.calendarPlanned = false,
    this.somedayReviewed = false,
    this.newGoalsAdded = false,
    this.notes,
    required this.createdAt,
  });

  Review copyWith({
    String? id,
    DateTime? reviewDate,
    ReviewType? type,
    bool? emptyInboxCompleted,
    bool? clarifyCompleted,
    bool? mindSweepCompleted,
    bool? nextActionsReviewed,
    bool? projectsUpdated,
    bool? goalsChecked,
    bool? calendarPlanned,
    bool? somedayReviewed,
    bool? newGoalsAdded,
    String? notes,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      reviewDate: reviewDate ?? this.reviewDate,
      type: type ?? this.type,
      emptyInboxCompleted: emptyInboxCompleted ?? this.emptyInboxCompleted,
      clarifyCompleted: clarifyCompleted ?? this.clarifyCompleted,
      mindSweepCompleted: mindSweepCompleted ?? this.mindSweepCompleted,
      nextActionsReviewed: nextActionsReviewed ?? this.nextActionsReviewed,
      projectsUpdated: projectsUpdated ?? this.projectsUpdated,
      goalsChecked: goalsChecked ?? this.goalsChecked,
      calendarPlanned: calendarPlanned ?? this.calendarPlanned,
      somedayReviewed: somedayReviewed ?? this.somedayReviewed,
      newGoalsAdded: newGoalsAdded ?? this.newGoalsAdded,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'review_date': reviewDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'type': type.name,
      'empty_inbox_completed': emptyInboxCompleted ? 1 : 0,
      'clarify_completed': clarifyCompleted ? 1 : 0,
      'mind_sweep_completed': mindSweepCompleted ? 1 : 0,
      'next_actions_reviewed': nextActionsReviewed ? 1 : 0,
      'projects_updated': projectsUpdated ? 1 : 0,
      'goals_checked': goalsChecked ? 1 : 0,
      'calendar_planned': calendarPlanned ? 1 : 0,
      'someday_reviewed': somedayReviewed ? 1 : 0,
      'new_goals_added': newGoalsAdded ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      reviewDate: DateTime.parse(map['review_date']),
      type: ReviewType.values.firstWhere((e) => e.name == map['type']),
      emptyInboxCompleted: map['empty_inbox_completed'] == 1,
      clarifyCompleted: map['clarify_completed'] == 1,
      mindSweepCompleted: map['mind_sweep_completed'] == 1,
      nextActionsReviewed: map['next_actions_reviewed'] == 1,
      projectsUpdated: map['projects_updated'] == 1,
      goalsChecked: map['goals_checked'] == 1,
      calendarPlanned: map['calendar_planned'] == 1,
      somedayReviewed: map['someday_reviewed'] == 1,
      newGoalsAdded: map['new_goals_added'] == 1,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  List<bool> get allSteps {
    return [
      emptyInboxCompleted,
      clarifyCompleted,
      mindSweepCompleted,
      nextActionsReviewed,
      projectsUpdated,
      goalsChecked,
      calendarPlanned,
      somedayReviewed,
      newGoalsAdded,
    ];
  }

  int get completedSteps {
    return allSteps.where((step) => step).length;
  }

  int get totalSteps {
    return allSteps.length;
  }

  double get completionRate {
    if (totalSteps == 0) return 0.0;
    return completedSteps / totalSteps;
  }

  int get completionPercentage {
    return (completionRate * 100).round();
  }
}



