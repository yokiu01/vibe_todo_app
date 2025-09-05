import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class CalendarSyncService {
  static const List<String> _scopes = [calendar.CalendarApi.calendarReadonlyScope];
  static const String _credentialsJson = '''
  {
    "type": "service_account",
    "project_id": "your-project-id",
    "private_key_id": "your-private-key-id",
    "private_key": "-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY\\n-----END PRIVATE KEY-----\\n",
    "client_email": "your-service-account@your-project-id.iam.gserviceaccount.com",
    "client_id": "your-client-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project-id.iam.gserviceaccount.com"
  }
  ''';

  static Future<List<Task>> syncGoogleCalendar(DateTime startDate, DateTime endDate) async {
    try {
      // Google Calendar API 인증
      final credentials = ServiceAccountCredentials.fromJson(_credentialsJson);
      final authClient = await clientViaServiceAccount(credentials, _scopes);
      
      final calendarApi = calendar.CalendarApi(authClient);
      
      // 이벤트 조회
      final events = await calendarApi.events.list(
        'primary',
        timeMin: startDate,
        timeMax: endDate,
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      final List<Task> tasks = [];
      
      for (final event in events.items ?? []) {
        if (event.start?.dateTime != null && event.end?.dateTime != null) {
          final task = Task(
            id: 'google_${event.id}',
            title: event.summary ?? '제목 없음',
            description: event.description,
            startTime: event.start!.dateTime!,
            endTime: event.end!.dateTime!,
            category: _mapEventToCategory(event),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isFromExternal: true,
            externalId: event.id,
          );
          tasks.add(task);
        }
      }
      
      return tasks;
    } catch (e) {
      print('Error syncing Google Calendar: $e');
      return [];
    }
  }

  static TaskCategory _mapEventToCategory(calendar.Event event) {
    // 이벤트 제목이나 설명을 기반으로 카테고리 매핑
    final title = (event.summary ?? '').toLowerCase();
    final description = (event.description ?? '').toLowerCase();
    
    if (title.contains('회의') || title.contains('meeting')) {
      return TaskCategory.work;
    } else if (title.contains('학습') || title.contains('study')) {
      return TaskCategory.study;
    } else if (title.contains('운동') || title.contains('exercise')) {
      return TaskCategory.exercise;
    } else if (title.contains('수면') || title.contains('sleep')) {
      return TaskCategory.sleep;
    } else if (title.contains('휴식') || title.contains('rest')) {
      return TaskCategory.rest;
    } else {
      return TaskCategory.other;
    }
  }

  static Future<List<Task>> syncNotionDatabase() async {
    // Notion API 동기화 (향후 구현)
    // 현재는 빈 리스트 반환
    return [];
  }
}

