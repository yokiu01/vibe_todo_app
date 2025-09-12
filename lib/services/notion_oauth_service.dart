import 'package:shared_preferences/shared_preferences.dart';

class NotionOAuthService {
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

설정 완료 후 앱을 다시 실행하세요!
    ''';
  }
}