class NotionTask {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? clarification;
  final String? status;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? delegatedTo;
  final String? waitingFor;
  final String? nextActionSituation;
  final String? project;

  NotionTask({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.clarification,
    this.status,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.delegatedTo,
    this.waitingFor,
    this.nextActionSituation,
    this.project,
  });
  
  /// Notion API 응답에서 NotionTask 생성
  factory NotionTask.fromNotion(Map<String, dynamic> notionData) {
    final properties = notionData['properties'] ?? {};
    
    // 제목 추출 개선 (safe parsing)
    String title = '';
    
    try {
      // '이름' 속성에서 제목 추출
      if (properties['이름'] != null) {
        final titleProperty = properties['이름'];
        if (titleProperty is Map && titleProperty['title'] != null && titleProperty['title'] is List && titleProperty['title'].isNotEmpty) {
          final titleArray = titleProperty['title'] as List;
          if (titleArray[0] is Map && titleArray[0]['text'] is Map) {
            title = titleArray[0]['text']['content']?.toString() ?? '';
          }
        }
      }
      
      // title이 비어있으면 다른 제목 속성들 시도
      if (title.isEmpty) {
        for (String key in ['Name', 'Title', 'title', '제목']) {
          if (properties[key] != null) {
            final prop = properties[key];
            if (prop is Map && prop['title'] != null && prop['title'] is List && prop['title'].isNotEmpty) {
              final titleArray = prop['title'] as List;
              if (titleArray[0] is Map && titleArray[0]['text'] is Map) {
                title = titleArray[0]['text']['content']?.toString() ?? '';
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('제목 추출 오류: $e');
    }
    
    // 제목이 여전히 비어있으면 기본값 설정
    if (title.isEmpty) {
      title = '제목 없음';
    }
    
    // 설명 추출 (safe parsing) - 여러 가능한 속성명 시도
    String? description;
    try {
      // description, content, 설명 등 여러 속성명 시도
      for (String key in ['description', 'content', '설명', '내용']) {
        if (properties[key] != null) {
          final descProperty = properties[key];
          if (descProperty is Map && descProperty['rich_text'] is List) {
            final richTextArray = descProperty['rich_text'] as List;
            if (richTextArray.isNotEmpty && richTextArray[0] is Map && richTextArray[0]['text'] is Map) {
              description = richTextArray[0]['text']['content']?.toString();
              if (description != null && description.isNotEmpty) break;
            }
          }
        }
      }
    } catch (e) {
      print('설명 추출 오류: $e');
    }
    
    // 기한 추출 (safe parsing)
    DateTime? dueDate;
    try {
      final dueDateProperty = properties['날짜'];
      if (dueDateProperty is Map && dueDateProperty['date'] is Map) {
        final dateObj = dueDateProperty['date'] as Map;
        if (dateObj['start'] != null) {
          dueDate = DateTime.parse(dateObj['start'].toString());
        }
      }
    } catch (e) {
      print('기한 추출 오류: $e');
    }
    
    // 명료화 추출 (safe parsing) - 여러 가능한 속성명 시도
    String? clarification;
    try {
      // 명료화, 분류 등 여러 속성명 시도
      for (String key in ['명료화', '분류']) {
        if (properties[key] != null) {
          final clarificationProperty = properties[key];
          if (clarificationProperty is Map && clarificationProperty['select'] is Map) {
            final selectObj = clarificationProperty['select'] as Map;
            clarification = selectObj['name']?.toString();
            if (clarification != null && clarification.isNotEmpty) break;
          }
        }
      }
    } catch (e) {
      print('명료화 추출 오류: $e');
    }
    
    // 상태 추출 (safe parsing) - 여러 가능한 속성명 시도
    String? status;
    try {
      // status, 상태, 명료화 등 여러 속성명 시도
      for (String key in ['status', '상태', '명료화']) {
        if (properties[key] != null) {
          final statusProperty = properties[key];
          if (statusProperty is Map) {
            // select 속성 시도
            if (statusProperty['select'] is Map) {
              final selectObj = statusProperty['select'] as Map;
              status = selectObj['name']?.toString();
              if (status != null && status.isNotEmpty) break;
            }
            // status 속성 시도 (Notion status 타입)
            if (statusProperty['status'] is Map) {
              final statusObj = statusProperty['status'] as Map;
              status = statusObj['name']?.toString();
              if (status != null && status.isNotEmpty) break;
            }
          }
        }
      }
    } catch (e) {
      print('상태 추출 오류: $e');
    }
    
    // 완료 여부 추출 (safe parsing)
    bool isCompleted = false;
    try {
      final completedProperty = properties['완료'];
      if (completedProperty is Map && completedProperty['checkbox'] is bool) {
        isCompleted = completedProperty['checkbox'] as bool;
      }
    } catch (e) {
      print('완료 여부 추출 오류: $e');
    }
    
    // 위임 대상 추출 (safe parsing)
    String? delegatedTo;
    try {
      final delegatedProperty = properties['delegated_to'];
      if (delegatedProperty is Map && delegatedProperty['rich_text'] is List) {
        final richTextArray = delegatedProperty['rich_text'] as List;
        if (richTextArray.isNotEmpty && richTextArray[0] is Map && richTextArray[0]['text'] is Map) {
          delegatedTo = richTextArray[0]['text']['content']?.toString();
        }
      }
    } catch (e) {
      print('위임 대상 추출 오류: $e');
    }
    
    // 대기 중인 것 추출 (safe parsing)
    String? waitingFor;
    try {
      final waitingProperty = properties['waiting_for'];
      if (waitingProperty is Map && waitingProperty['rich_text'] is List) {
        final richTextArray = waitingProperty['rich_text'] as List;
        if (richTextArray.isNotEmpty && richTextArray[0] is Map && richTextArray[0]['text'] is Map) {
          waitingFor = richTextArray[0]['text']['content']?.toString();
        }
      }
    } catch (e) {
      print('대기 중인 것 추출 오류: $e');
    }
    
    // 다음행동상황 추출 (safe parsing)
    String? nextActionSituation;
    try {
      final nextActionSituationProperty = properties['다음 행동 상황'];
      if (nextActionSituationProperty is Map && nextActionSituationProperty['multi_select'] is List) {
        final multiSelectArray = nextActionSituationProperty['multi_select'] as List;
        if (multiSelectArray.isNotEmpty && multiSelectArray[0] is Map) {
          nextActionSituation = multiSelectArray[0]['name']?.toString();
        }
      }
    } catch (e) {
      print('다음행동상황 추출 오류: $e');
    }

    // 프로젝트 추출 (relation 속성)
    String? project;
    try {
      for (String key in ['프로젝트', 'Project', 'project']) {
        if (properties[key] != null) {
          final projectProperty = properties[key];
          if (projectProperty is Map && projectProperty['relation'] is List) {
            final relationArray = projectProperty['relation'] as List;
            if (relationArray.isNotEmpty && relationArray[0] is Map) {
              final relationId = relationArray[0]['id']?.toString();
              if (relationId != null) {
                project = relationId;
              }
            }
          }
        }
      }
    } catch (e) {
      print('프로젝트 추출 오류: $e');
    }

    return NotionTask(
      id: notionData['id']?.toString() ?? '',
      title: title,
      description: description,
      dueDate: dueDate,
      clarification: clarification,
      status: status,
      isCompleted: isCompleted,
      createdAt: _safeParseDateTime(notionData['created_time']),
      updatedAt: _safeParseDateTime(notionData['last_edited_time']),
      delegatedTo: delegatedTo,
      waitingFor: waitingFor,
      nextActionSituation: nextActionSituation,
      project: project,
    );
  }
  
  /// 안전한 DateTime 파싱
  static DateTime _safeParseDateTime(dynamic dateTimeValue) {
    try {
      if (dateTimeValue != null) {
        return DateTime.parse(dateTimeValue.toString());
      }
    } catch (e) {
      print('DateTime 파싱 오류: $e');
    }
    return DateTime.now();
  }
  
  /// Notion API 요청용 Map으로 변환
  Map<String, dynamic> toNotion() {
    final properties = <String, dynamic>{
      '이름': {
        'title': [
          {
            'text': {
              'content': title,
            }
          }
        ]
      },
    };
    
    if (description != null && description!.isNotEmpty) {
      properties['description'] = {
        'rich_text': [
          {
            'text': {
              'content': description!,
            }
          }
        ]
      };
    }
    
    if (dueDate != null) {
      properties['날짜'] = {
        'date': {
          'start': dueDate!.toIso8601String().split('T')[0],
        }
      };
    }
    
    if (clarification != null && clarification!.isNotEmpty) {
      properties['명료화'] = {
        'select': {
          'name': clarification!,
        }
      };
    }
    
    if (status != null && status!.isNotEmpty) {
      properties['status'] = {
        'select': {
          'name': status!,
        }
      };
    }
    
    properties['완료'] = {
      'checkbox': isCompleted,
    };
    
    if (delegatedTo != null && delegatedTo!.isNotEmpty) {
      properties['delegated_to'] = {
        'rich_text': [
          {
            'text': {
              'content': delegatedTo!,
            }
          }
        ]
      };
    }
    
    if (waitingFor != null && waitingFor!.isNotEmpty) {
      properties['waiting_for'] = {
        'rich_text': [
          {
            'text': {
              'content': waitingFor!,
            }
          }
        ]
      };
    }
    
    if (nextActionSituation != null && nextActionSituation!.isNotEmpty) {
      properties['다음 행동 상황'] = {
        'multi_select': [
          {
            'name': nextActionSituation!,
          }
        ]
      };
    }
    
    return properties;
  }
  
  /// 로컬 데이터베이스용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'clarification': clarification,
      'status': status,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'delegated_to': delegatedTo,
      'waiting_for': waitingFor,
      'next_action_situation': nextActionSituation,
      'project': project,
    };
  }

  /// 로컬 데이터베이스에서 NotionTask 생성
  factory NotionTask.fromMap(Map<String, dynamic> map) {
    return NotionTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      clarification: map['clarification'],
      status: map['status'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      delegatedTo: map['delegated_to'],
      waitingFor: map['waiting_for'],
      nextActionSituation: map['next_action_situation'],
      project: map['project'],
    );
  }

  /// 복사본 생성 (일부 필드 수정)
  NotionTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? clarification,
    String? status,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? delegatedTo,
    String? waitingFor,
    String? nextActionSituation,
    String? project,
  }) {
    return NotionTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      clarification: clarification ?? this.clarification,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      delegatedTo: delegatedTo ?? this.delegatedTo,
      waitingFor: waitingFor ?? this.waitingFor,
      nextActionSituation: nextActionSituation ?? this.nextActionSituation,
      project: project ?? this.project,
    );
  }
  
  @override
  String toString() {
    return 'NotionTask(id: $id, title: $title, status: $status, isCompleted: $isCompleted)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotionTask && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}


