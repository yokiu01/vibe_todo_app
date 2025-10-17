/// Routine model representing a recurring task template
class Routine {
  final String id;
  final String title;
  final List<String> frequency; // 반복 주기: 매일, 주중, 주말, 월, 화, 수, 목, 금, 토, 일
  final String? scheduledTime; // 루틴 수행 시간 (예: "08:00")
  final String status; // Active, Paused
  final DateTime? lastGenerated; // 마지막으로 할 일이 생성된 날짜
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? category;
  final int? estimatedMinutes;

  Routine({
    required this.id,
    required this.title,
    required this.frequency,
    this.scheduledTime,
    this.status = 'Active',
    this.lastGenerated,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.category,
    this.estimatedMinutes,
  });

  /// Create from JSON
  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      title: json['title'] as String,
      frequency: (json['frequency'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scheduledTime: json['scheduled_time'] as String?,
      status: json['status'] as String? ?? 'Active',
      lastGenerated: json['last_generated'] != null
          ? DateTime.parse(json['last_generated'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      category: json['category'] as String?,
      estimatedMinutes: json['estimated_minutes'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency,
      'scheduled_time': scheduledTime,
      'status': status,
      'last_generated': lastGenerated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'description': description,
      'category': category,
      'estimated_minutes': estimatedMinutes,
    };
  }

  /// Create from Notion API response
  factory Routine.fromNotion(Map<String, dynamic> notionPage) {
    try {
      final properties = notionPage['properties'] as Map<String, dynamic>;

      // Extract title
      String title = '';
      if (properties['이름'] != null) {
        final titleProp = properties['이름'];
        if (titleProp['title'] != null && titleProp['title'].isNotEmpty) {
          title = titleProp['title'][0]['plain_text'] ?? '';
        }
      }

      // Extract frequency (Multi-select)
      List<String> frequency = [];
      if (properties['반복 주기'] != null) {
        final freqProp = properties['반복 주기'];
        if (freqProp['multi_select'] != null) {
          frequency = (freqProp['multi_select'] as List<dynamic>)
              .map((item) => item['name'] as String)
              .toList();
        }
      }

      // Extract scheduled time
      String? scheduledTime;
      if (properties['루틴 수행 시간'] != null) {
        final timeProp = properties['루틴 수행 시간'];
        if (timeProp['rich_text'] != null && timeProp['rich_text'].isNotEmpty) {
          scheduledTime = timeProp['rich_text'][0]['plain_text'];
        }
      }

      // Extract status
      String status = 'Active';
      if (properties['루틴 활성화 상태'] != null) {
        final statusProp = properties['루틴 활성화 상태'];
        if (statusProp['select'] != null) {
          status = statusProp['select']['name'] ?? 'Active';
        }
      }

      // Extract last generated date
      DateTime? lastGenerated;
      if (properties['Last Generated Date'] != null) {
        final lastGenProp = properties['Last Generated Date'];
        if (lastGenProp['date'] != null && lastGenProp['date']['start'] != null) {
          lastGenerated = DateTime.parse(lastGenProp['date']['start']);
        }
      }

      // Extract description
      String? description;
      if (properties['Description'] != null) {
        final descProp = properties['Description'];
        if (descProp['rich_text'] != null && descProp['rich_text'].isNotEmpty) {
          description = descProp['rich_text'][0]['plain_text'];
        }
      }

      // Extract category
      String? category;
      if (properties['Category'] != null) {
        final catProp = properties['Category'];
        if (catProp['select'] != null) {
          category = catProp['select']['name'];
        }
      }

      // Extract estimated minutes
      int? estimatedMinutes;
      if (properties['Duration'] != null) {
        final minProp = properties['Duration'];
        if (minProp['number'] != null) {
          estimatedMinutes = minProp['number'] as int?;
        }
      }

      // Extract dates
      final createdTime = notionPage['created_time'] as String;
      final lastEditedTime = notionPage['last_edited_time'] as String;

      return Routine(
        id: notionPage['id'] as String,
        title: title,
        frequency: frequency,
        scheduledTime: scheduledTime,
        status: status,
        lastGenerated: lastGenerated,
        createdAt: DateTime.parse(createdTime),
        updatedAt: DateTime.parse(lastEditedTime),
        description: description,
        category: category,
        estimatedMinutes: estimatedMinutes,
      );
    } catch (e) {
      throw Exception('Failed to parse Routine from Notion: $e');
    }
  }

  /// Convert to Notion API format for creation/update
  Map<String, dynamic> toNotionProperties() {
    final properties = <String, dynamic>{
      '이름': {
        'title': [
          {
            'text': {'content': title}
          }
        ]
      },
      '반복 주기': {
        'multi_select': frequency.map((freq) => {'name': freq}).toList(),
      },
      '루틴 활성화 상태': {
        'select': {'name': status},
      },
    };

    if (scheduledTime != null) {
      properties['루틴 수행 시간'] = {
        'rich_text': [
          {
            'text': {'content': scheduledTime}
          }
        ]
      };
    }

    if (lastGenerated != null) {
      properties['Last Generated Date'] = {
        'date': {'start': lastGenerated!.toIso8601String().split('T')[0]}
      };
    }

    if (description != null) {
      properties['Description'] = {
        'rich_text': [
          {
            'text': {'content': description}
          }
        ]
      };
    }

    if (category != null) {
      properties['Category'] = {
        'select': {'name': category}
      };
    }

    if (estimatedMinutes != null) {
      properties['Duration'] = {
        'number': estimatedMinutes,
      };
    }

    return properties;
  }

  /// Check if this routine should run today
  bool shouldRunToday(DateTime date) {
    // If not active, don't run
    if (status != 'Active') return false;

    // If already generated today, don't run again
    if (lastGenerated != null) {
      final lastGenDate = DateTime(
        lastGenerated!.year,
        lastGenerated!.month,
        lastGenerated!.day,
      );
      final today = DateTime(date.year, date.month, date.day);
      if (lastGenDate.isAtSameMomentAs(today)) {
        return false;
      }
    }

    // Check frequency
    final weekday = _getWeekdayName(date.weekday);

    // Check if frequency matches today
    if (frequency.contains('매일')) return true;
    if (frequency.contains('주중') && date.weekday >= 1 && date.weekday <= 5) {
      return true;
    }
    if (frequency.contains('주말') && (date.weekday == 6 || date.weekday == 7)) {
      return true;
    }
    if (frequency.contains(weekday)) return true;

    return false;
  }

  /// Get Korean weekday name
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  /// Create a copy with updated fields
  Routine copyWith({
    String? id,
    String? title,
    List<String>? frequency,
    String? scheduledTime,
    String? status,
    DateTime? lastGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? category,
    int? estimatedMinutes,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  /// Get frequency display text
  String getFrequencyDisplayText() {
    if (frequency.isEmpty) return '설정 안됨';
    if (frequency.contains('매일')) return '매일';
    if (frequency.length == 1) return frequency.first;
    return frequency.join(', ');
  }

  @override
  String toString() {
    return 'Routine(id: $id, title: $title, frequency: $frequency, status: $status)';
  }
}
