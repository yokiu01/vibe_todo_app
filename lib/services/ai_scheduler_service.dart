import 'dart:convert';
import 'ai_service.dart';
import 'openai_service.dart';

class AISchedulerService {
  static AIService? _aiService;

  static Future<void> initialize() async {
    final config = await AIService.getConfig();
    if (config != null) {
      switch (config.provider) {
        case AIServiceProvider.openai:
          _aiService = OpenAIService(
            apiKey: config.apiKey,
            model: config.model.isNotEmpty ? config.model : 'gpt-4',
          );
          break;
        case AIServiceProvider.claude:
          break;
      }
    }
  }

  static bool get isConfigured => _aiService != null;

  static Future<List<Map<String, dynamic>>> generateDailySchedule({
    required List<Map<String, dynamic>> tasks,
    required DateTime targetDate,
    Map<String, dynamic>? userPreferences,
    List<Map<String, dynamic>>? existingEvents,
  }) async {
    if (_aiService == null) {
      throw Exception('AI service not configured. Please set up API keys first.');
    }

    final defaultPreferences = {
      'work_start_time': '09:00',
      'work_end_time': '18:00',
      'break_interval': 90,
      'focus_block_duration': 25,
      'lunch_start': '12:00',
      'lunch_duration': 60,
      'energy_peak_hours': ['09:00-11:00', '14:00-16:00'],
      'low_energy_tasks': ['email', 'admin', 'planning'],
      'high_energy_tasks': ['creative', 'analysis', 'problem-solving'],
    };

    final preferences = {...defaultPreferences, ...?userPreferences};

    try {
      final schedule = await _aiService!.generateDailySchedule(tasks, preferences);

      return schedule.map((item) => {
        ...item,
        'date': targetDate.toIso8601String().split('T')[0],
        'generated_at': DateTime.now().toIso8601String(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to generate schedule: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> optimizeSchedule({
    required List<Map<String, dynamic>> currentSchedule,
    required List<Map<String, dynamic>> completedTasks,
    Map<String, dynamic>? learningData,
  }) async {
    if (_aiService == null) {
      return currentSchedule;
    }

    final prompt = '''
현재 일정을 분석하고 완료된 작업들을 바탕으로 최적화해주세요:

현재 일정:
${currentSchedule.map((s) => '${s['start_time']}-${s['end_time']}: ${s['title']} (${s['duration']}분)').join('\n')}

완료된 작업들:
${completedTasks.map((t) => '${t['title']}: 예상 ${t['estimated_duration']}분, 실제 ${t['actual_duration'] ?? 'N/A'}분').join('\n')}

${learningData != null ? '학습 데이터:\n${learningData.entries.map((e) => '${e.key}: ${e.value}').join('\n')}' : ''}

다음을 고려하여 일정을 최적화해주세요:
1. 실제 소요 시간 vs 예상 시간 차이
2. 작업 유형별 최적 시간대
3. 연속 작업 vs 분할 작업 효율성
4. 휴식 시간 적절성

최적화된 일정을 다음 JSON 형태로 제공해주세요:
[
  {
    "task_id": "작업 ID",
    "title": "작업 제목",
    "start_time": "HH:MM",
    "end_time": "HH:MM",
    "duration": 소요시간_분,
    "type": "work/break",
    "priority": "높음/보통/낮음",
    "optimization_reason": "최적화 이유",
    "confidence": 0.8
  }
]

답변은 반드시 유효한 JSON 배열 형태로만 해주세요.
''';

    try {
      final response = await _aiService!.generateResponse(prompt);

      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final List<dynamic> parsed = jsonDecode(jsonString);
        return List<Map<String, dynamic>>.from(parsed);
      }
    } catch (e) {
      print('Error optimizing schedule: $e');
    }

    return currentSchedule;
  }

  static Future<Map<String, dynamic>?> suggestBreakPlacement({
    required List<Map<String, dynamic>> currentSchedule,
    required int totalWorkMinutes,
    Map<String, dynamic>? energyPattern,
  }) async {
    if (_aiService == null) {
      return null;
    }

    final prompt = '''
현재 일정에서 최적의 휴식 시간 배치를 제안해주세요:

현재 일정:
${currentSchedule.map((s) => '${s['start_time']}-${s['end_time']}: ${s['title']}').join('\n')}

총 작업 시간: ${totalWorkMinutes}분

${energyPattern != null ? '에너지 패턴:\n${energyPattern.entries.map((e) => '${e.key}: ${e.value}').join('\n')}' : ''}

다음을 고려하여 휴식 시간을 제안해주세요:
1. 연속 작업 시간이 90분을 초과하지 않도록
2. 에너지 저하 시점에 휴식 배치
3. 작업 유형 전환 시 적절한 휴식
4. 점심시간과의 조화

제안사항을 다음 JSON 형태로 제공해주세요:
{
  "suggested_breaks": [
    {
      "start_time": "HH:MM",
      "duration": 휴식시간_분,
      "type": "short/long",
      "reason": "휴식이 필요한 이유",
      "activity_suggestions": ["휴식 중 권장 활동들"]
    }
  ],
  "schedule_adjustments": [
    {
      "task_id": "조정할 작업 ID",
      "new_start_time": "HH:MM",
      "reason": "조정 이유"
    }
  ]
}

답변은 반드시 유효한 JSON 형태로만 해주세요.
''';

    try {
      final response = await _aiService!.generateResponse(prompt);

      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        return Map<String, dynamic>.from(
          Uri.splitQueryString(jsonString),
        );
      }
    } catch (e) {
      print('Error suggesting break placement: $e');
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> generateWeeklySchedule({
    required List<Map<String, dynamic>> weeklyTasks,
    required DateTime startDate,
    Map<String, dynamic>? userPreferences,
    List<Map<String, dynamic>>? recurringEvents,
  }) async {
    if (_aiService == null) {
      throw Exception('AI service not configured. Please set up API keys first.');
    }

    final prompt = '''
주간 작업들을 7일간 최적 분배해주세요:

작업 목록:
${weeklyTasks.map((t) => '${t['title']}: ${t['estimated_duration']}분, 우선순위: ${t['priority']}, 마감일: ${t['due_date'] ?? 'N/A'}').join('\n')}

시작 날짜: ${startDate.toIso8601String().split('T')[0]}

${recurringEvents != null ? '반복 일정:\n${recurringEvents.map((e) => '${e['title']}: ${e['day_of_week']} ${e['time']}').join('\n')}' : ''}

사용자 선호도:
${userPreferences?.entries.map((e) => '${e.key}: ${e.value}').join('\n') ?? '기본 설정 사용'}

다음을 고려하여 주간 일정을 생성해주세요:
1. 마감일이 있는 작업 우선 배치
2. 작업 유형별 최적 요일 고려
3. 업무 부하 균등 분배
4. 반복 일정과의 충돌 방지
5. 주말/평일 작업 성격 구분

주간 일정을 다음 JSON 형태로 제공해주세요:
[
  {
    "task_id": "작업 ID",
    "title": "작업 제목",
    "date": "YYYY-MM-DD",
    "start_time": "HH:MM",
    "end_time": "HH:MM",
    "duration": 소요시간_분,
    "day_of_week": "월/화/수/목/금/토/일",
    "rationale": "이날 배치한 이유"
  }
]

답변은 반드시 유효한 JSON 배열 형태로만 해주세요.
''';

    try {
      final response = await _aiService!.generateResponse(prompt);

      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final List<dynamic> parsed = jsonDecode(jsonString);
        return List<Map<String, dynamic>>.from(parsed);
      }
    } catch (e) {
      print('Error generating weekly schedule: $e');
    }

    return [];
  }

  static void dispose() {
    _aiService = null;
  }
}