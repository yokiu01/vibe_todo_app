import 'package:shared_preferences/shared_preferences.dart';
import 'notion_api_service.dart';

class NotionAuthService {
  static final NotionAuthService _instance = NotionAuthService._internal();
  factory NotionAuthService() => _instance;
  NotionAuthService._internal();

  static const String _apiKeyKey = 'notion_api_key';
  
  String? _apiKey;
  bool _isAuthenticated = false;
  NotionApiService? _apiService;

  /// API 키 설정
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    _apiService = NotionApiService();
    await _apiService!.setApiKey(apiKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    
    _isAuthenticated = true;
  }
  
  /// API 키 가져오기
  Future<String?> getApiKey() async {
    if (_apiKey != null) return _apiKey;
    
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey);
    
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _apiService = NotionApiService();
      await _apiService!.setApiKey(_apiKey!);
      _isAuthenticated = true;
    }
    
    return _apiKey;
  }
  
  /// API 키 삭제 (로그아웃)
  Future<void> clearApiKey() async {
    _apiKey = null;
    _isAuthenticated = false;
    _apiService = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
  }
  
  /// 인증 상태 확인
  Future<bool> isAuthenticated() async {
    if (_isAuthenticated && _apiKey != null) return true;
    
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  /// API 서비스 인스턴스 가져오기
  NotionApiService? get apiService => _apiService;
  
  /// 설정 가이드 표시
  String getSetupGuide() {
    return '''
🔧 Notion API 키 설정이 필요합니다!

1. Notion 개발자 포털 접속: https://www.notion.so/my-integrations
2. "New integration" 클릭
3. 앱 정보 입력:
   - Name: Vibe Todo App
   - Associated workspace: 본인의 워크스페이스 선택
4. "Submit" 클릭
5. 생성된 앱에서 "Internal Integration Token" 복사
6. 앱에서 "API 키 입력" 버튼을 눌러 복사한 토큰을 입력

⚠️ 중요: 각 데이터베이스에 통합을 공유해야 합니다!
- 할일 데이터베이스에 통합 공유
- 메모 데이터베이스에 통합 공유
- 프로젝트 데이터베이스에 통합 공유
- 목표 데이터베이스에 통합 공유

설정 완료 후 앱을 다시 실행하세요!
    ''';
  }

  /// 데이터베이스 접근 권한 검증
  Future<Map<String, bool>> validateDatabaseAccess() async {
    if (_apiService == null) return {};

    final results = <String, bool>{};
    
    try {
      // 할일 데이터베이스 검증
      try {
        await _apiService!.queryDatabase('1159f5e4a81180e591cbc596ae52f611', null);
        results['할일 데이터베이스'] = true;
      } catch (e) {
        results['할일 데이터베이스'] = false;
      }


      // 메모 데이터베이스 검증
      try {
        await _apiService!.queryDatabase('1159f5e4a81180e3a9f2fdf6634730e6', null);
        results['메모 데이터베이스'] = true;
      } catch (e) {
        results['메모 데이터베이스'] = false;
      }

      // 프로젝트 데이터베이스 검증
      try {
        await _apiService!.queryDatabase('1159f5e4a81180019f29cdd24d369230', null);
        results['프로젝트 데이터베이스'] = true;
      } catch (e) {
        results['프로젝트 데이터베이스'] = false;
      }

      // 목표 데이터베이스 검증
      try {
        await _apiService!.queryDatabase('1159f5e4a81180d092add53ae9df7f05', null);
        results['목표 데이터베이스'] = true;
      } catch (e) {
        results['목표 데이터베이스'] = false;
      }

    } catch (e) {
      print('데이터베이스 접근 권한 검증 중 오류: $e');
    }

    return results;
  }

  /// 데이터베이스 접근 권한 검증 결과 표시용 텍스트 생성
  String getValidationReport(Map<String, bool> results) {
    final buffer = StringBuffer();
    buffer.writeln('📊 데이터베이스 접근 권한 검증 결과\n');
    
    results.forEach((dbName, hasAccess) {
      final status = hasAccess ? '✅ 접근 가능' : '❌ 접근 불가';
      buffer.writeln('$dbName: $status');
    });
    
    final accessibleCount = results.values.where((access) => access).length;
    final totalCount = results.length;
    
    buffer.writeln('\n📈 요약: $accessibleCount/$totalCount 데이터베이스에 접근 가능');
    
    if (accessibleCount < totalCount) {
      buffer.writeln('\n⚠️ 접근 불가능한 데이터베이스가 있습니다.');
      buffer.writeln('Notion에서 해당 데이터베이스에 통합을 공유해주세요.');
    } else {
      buffer.writeln('\n🎉 모든 데이터베이스에 접근 가능합니다!');
    }
    
    return buffer.toString();
  }

  /// 명료화 탭용 할일들 가져오기
  Future<List<Map<String, dynamic>>> getClarificationTasks() async {
    if (_apiService == null) {
      throw Exception('API 서비스가 초기화되지 않았습니다. Notion API 키를 설정해주세요.');
    }
    if (!_isAuthenticated) {
      throw Exception('Notion 인증이 되지 않았습니다. API 키를 확인해주세요.');
    }
    try {
      return await _apiService!.getClarificationTasks();
    } catch (e) {
      print('getClarificationTasks 에러: $e');
      rethrow;
    }
  }

  /// 수집 탭용 할일들 가져오기
  Future<List<Map<String, dynamic>>> getInboxTasks() async {
    if (_apiService == null) {
      throw Exception('API 서비스가 초기화되지 않았습니다.');
    }
    return await _apiService!.getInboxTasks();
  }
}
