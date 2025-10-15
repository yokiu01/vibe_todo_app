import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/ai_clarification_service.dart';
import '../services/ai_scheduler_service.dart';

class AIProvider with ChangeNotifier {
  bool _isConfigured = false;
  bool _isLoading = false;
  String? _error;
  AIConfig? _config;
  bool _isClarifying = false;
  Map<String, dynamic>? _lastClarification;
  bool _isScheduling = false;
  List<Map<String, dynamic>> _generatedSchedule = [];

  bool get isConfigured => _isConfigured;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AIConfig? get config => _config;
  bool get isClarifying => _isClarifying;
  Map<String, dynamic>? get lastClarification => _lastClarification;
  bool get isScheduling => _isScheduling;
  List<Map<String, dynamic>> get generatedSchedule => _generatedSchedule;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _config = await AIService.getConfig();
      _isConfigured = await AIService.hasValidConfig();

      if (_isConfigured) {
        await AIClarificationService.initialize();
        await AISchedulerService.initialize();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveConfig({
    required AIServiceProvider provider,
    required String apiKey,
    required String model,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final config = AIConfig(
        provider: provider,
        apiKey: apiKey,
        model: model,
      );

      final success = await AIService.saveConfig(config);
      if (success) {
        _config = config;
        _isConfigured = true;
        await AIClarificationService.initialize();
        await AISchedulerService.initialize();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AIService.clearConfig();
      _config = null;
      _isConfigured = false;
      AIClarificationService.dispose();
      AISchedulerService.dispose();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clarification methods
  Future<Map<String, dynamic>?> clarifyTask({
    required String title,
    String? description,
    String? category,
    String? priority,
    String? dueDate,
  }) async {
    if (!_isConfigured) {
      _error = 'AI service not configured. Please set up API keys first.';
      notifyListeners();
      return null;
    }

    _isClarifying = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AIClarificationService.clarifyTask(
        title: title,
        description: description,
        category: category,
        priority: priority,
        dueDate: dueDate,
      );

      _lastClarification = result;
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isClarifying = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String partialInput,
    String? context,
  }) async {
    if (!_isConfigured) {
      return [];
    }

    try {
      return await AIClarificationService.generateSuggestions(
        partialInput: partialInput,
        context: context,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Map<String, dynamic>?> enhanceTaskWithContext({
    required Map<String, dynamic> task,
    required List<Map<String, dynamic>> relatedTasks,
    Map<String, dynamic>? userHabits,
  }) async {
    if (!_isConfigured) {
      return null;
    }

    try {
      return await AIClarificationService.enhanceTaskWithContext(
        task: task,
        relatedTasks: relatedTasks,
        userHabits: userHabits,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Scheduling methods
  Future<List<Map<String, dynamic>>> generateDailySchedule({
    required List<Map<String, dynamic>> tasks,
    required DateTime targetDate,
    Map<String, dynamic>? userPreferences,
    List<Map<String, dynamic>>? existingEvents,
  }) async {
    if (!_isConfigured) {
      _error = 'AI service not configured. Please set up API keys first.';
      notifyListeners();
      return [];
    }

    _isScheduling = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = await AISchedulerService.generateDailySchedule(
        tasks: tasks,
        targetDate: targetDate,
        userPreferences: userPreferences,
        existingEvents: existingEvents,
      );

      _generatedSchedule = schedule;
      return schedule;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isScheduling = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> optimizeSchedule({
    required List<Map<String, dynamic>> currentSchedule,
    required List<Map<String, dynamic>> completedTasks,
    Map<String, dynamic>? learningData,
  }) async {
    if (!_isConfigured) {
      return currentSchedule;
    }

    _isScheduling = true;
    _error = null;
    notifyListeners();

    try {
      final optimized = await AISchedulerService.optimizeSchedule(
        currentSchedule: currentSchedule,
        completedTasks: completedTasks,
        learningData: learningData,
      );

      _generatedSchedule = optimized;
      return optimized;
    } catch (e) {
      _error = e.toString();
      return currentSchedule;
    } finally {
      _isScheduling = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> suggestBreakPlacement({
    required List<Map<String, dynamic>> currentSchedule,
    required int totalWorkMinutes,
    Map<String, dynamic>? energyPattern,
  }) async {
    if (!_isConfigured) {
      return null;
    }

    try {
      return await AISchedulerService.suggestBreakPlacement(
        currentSchedule: currentSchedule,
        totalWorkMinutes: totalWorkMinutes,
        energyPattern: energyPattern,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> generateWeeklySchedule({
    required List<Map<String, dynamic>> weeklyTasks,
    required DateTime startDate,
    Map<String, dynamic>? userPreferences,
    List<Map<String, dynamic>>? recurringEvents,
  }) async {
    if (!_isConfigured) {
      _error = 'AI service not configured. Please set up API keys first.';
      notifyListeners();
      return [];
    }

    _isScheduling = true;
    _error = null;
    notifyListeners();

    try {
      return await AISchedulerService.generateWeeklySchedule(
        weeklyTasks: weeklyTasks,
        startDate: startDate,
        userPreferences: userPreferences,
        recurringEvents: recurringEvents,
      );
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isScheduling = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearLastClarification() {
    _lastClarification = null;
    notifyListeners();
  }

  void clearGeneratedSchedule() {
    _generatedSchedule = [];
    notifyListeners();
  }

  Future<void> recordClarificationFeedback({
    required String taskId,
    required bool wasHelpful,
    String? feedback,
    Map<String, dynamic>? improvements,
  }) async {
    try {
      final feedbackData = {
        'task_id': taskId,
        'was_helpful': wasHelpful,
        'feedback': feedback,
        'improvements': improvements,
        'timestamp': DateTime.now().toIso8601String(),
      };
      debugPrint('AI Clarification Feedback: $feedbackData');
    } catch (e) {
      debugPrint('Error recording clarification feedback: $e');
    }
  }

  Future<void> recordSchedulingFeedback({
    required String scheduleId,
    required bool wasFollowed,
    Map<String, dynamic>? actualTimes,
    String? feedback,
  }) async {
    try {
      final feedbackData = {
        'schedule_id': scheduleId,
        'was_followed': wasFollowed,
        'actual_times': actualTimes,
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      };
      debugPrint('AI Scheduling Feedback: $feedbackData');
    } catch (e) {
      debugPrint('Error recording scheduling feedback: $e');
    }
  }
}