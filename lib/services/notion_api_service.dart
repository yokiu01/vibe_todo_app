import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotionApiService {
  static const String baseUrl = 'https://api.notion.com/v1';
  
  // 실제 Notion 데이터베이스 ID들
  static const String TODO_DB_ID = '1159f5e4a81180e591cbc596ae52f611';
  static const String MEMO_DB_ID = '1159f5e4a81180e3a9f2fdf6634730e6';
  static const String PROJECT_DB_ID = '1159f5e4a81180019f29cdd24d369230';
  static const String GOAL_DB_ID = '1159f5e4a81180d092add53ae9df7f05';
  static const String AREA_RESOURCE_DB_ID = '1159f5e4a81180d1ab17fa79bb0cf0f4'; // 영역·자원 데이터베이스
  static const String PDS_DB_ID = '27b9f5e4a811805c89cff86146f4d12f'; // PDS 데이터베이스
  
  static const String _apiKeyKey = 'notion_api_key';
  
  /// API 키 설정
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }
  
  /// API 키 삭제 (로그아웃)
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
  }
  
  /// 인증 상태 확인
  Future<bool> isAuthenticated() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  /// 인증 헤더 생성
  Future<Map<String, String>> _getHeaders() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다. 먼저 API 키를 입력해주세요.');
    }
    
    return <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Notion-Version': '2022-06-28',
    };
  }
  
  /// API 연결 테스트
  Future<bool> testConnection() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/users/me');
      
      final response = await http.get(url, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('API 연결 테스트 실패: $e');
      return false;
    }
  }
  
  /// 페이지 생성
  Future<Map<String, dynamic>> createPage(String databaseId, Map<String, dynamic> properties) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/pages');
      
      final body = <String, dynamic>{
        'parent': <String, dynamic>{'database_id': databaseId},
        'properties': properties,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('페이지 생성 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('페이지 생성 오류: $e');
      rethrow;
    }
  }
  
  /// 페이지 수정
  Future<Map<String, dynamic>> updatePage(String pageId, Map<String, dynamic> properties) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/pages/$pageId');
      
      final body = <String, dynamic>{
        'properties': properties,
      };
      
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('페이지 수정 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('페이지 수정 오류: $e');
      rethrow;
    }
  }
  
  /// 페이지 삭제
  Future<void> deletePage(String pageId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/pages/$pageId');
      
      final body = <String, dynamic>{
        'archived': true,
      };
      
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode != 200) {
        throw Exception('페이지 삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('페이지 삭제 오류: $e');
      rethrow;
    }
  }
  
  /// 데이터베이스 쿼리
  Future<List<Map<String, dynamic>>> queryDatabase(String databaseId, Map<String, dynamic>? filter) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/databases/$databaseId/query');
      
      final body = <String, dynamic>{};
      if (filter != null) {
        body['filter'] = filter;
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        print('Notion API 응답 오류:');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('Database ID: $databaseId');
        print('Filter: $filter');
        
        if (response.statusCode == 401) {
          throw Exception('Notion API 키가 유효하지 않습니다. API 키를 확인해주세요.');
        } else if (response.statusCode == 404) {
          throw Exception('데이터베이스를 찾을 수 없습니다. 데이터베이스 ID를 확인해주세요: $databaseId');
        } else if (response.statusCode == 403) {
          throw Exception('데이터베이스에 접근 권한이 없습니다. Notion에서 Integration을 데이터베이스에 공유해주세요.');
        } else {
          throw Exception('데이터베이스 쿼리 실패: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('데이터베이스 쿼리 오류: $e');
      print('Database ID: $databaseId');
      print('Filter: $filter');
      rethrow;
    }
  }
  
  /// 페이지 조회
  Future<Map<String, dynamic>> getPage(String pageId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/pages/$pageId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('페이지 조회 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('페이지 조회 오류: $e');
      rethrow;
    }
  }
  
  /// 할일 생성 (TODO 데이터베이스)
  Future<Map<String, dynamic>> createTodo(String title, {String? description}) async {
    final properties = <String, dynamic>{
      '이름': <String, dynamic>{
        'title': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': title,
            }
          }
        ]
      },
    };
    
    if (description != null && description.isNotEmpty) {
      properties['description'] = <String, dynamic>{
        'rich_text': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': description,
            }
          }
        ]
      };
    }
    
    return await createPage(TODO_DB_ID, properties);
  }
  
  
  /// 프로젝트 생성
  Future<Map<String, dynamic>> createProject(String title, {String? description, String? areaResourceId}) async {
    final properties = <String, dynamic>{
      '이름': <String, dynamic>{
        'title': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': title,
            }
          }
        ]
      },
    };
    
    if (description != null && description.isNotEmpty) {
      properties['description'] = <String, dynamic>{
        'rich_text': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': description,
            }
          }
        ]
      };
    }
    
    if (areaResourceId != null && areaResourceId.isNotEmpty) {
      properties['영역 · 자원 데이터베이스'] = <String, dynamic>{
        'relation': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': areaResourceId,
          }
        ]
      };
    }
    
    return await createPage(PROJECT_DB_ID, properties);
  }
  
  /// 목표 생성
  Future<Map<String, dynamic>> createGoal(String title, {String? description, String? areaResourceId}) async {
    final properties = <String, dynamic>{
      '이름': <String, dynamic>{
        'title': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': title,
            }
          }
        ]
      },
    };
    
    if (description != null && description.isNotEmpty) {
      properties['description'] = <String, dynamic>{
        'rich_text': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': description,
            }
          }
        ]
      };
    }
    
    if (areaResourceId != null && areaResourceId.isNotEmpty) {
      properties['영역 · 자원 데이터베이스'] = <String, dynamic>{
        'relation': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': areaResourceId,
          }
        ]
      };
    }
    
    return await createPage(GOAL_DB_ID, properties);
  }
  
  /// 메모 생성
  Future<Map<String, dynamic>> createMemo(String title, {String? content, String? category, String? areaResourceId}) async {
    final properties = <String, dynamic>{
      '이름': <String, dynamic>{
        'title': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': title,
            }
          }
        ]
      },
    };
    
    if (content != null && content.isNotEmpty) {
      properties['content'] = <String, dynamic>{
        'rich_text': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': <String, dynamic>{
              'content': content,
            }
          }
        ]
      };
    }
    
    if (category != null && category.isNotEmpty) {
      properties['분류'] = <String, dynamic>{
        'select': <String, dynamic>{
          'name': category,
        }
      };
    }
    
    if (areaResourceId != null && areaResourceId.isNotEmpty) {
      properties['영역 · 자원 데이터베이스'] = <String, dynamic>{
        'relation': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': areaResourceId,
          }
        ]
      };
    }
    
    return await createPage(MEMO_DB_ID, properties);
  }
  

  /// 특정 날짜의 할일 조회
  Future<List<Map<String, dynamic>>> getTasksByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD 형식
    
    final filter = <String, dynamic>{
      'property': '날짜',
      'date': <String, dynamic>{
        'equals': dateStr,
      }
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }

  /// 수집 탭용 할일 조회 (명료화가 비어있고 완료가 체크되지 않은 항목들)
  Future<List<Map<String, dynamic>>> getInboxTasks() async {
    final filter = <String, dynamic>{
      'and': <Map<String, dynamic>>[
        <String, dynamic>{
          'property': '명료화',
          'select': <String, dynamic>{
            'is_empty': true,
          }
        },
        <String, dynamic>{
          'property': '완료',
          'checkbox': <String, dynamic>{
            'equals': false,
          }
        }
      ]
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }

  /// 명료화 탭용 할일 조회 (명료화가 필요한 모든 항목들)
  Future<List<Map<String, dynamic>>> getClarificationTasks() async {
    // 완료되지 않은 모든 항목을 가져온 후 클라이언트에서 필터링
    final filter = <String, dynamic>{
      'property': '완료',
      'checkbox': <String, dynamic>{
        'equals': false,
      }
    };
    
    final allTasks = await queryDatabase(TODO_DB_ID, filter);
    
    // 클라이언트에서 명료화가 필요한 항목들만 필터링
    return allTasks.where((task) {
      final properties = task['properties'] as Map<String, dynamic>?;
      if (properties == null) return false;
      
      final clarification = properties['명료화'] as Map<String, dynamic>?;
      final clarificationValue = clarification?['select']?['name'] as String?;
      
      // 명료화가 비어있으면 명료화 필요
      if (clarificationValue == null || clarificationValue.isEmpty) {
        return true;
      }
      
      // 명료화가 '할일'인데 날짜가 비어있으면 다시 명료화 필요
      if (clarificationValue == '할일') {
        final date = properties['날짜'] as Map<String, dynamic>?;
        final dateValue = date?['date']?['start'] as String?;
        return dateValue == null || dateValue.isEmpty;
      }
      
      // 명료화가 '위임'인 경우는 담당자가 비어있어도 됨 (요청사항 반영)
      if (clarificationValue == '위임') {
        return false; // 위임은 담당자가 비어있어도 명료화 완료로 간주
      }
      
      // 명료화가 '프로젝트'나 '목표'인 경우는 해당 데이터베이스로 이동되므로 명료화 완료
      if (clarificationValue == '프로젝트' || clarificationValue == '목표') {
        return false;
      }
      
      // 다른 경우들은 명료화가 완료된 것으로 간주
      return false;
    }).toList();
  }

  /// 기한 지난 할일 조회 (날짜가 이전이고 완료되지 않은 항목)
  Future<List<Map<String, dynamic>>> getOverdueTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final filter = <String, dynamic>{
      'and': <Map<String, dynamic>>[
        <String, dynamic>{
          'property': '완료',
          'checkbox': <String, dynamic>{
            'equals': false,
          }
        },
        <String, dynamic>{
          'property': '날짜',
          'date': <String, dynamic>{
            'before': today.toIso8601String().split('T')[0], // YYYY-MM-DD 형식 (당일 불포함)
          }
        }
      ]
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }
  
  /// 진행 중인 프로젝트별 할일 조회 (완료되지 않은 모든 할일)
  Future<List<Map<String, dynamic>>> getInProgressTasks() async {
    // 완료되지 않은 모든 할일을 반환
    final filter = <String, dynamic>{
      'property': '완료',
      'checkbox': <String, dynamic>{
        'equals': false,
      }
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }
  
  /// 다음 행동 할일 조회 (다음 행동 상황이 비어있지 않고 완료되지 않고 날짜가 비어있는 할일)
  Future<List<Map<String, dynamic>>> getNextActionTasks() async {
    final filter = <String, dynamic>{
      'and': <Map<String, dynamic>>[
        <String, dynamic>{
          'property': '완료',
          'checkbox': <String, dynamic>{
            'equals': false,
          }
        },
        <String, dynamic>{
          'property': '다음 행동 상황',
          'multi_select': <String, dynamic>{
            'is_not_empty': true,
          }
        },
        <String, dynamic>{
          'property': '날짜',
          'date': <String, dynamic>{
            'is_empty': true,
          }
        }
      ]
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }
  
  /// 위임된 할일 조회 (명료화가 위임이고 날짜가 비어있고 완료되지 않은 할일)
  Future<List<Map<String, dynamic>>> getDelegatedTasks() async {
    final filter = <String, dynamic>{
      'and': <Map<String, dynamic>>[
        <String, dynamic>{
          'property': '완료',
          'checkbox': <String, dynamic>{
            'equals': false,
          }
        },
        <String, dynamic>{
          'property': '명료화',
          'select': <String, dynamic>{
            'equals': '위임',
          }
        },
        <String, dynamic>{
          'property': '날짜',
          'date': <String, dynamic>{
            'is_empty': true,
          }
        }
      ]
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }

  /// 영역 · 자원 데이터베이스 데이터베이스에서 항목들 조회
  Future<List<Map<String, dynamic>>> getAreaResourceItems() async {
    return await queryDatabase(AREA_RESOURCE_DB_ID, null);
  }

  /// 특정 데이터베이스만 허용하는 필터링
  bool isAllowedDatabase(String databaseId) {
    const allowedDatabases = [
      TODO_DB_ID,      // 할일
      PROJECT_DB_ID,   // 프로젝트
      GOAL_DB_ID,      // 목표
      MEMO_DB_ID,      // 노트 (영역.자원)
      AREA_RESOURCE_DB_ID, // 영역 · 자원 데이터베이스
      PDS_DB_ID,       // PDS 데이터베이스
    ];
    return allowedDatabases.contains(databaseId);
  }

  /// 페이지에 블록 추가 (Append Block Children)
  Future<Map<String, dynamic>> appendBlockChildren(
    String pageId,
    List<Map<String, dynamic>> blocks,
  ) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/blocks/$pageId/children';

    final body = jsonEncode(<String, dynamic>{
      'children': blocks,
    });

    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('블록 추가 실패 (${response.statusCode}): ${errorBody['message'] ?? response.body}');
    }
  }

  /// 페이지의 블록 내용 조회
  Future<List<Map<String, dynamic>>> getBlockChildren(String pageId) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/blocks/$pageId/children';

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('블록 조회 실패 (${response.statusCode}): ${errorBody['message'] ?? response.body}');
    }
  }

  /// 텍스트 블록 생성 헬퍼 메서드
  Map<String, dynamic> createParagraphBlock(String text) {
    return <String, dynamic>{
      'object': 'block',
      'type': 'paragraph',
      'paragraph': <String, dynamic>{
        'rich_text': [
          <String, dynamic>{
            'type': 'text',
            'text': <String, dynamic>{
              'content': text,
            },
          },
        ],
      },
    };
  }

  /// 오늘 수집한 항목들 조회 (MEMO_DB_ID에서 오늘 생성된 항목들)
  Future<List<Map<String, dynamic>>> getTodayCollectedItems() async {
    try {
      // 모든 항목을 가져온 후 클라이언트에서 오늘 생성된 것만 필터링
      final allItems = await queryDatabase(MEMO_DB_ID, null);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // 오늘 생성된 항목들만 필터링
      final todayItems = allItems.where((item) {
        final createdTime = item['created_time'] as String?;
        if (createdTime == null) return false;

        final created = DateTime.tryParse(createdTime);
        if (created == null) return false;

        return created.isAfter(today.subtract(const Duration(seconds: 1))) &&
               created.isBefore(tomorrow);
      }).toList();

      return todayItems;
    } catch (e) {
      print('getTodayCollectedItems 오류: $e');
      rethrow;
    }
  }

  /// 특정 영역/자원/프로젝트와 관련된 노트들을 찾는 메서드
  Future<List<Map<String, dynamic>>> getRelatedNotes(String parentTitle) async {
    try {
      // 노트 데이터베이스에서 해당 영역/자원/프로젝트와 관련된 노트들을 찾음
      final allNotes = await queryDatabase(MEMO_DB_ID, null);

      // 제목이나 내용에서 관련성을 찾음
      final relatedNotes = allNotes.where((note) {
        final properties = note['properties'] as Map<String, dynamic>? ?? {};

        // 제목에서 관련성 확인
        final nameProperty = properties['이름'] as Map<String, dynamic>? ?? {};
        final titleArray = nameProperty['title'] as List<dynamic>? ?? [];
        final title = titleArray.isNotEmpty
            ? (titleArray.first['text']?['content'] as String? ?? '')
            : '';

        // 태그나 관련 속성에서 관련성 확인
        final tagProperty = properties['태그'] as Map<String, dynamic>? ?? {};
        final multiSelect = tagProperty['multi_select'] as List<dynamic>? ?? [];
        final tags = multiSelect.map((tag) => tag['name'] as String? ?? '').toList();

        // 관련 프로젝트/영역 속성 확인
        final relatedProperty = properties['관련'] as Map<String, dynamic>? ?? {};
        final relatedSelect = relatedProperty['select'] as Map<String, dynamic>? ?? {};
        final relatedValue = relatedSelect['name'] as String? ?? '';

        return title.contains(parentTitle) ||
               tags.any((tag) => tag.contains(parentTitle)) ||
               relatedValue.contains(parentTitle);
      }).toList();

      return relatedNotes;
    } catch (e) {
      print('getRelatedNotes 오류: $e');
      rethrow;
    }
  }

  /// 모든 노트를 가져오는 메서드 (분류별 필터링 가능)
  Future<List<Map<String, dynamic>>> getAllNotes({String? categoryFilter}) async {
    try {
      final allNotes = await queryDatabase(MEMO_DB_ID, null);

      if (categoryFilter == null) {
        return allNotes;
      }

      // 분류별 필터링
      final filteredNotes = allNotes.where((note) {
        final properties = note['properties'] as Map<String, dynamic>? ?? {};
        final categoryProperty = properties['분류'] as Map<String, dynamic>? ?? {};
        final selectValue = categoryProperty['select'] as Map<String, dynamic>? ?? {};
        final categoryName = selectValue['name'] as String? ?? '';

        return categoryName == categoryFilter;
      }).toList();

      return filteredNotes;
    } catch (e) {
      print('getAllNotes 오류: $e');
      rethrow;
    }
  }

  /// 특정 영역·자원과 관련된 목표 조회
  Future<List<Map<String, dynamic>>> getRelatedGoals(String areaResourceId) async {
    try {
      final filter = {
        'property': '영역 · 자원 데이터베이스',
        'relation': {
          'contains': areaResourceId,
        }
      };

      return await queryDatabase(GOAL_DB_ID, filter);
    } catch (e) {
      print('관련 목표 조회 오류: $e');
      return [];
    }
  }

  /// 특정 영역·자원과 관련된 프로젝트 조회
  Future<List<Map<String, dynamic>>> getRelatedProjects(String areaResourceId) async {
    try {
      final filter = {
        'property': '영역 · 자원 데이터베이스',
        'relation': {
          'contains': areaResourceId,
        }
      };

      return await queryDatabase(PROJECT_DB_ID, filter);
    } catch (e) {
      print('관련 프로젝트 조회 오류: $e');
      return [];
    }
  }

  /// 특정 영역·자원과 관련된 노트 조회 (관계형 필터)
  Future<List<Map<String, dynamic>>> getRelatedNotesByRelation(String areaResourceId) async {
    try {
      final filter = {
        'property': '영역 · 자원 데이터베이스',
        'relation': {
          'contains': areaResourceId,
        }
      };

      return await queryDatabase(MEMO_DB_ID, filter);
    } catch (e) {
      print('관련 노트 조회 오류: $e');
      return [];
    }
  }

  /// 특정 목표/프로젝트와 관련된 할일 조회
  Future<List<Map<String, dynamic>>> getRelatedTodos(String goalOrProjectId) async {
    try {
      // 목표 관련 할일 조회
      final goalFilter = {
        'property': '목표 데이터베이스',
        'relation': {
          'contains': goalOrProjectId,
        }
      };

      final goalTodos = await queryDatabase(TODO_DB_ID, goalFilter);

      // 프로젝트 관련 할일 조회
      final projectFilter = {
        'property': '프로젝트 데이터베이스',
        'relation': {
          'contains': goalOrProjectId,
        }
      };

      final projectTodos = await queryDatabase(TODO_DB_ID, projectFilter);

      // 중복 제거하여 반환
      final allTodos = [...goalTodos, ...projectTodos];
      final uniqueTodos = <String, Map<String, dynamic>>{};

      for (final todo in allTodos) {
        final id = todo['id'] as String;
        uniqueTodos[id] = todo;
      }

      return uniqueTodos.values.toList();
    } catch (e) {
      print('관련 할일 조회 오류: $e');
      return [];
    }
  }

  /// 특정 목표/프로젝트와 관련된 노트 조회
  Future<List<Map<String, dynamic>>> getRelatedNotesForGoalProject(String goalOrProjectId) async {
    try {
      // 목표와 관련된 노트 조회
      final goalFilter = {
        'property': '목표 데이터베이스',
        'relation': {
          'contains': goalOrProjectId,
        }
      };

      final goalNotes = await queryDatabase(MEMO_DB_ID, goalFilter);

      // 프로젝트와 관련된 노트 조회
      final projectFilter = {
        'property': '프로젝트 데이터베이스',
        'relation': {
          'contains': goalOrProjectId,
        }
      };

      final projectNotes = await queryDatabase(MEMO_DB_ID, projectFilter);

      // 중복 제거하여 반환
      final allNotes = [...goalNotes, ...projectNotes];
      final uniqueNotes = <String, Map<String, dynamic>>{};

      for (final note in allNotes) {
        final id = note['id'] as String;
        uniqueNotes[id] = note;
      }

      return uniqueNotes.values.toList();
    } catch (e) {
      print('관련 노트 조회 오류: $e');
      return [];
    }
  }

  /// 위치 기반 할일 조회 (위치 기반 알림용)
  Future<List<Map<String, dynamic>>> getTasksForLocation(String locationName) async {
    try {
      final filter = {
        'and': [
          {
            'property': '완료',
            'checkbox': {
              'equals': false,
            }
          },
          {
            'property': '명료화',
            'select': {
              'equals': '다음행동',
            }
          },
          {
            'property': '다음 행동 상황',
            'multi_select': {
              'contains': locationName,
            }
          }
        ]
      };

      return await queryDatabase(TODO_DB_ID, filter);
    } catch (e) {
      print('위치 기반 할일 조회 오류: $e');
      rethrow;
    }
  }

  /// 할일의 날짜/시간 업데이트
  Future<void> updateTaskDateTime(String taskId, DateTime dateTime) async {
    try {
      final properties = <String, dynamic>{
        '날짜': <String, dynamic>{
          'date': <String, dynamic>{
            'start': dateTime.toIso8601String(),
          }
        }
      };

      await updatePage(taskId, properties);
    } catch (e) {
      print('할일 날짜/시간 업데이트 오류: $e');
      rethrow;
    }
  }

  // ==================== PDS 관련 메서드 ====================

  /// 헤딩 블록 생성 헬퍼 메서드
  Map<String, dynamic> createHeadingBlock(String text, {int level = 2}) {
    final headingType = 'heading_$level';
    return <String, dynamic>{
      'object': 'block',
      'type': headingType,
      headingType: <String, dynamic>{
        'rich_text': [
          <String, dynamic>{
            'type': 'text',
            'text': <String, dynamic>{
              'content': text,
            },
          },
        ],
      },
    };
  }

  /// 토글 블록 생성 헬퍼 메서드
  Map<String, dynamic> createToggleBlock(String text, {List<Map<String, dynamic>>? children}) {
    return <String, dynamic>{
      'object': 'block',
      'type': 'toggle',
      'toggle': <String, dynamic>{
        'rich_text': [
          <String, dynamic>{
            'type': 'text',
            'text': <String, dynamic>{
              'content': text,
            },
          },
        ],
        if (children != null && children.isNotEmpty) 'children': children,
      },
    };
  }

  /// 특정 날짜의 PDS 페이지 조회
  Future<Map<String, dynamic>?> getPDSPageByDate(DateTime date) async {
    try {
      final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

      final filter = <String, dynamic>{
        'property': '이름',
        'title': <String, dynamic>{
          'equals': dateStr,
        }
      };

      final results = await queryDatabase(PDS_DB_ID, filter);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('PDS 페이지 조회 오류: $e');
      return null;
    }
  }

  /// PDS 페이지 생성
  Future<Map<String, dynamic>> createPDSPage(DateTime date) async {
    try {
      final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

      final properties = <String, dynamic>{
        '이름': <String, dynamic>{
          'title': <Map<String, dynamic>>[
            <String, dynamic>{
              'text': <String, dynamic>{
                'content': dateStr,
              }
            }
          ]
        },
      };

      final page = await createPage(PDS_DB_ID, properties);
      final pageId = page['id'] as String;

      // 초기 블록 구조 생성
      await _createInitialPDSBlocks(pageId);

      return page;
    } catch (e) {
      print('PDS 페이지 생성 오류: $e');
      rethrow;
    }
  }

  /// PDS 페이지 초기 블록 구조 생성
  Future<void> _createInitialPDSBlocks(String pageId) async {
    final blocks = <Map<String, dynamic>>[
      createHeadingBlock('Plan ✍️'),
      createHeadingBlock('Do 🏃'),
      createHeadingBlock('See 👀'),
    ];

    await appendBlockChildren(pageId, blocks);
  }

  /// PDS 페이지에 계획 내용 추가
  Future<void> addPlanContent(String pageId, String timeSlot, String content) async {
    try {
      final blocks = await getBlockChildren(pageId);
      String? planHeadingId;

      // Plan 헤딩 찾기
      for (final block in blocks) {
        if (block['type'] == 'heading_2') {
          final richText = block['heading_2']?['rich_text'] as List<dynamic>? ?? [];
          if (richText.isNotEmpty) {
            final text = richText.first['text']?['content'] as String? ?? '';
            if (text.startsWith('Plan')) {
              planHeadingId = block['id'] as String;
              break;
            }
          }
        }
      }

      if (planHeadingId == null) {
        throw Exception('Plan 헤딩을 찾을 수 없습니다.');
      }

      // Plan 헤딩 아래의 기존 블록들 조회
      final planChildren = await getBlockChildren(planHeadingId);

      // 해당 시간 슬롯의 토글 블록 찾기 또는 생성
      String? timeToggleId;
      for (final child in planChildren) {
        if (child['type'] == 'toggle') {
          final richText = child['toggle']?['rich_text'] as List<dynamic>? ?? [];
          if (richText.isNotEmpty) {
            final text = richText.first['text']?['content'] as String? ?? '';
            if (text == timeSlot) {
              timeToggleId = child['id'] as String;
              break;
            }
          }
        }
      }

      if (timeToggleId == null) {
        // 새 시간 토글 블록 생성
        final timeToggleBlock = createToggleBlock(timeSlot, children: [createParagraphBlock(content)]);
        await appendBlockChildren(planHeadingId, [timeToggleBlock]);
      } else {
        // 기존 토글에 내용 추가
        await appendBlockChildren(timeToggleId, [createParagraphBlock(content)]);
      }
    } catch (e) {
      print('계획 내용 추가 오류: $e');
      rethrow;
    }
  }

  /// PDS 페이지에 실제 활동 내용 추가
  Future<void> addDoContent(String pageId, String timeSlot, String content) async {
    try {
      final blocks = await getBlockChildren(pageId);
      String? doHeadingId;

      // Do 헤딩 찾기
      for (final block in blocks) {
        if (block['type'] == 'heading_2') {
          final richText = block['heading_2']?['rich_text'] as List<dynamic>? ?? [];
          if (richText.isNotEmpty) {
            final text = richText.first['text']?['content'] as String? ?? '';
            if (text.startsWith('Do')) {
              doHeadingId = block['id'] as String;
              break;
            }
          }
        }
      }

      if (doHeadingId == null) {
        throw Exception('Do 헤딩을 찾을 수 없습니다.');
      }

      // Do 헤딩 아래의 기존 블록들 조회
      final doChildren = await getBlockChildren(doHeadingId);

      // 해당 시간 슬롯의 토글 블록 찾기 또는 생성
      String? timeToggleId;
      for (final child in doChildren) {
        if (child['type'] == 'toggle') {
          final richText = child['toggle']?['rich_text'] as List<dynamic>? ?? [];
          if (richText.isNotEmpty) {
            final text = richText.first['text']?['content'] as String? ?? '';
            if (text == timeSlot) {
              timeToggleId = child['id'] as String;
              break;
            }
          }
        }
      }

      if (timeToggleId == null) {
        // 새 시간 토글 블록 생성
        final timeToggleBlock = createToggleBlock(timeSlot, children: [createParagraphBlock(content)]);
        await appendBlockChildren(doHeadingId, [timeToggleBlock]);
      } else {
        // 기존 토글에 내용 추가
        await appendBlockChildren(timeToggleId, [createParagraphBlock(content)]);
      }
    } catch (e) {
      print('실제 활동 내용 추가 오류: $e');
      rethrow;
    }
  }

  /// PDS 페이지에 회고 내용 추가
  Future<void> addSeeContent(String pageId, String content) async {
    try {
      final blocks = await getBlockChildren(pageId);
      String? seeHeadingId;

      // See 헤딩 찾기
      for (final block in blocks) {
        if (block['type'] == 'heading_2') {
          final richText = block['heading_2']?['rich_text'] as List<dynamic>? ?? [];
          if (richText.isNotEmpty) {
            final text = richText.first['text']?['content'] as String? ?? '';
            if (text.startsWith('See')) {
              seeHeadingId = block['id'] as String;
              break;
            }
          }
        }
      }

      if (seeHeadingId == null) {
        throw Exception('See 헤딩을 찾을 수 없습니다.');
      }

      // See 헤딩 아래에 내용 추가
      await appendBlockChildren(seeHeadingId, [createParagraphBlock(content)]);
    } catch (e) {
      print('회고 내용 추가 오류: $e');
      rethrow;
    }
  }

  /// PDS 전체 동기화 (날짜별로 한 번에 처리)
  Future<void> syncPDSData(DateTime date, Map<String, String>? plans, Map<String, String>? activities, String? seeNotes) async {
    try {
      print('PDS 동기화 시작: ${date.toIso8601String().split('T')[0]}');

      // 기존 페이지 찾기 또는 새로 생성
      var pdsPage = await getPDSPageByDate(date);
      if (pdsPage == null) {
        print('새 PDS 페이지 생성');
        pdsPage = await createPDSPage(date);
      }

      final pageId = pdsPage['id'] as String;
      print('PDS 페이지 ID: $pageId');

      // 계획 동기화
      if (plans != null && plans.isNotEmpty) {
        print('계획 동기화: ${plans.length}개 항목');
        for (final entry in plans.entries) {
          if (entry.value.trim().isNotEmpty) {
            final timeSlot = entry.key.substring(0, 2); // "03:00" -> "03"
            await addPlanContent(pageId, timeSlot, entry.value);
          }
        }
      }

      // 실제 활동 동기화
      if (activities != null && activities.isNotEmpty) {
        print('실제 활동 동기화: ${activities.length}개 항목');
        for (final entry in activities.entries) {
          if (entry.value.trim().isNotEmpty) {
            final timeSlot = entry.key.substring(0, 2); // "03:00" -> "03"
            await addDoContent(pageId, timeSlot, entry.value);
          }
        }
      }

      // 회고 동기화
      if (seeNotes != null && seeNotes.trim().isNotEmpty) {
        print('회고 동기화');
        await addSeeContent(pageId, seeNotes);
      }

      print('PDS 동기화 완료');
    } catch (e) {
      print('PDS 동기화 오류: $e');
      rethrow;
    }
  }
}