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
  Future<Map<String, dynamic>> createProject(String title, {String? description}) async {
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
    
    return await createPage(PROJECT_DB_ID, properties);
  }
  
  /// 목표 생성
  Future<Map<String, dynamic>> createGoal(String title, {String? description}) async {
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
    
    return await createPage(GOAL_DB_ID, properties);
  }
  
  /// 메모 생성
  Future<Map<String, dynamic>> createMemo(String title, {String? content}) async {
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
    
    return await createPage(MEMO_DB_ID, properties);
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
    // Notion API는 복잡한 중첩 필터를 지원하지 않으므로 간단한 필터 사용
    final filter = <String, dynamic>{
      'and': <Map<String, dynamic>>[
        // 완료되지 않은 항목들만
        <String, dynamic>{
          'property': '완료',
          'checkbox': <String, dynamic>{
            'equals': false,
          }
        },
        // 명료화가 비어있는 것 (가장 기본적인 명료화가 필요한 항목)
        <String, dynamic>{
          'property': '명료화',
          'select': <String, dynamic>{
            'is_empty': true,
          }
        }
      ]
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }

  /// 기한 지난 할일 조회 (완료되지 않은 모든 항목)
  Future<List<Map<String, dynamic>>> getOverdueTasks() async {
    final filter = <String, dynamic>{
      'property': '완료',
      'checkbox': <String, dynamic>{
        'equals': false,
      }
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }
  
  /// 진행 중인 할일 조회 (완료되지 않은 모든 항목)
  Future<List<Map<String, dynamic>>> getInProgressTasks() async {
    final filter = <String, dynamic>{
      'property': '완료',
      'checkbox': <String, dynamic>{
        'equals': false,
      }
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }
  
  /// 다음 행동 할일 조회 (완료되지 않은 모든 항목)
  Future<List<Map<String, dynamic>>> getNextActionTasks() async {
    final filter = <String, dynamic>{
      'property': '완료',
      'checkbox': <String, dynamic>{
        'equals': false,
      }
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }
  
  /// 위임된 할일 조회 (완료되지 않은 모든 항목)
  Future<List<Map<String, dynamic>>> getDelegatedTasks() async {
    final filter = <String, dynamic>{
      'property': '완료',
      'checkbox': <String, dynamic>{
        'equals': false,
      }
    };
    
    return await queryDatabase(TODO_DB_ID, filter);
  }

  /// 특정 데이터베이스만 허용하는 필터링
  bool isAllowedDatabase(String databaseId) {
    const allowedDatabases = [
      TODO_DB_ID,      // 할일
      PROJECT_DB_ID,   // 프로젝트
      GOAL_DB_ID,      // 목표
      MEMO_DB_ID,      // 노트 (영역.자원)
    ];
    return allowedDatabases.contains(databaseId);
  }
}