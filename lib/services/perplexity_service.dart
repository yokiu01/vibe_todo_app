import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class PerplexityService extends AIService {
  final String apiKey;
  final String model;

  PerplexityService({
    required this.apiKey,
    this.model = 'llama-3.1-sonar-large-128k-online',
  });

  static const String _baseUrl = 'https://api.perplexity.ai';

  @override
  Future<String> generateResponse(String prompt, {Map<String, dynamic>? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant for a Korean productivity app called Plan·Do. Help users with task management, scheduling, and clarification.',
            },
            if (context != null)
              {
                'role': 'system',
                'content': 'Context: ${jsonEncode(context)}',
              },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Perplexity API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> clarifyTask(String taskDescription, {
    String? category,
    String? dueDate,
    String? priority,
  }) async {
    final prompt = '''
다음 작업을 분석하고 명료화해주세요:

작업: $taskDescription
${category != null ? '현재 카테고리: $category' : ''}
${dueDate != null ? '현재 마감일: $dueDate' : ''}
${priority != null ? '현재 우선순위: $priority' : ''}

다음 정보를 JSON 형태로 제공해주세요:
{
  "clarified_title": "명확하고 구체적인 작업 제목",
  "description": "작업에 대한 상세 설명",
  "estimated_duration": "예상 소요 시간 (분 단위 숫자)",
  "priority": "높음/보통/낮음 중 하나",
  "category": "적절한 카테고리 (업무/개인/학습/건강/기타)",
  "suggested_time": "작업하기 좋은 시간대 (오전/오후/저녁)",
  "breakdown": ["세부 단계들의 배열"],
  "prerequisites": ["필요한 사전 준비사항들의 배열"]
}

답변은 반드시 유효한 JSON 형태로만 해주세요.
''';

    try {
      final response = await generateResponse(prompt);

      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } else {
        throw Exception('Invalid JSON response from AI');
      }
    } catch (e) {
      throw Exception('Failed to clarify task: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateDailySchedule(
    List<Map<String, dynamic>> tasks,
    Map<String, dynamic> userPreferences,
  ) async {
    final prompt = '''
다음 작업들을 하루 일정으로 최적화해서 스케줄링해주세요:

작업 목록:
${tasks.map((task) => '- ${task['title']}: ${task['estimated_duration']}분, 우선순위: ${task['priority']}').join('\n')}

사용자 선호도:
- 작업 시작 시간: ${userPreferences['work_start_time'] ?? '09:00'}
- 작업 종료 시간: ${userPreferences['work_end_time'] ?? '18:00'}
- 휴식 시간 간격: ${userPreferences['break_interval'] ?? '90'}분
- 집중 시간 블록: ${userPreferences['focus_block_duration'] ?? '25'}분

다음 형태의 JSON 배열로 일정을 생성해주세요:
[
  {
    "task_id": "작업 ID",
    "title": "작업 제목",
    "start_time": "HH:MM",
    "end_time": "HH:MM",
    "duration": 소요시간_분,
    "type": "work/break",
    "priority": "높음/보통/낮음",
    "reasoning": "이 시간에 배치한 이유"
  }
]

답변은 반드시 유효한 JSON 배열 형태로만 해주세요.
''';

    try {
      final response = await generateResponse(prompt);

      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final List<dynamic> parsed = jsonDecode(jsonString);
        return parsed.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Invalid JSON response from AI');
      }
    } catch (e) {
      throw Exception('Failed to generate schedule: $e');
    }
  }
}
