import 'package:shared_preferences/shared_preferences.dart';

enum AIServiceProvider {
  openai,
  claude,
}

class AIConfig {
  final AIServiceProvider provider;
  final String apiKey;
  final String model;

  AIConfig({
    required this.provider,
    required this.apiKey,
    required this.model,
  });

  factory AIConfig.fromMap(Map<String, dynamic> map) {
    return AIConfig(
      provider: AIServiceProvider.values.firstWhere(
        (e) => e.toString() == map['provider'],
        orElse: () => AIServiceProvider.openai,
      ),
      apiKey: map['apiKey'] ?? '',
      model: map['model'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.toString(),
      'apiKey': apiKey,
      'model': model,
    };
  }
}

abstract class AIService {
  static const String _configKey = 'ai_config';

  static Future<AIConfig?> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configString = prefs.getString(_configKey);

    if (configString == null) return null;

    final configMap = Map<String, dynamic>.from(
      Uri.splitQueryString(configString),
    );

    return AIConfig.fromMap(configMap);
  }

  static Future<bool> saveConfig(AIConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configMap = config.toMap();
    final configString = Uri(queryParameters: configMap).query;

    return await prefs.setString(_configKey, configString);
  }

  static Future<bool> hasValidConfig() async {
    final config = await getConfig();
    return config != null && config.apiKey.isNotEmpty;
  }

  static Future<bool> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_configKey);
  }

  Future<String> generateResponse(String prompt, {Map<String, dynamic>? context});

  Future<Map<String, dynamic>> clarifyTask(String taskDescription, {
    String? category,
    String? dueDate,
    String? priority,
  });

  Future<List<Map<String, dynamic>>> generateDailySchedule(
    List<Map<String, dynamic>> tasks,
    Map<String, dynamic> userPreferences,
  );
}