import 'dart:convert';
import 'ai_service.dart';
import 'openai_service.dart';
import 'perplexity_service.dart';

class AIClarificationService {
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
        case AIServiceProvider.perplexity:
          _aiService = PerplexityService(
            apiKey: config.apiKey,
            model: config.model.isNotEmpty ? config.model : 'llama-3.1-sonar-large-128k-online',
          );
          break;
      }
    }
  }

  static bool get isConfigured => _aiService != null;

  static Future<Map<String, dynamic>?> clarifyTask({
    required String title,
    String? description,
    String? category,
    String? priority,
    String? dueDate,
  }) async {
    if (_aiService == null) {
      throw Exception('AI service not configured. Please set up API keys first.');
    }

    final taskDescription = [
      'Title: $title',
      if (description != null && description.isNotEmpty) 'Description: $description',
      if (category != null && category.isNotEmpty) 'Category: $category',
      if (priority != null && priority.isNotEmpty) 'Priority: $priority',
      if (dueDate != null && dueDate.isNotEmpty) 'Due Date: $dueDate',
    ].join('\n');

    try {
      final result = await _aiService!.clarifyTask(
        taskDescription,
        category: category,
        dueDate: dueDate,
        priority: priority,
      );

      return {
        'original_title': title,
        'original_description': description,
        'clarified_title': result['clarified_title'],
        'description': result['description'],
        'estimated_duration': result['estimated_duration'],
        'priority': result['priority'],
        'category': result['category'],
        'suggested_time': result['suggested_time'],
        'breakdown': result['breakdown'] ?? [],
        'prerequisites': result['prerequisites'] ?? [],
        'clarified_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to clarify task: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> generateSuggestions({
    required String partialInput,
    String? context,
  }) async {
    if (_aiService == null) {
      return [];
    }

    final prompt = '''
사용자가 "${partialInput}"라고 입력했습니다.
${context != null ? '컨텍스트: $context' : ''}

이 입력을 바탕으로 3-5개의 구체적인 작업 제안을 해주세요.
각 제안은 실행 가능하고 명확해야 합니다.

다음 형태의 JSON 배열로 응답해주세요:
[
  {
    "title": "제안된 작업 제목",
    "description": "작업 설명",
    "estimated_duration": 예상_소요시간_분,
    "category": "카테고리",
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
      print('Error generating suggestions: $e');
    }

    return [];
  }

  static Future<Map<String, dynamic>?> enhanceTaskWithContext({
    required Map<String, dynamic> task,
    required List<Map<String, dynamic>> relatedTasks,
    Map<String, dynamic>? userHabits,
  }) async {
    if (_aiService == null) {
      return null;
    }

    final prompt = '''
다음 작업을 관련 작업들과 사용자 습관을 고려하여 개선해주세요:

현재 작업:
${task['title']} - ${task['description'] ?? ''}

관련 작업들:
${relatedTasks.map((t) => '- ${t['title']}: ${t['status'] ?? 'pending'}').join('\n')}

${userHabits != null ? '사용자 습관:\n${userHabits.entries.map((e) => '${e.key}: ${e.value}').join('\n')}' : ''}

다음 정보를 JSON으로 제공해주세요:
{
  "enhanced_title": "개선된 제목",
  "enhanced_description": "개선된 설명",
  "dependencies": ["의존성 작업들"],
  "related_tasks": ["연관 작업들"],
  "optimal_time": "최적 실행 시간",
  "preparation_steps": ["사전 준비 단계들"],
  "success_criteria": ["성공 기준들"],
  "potential_obstacles": ["예상 장애물들"],
  "tips": ["실행 팁들"]
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
      print('Error enhancing task: $e');
    }

    return null;
  }

  static void dispose() {
    _aiService = null;
  }
}