import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingPhase {
  welcome,
  notionConnection,
  collection,
  clarification,
  planning,
  execution,
  completion,
  finished,
}

class OnboardingProvider with ChangeNotifier {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingPhaseKey = 'onboarding_phase';

  bool _isOnboardingCompleted = false;
  bool _isOnboardingActive = false;
  OnboardingPhase _currentPhase = OnboardingPhase.welcome;
  String? _sampleTaskId; // ID of the sample task created during onboarding

  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isOnboardingActive => _isOnboardingActive;
  OnboardingPhase get currentPhase => _currentPhase;
  String? get sampleTaskId => _sampleTaskId;

  OnboardingProvider() {
    _loadOnboardingStatus();
  }

  /// Load onboarding status from SharedPreferences
  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
      final phaseIndex = prefs.getInt(_onboardingPhaseKey) ?? 0;
      _currentPhase = OnboardingPhase.values[phaseIndex];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading onboarding status: $e');
    }
  }

  /// Start the onboarding flow
  Future<void> startOnboarding() async {
    _isOnboardingActive = true;
    _currentPhase = OnboardingPhase.welcome;
    await _saveCurrentPhase();
    notifyListeners();
  }

  /// Move to the next phase
  Future<void> nextPhase() async {
    final currentIndex = _currentPhase.index;
    if (currentIndex < OnboardingPhase.values.length - 1) {
      _currentPhase = OnboardingPhase.values[currentIndex + 1];
      await _saveCurrentPhase();
      notifyListeners();

      // Auto-complete if we reach the finished phase
      if (_currentPhase == OnboardingPhase.finished) {
        await completeOnboarding();
      }
    }
  }

  /// Move to a specific phase
  Future<void> goToPhase(OnboardingPhase phase) async {
    _currentPhase = phase;
    await _saveCurrentPhase();
    notifyListeners();
  }

  /// Save the current phase to SharedPreferences
  Future<void> _saveCurrentPhase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_onboardingPhaseKey, _currentPhase.index);
    } catch (e) {
      debugPrint('Error saving onboarding phase: $e');
    }
  }

  /// Complete the onboarding flow
  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    _isOnboardingActive = false;
    _currentPhase = OnboardingPhase.finished;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }

    notifyListeners();
  }

  /// Skip the onboarding (can be called from skip button)
  Future<void> skipOnboarding() async {
    await completeOnboarding();
  }

  /// Reset onboarding (for testing or user request)
  Future<void> resetOnboarding() async {
    _isOnboardingCompleted = false;
    _isOnboardingActive = false;
    _currentPhase = OnboardingPhase.welcome;
    _sampleTaskId = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, false);
      await prefs.setInt(_onboardingPhaseKey, 0);
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }

    notifyListeners();
  }

  /// Set the sample task ID created during onboarding
  void setSampleTaskId(String taskId) {
    _sampleTaskId = taskId;
    notifyListeners();
  }

  /// Check if a task is the sample task
  bool isSampleTask(String taskId) {
    return _sampleTaskId == taskId;
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (_currentPhase == OnboardingPhase.finished) return 1.0;
    return _currentPhase.index / (OnboardingPhase.values.length - 1);
  }

  /// Get phase description for UI
  String getPhaseDescription(OnboardingPhase phase) {
    switch (phase) {
      case OnboardingPhase.welcome:
        return '환영합니다!';
      case OnboardingPhase.notionConnection:
        return 'Notion 연동';
      case OnboardingPhase.collection:
        return '수집하기';
      case OnboardingPhase.clarification:
        return '명료화하기';
      case OnboardingPhase.planning:
        return '계획하기';
      case OnboardingPhase.execution:
        return '실행하기';
      case OnboardingPhase.completion:
        return '완료!';
      case OnboardingPhase.finished:
        return '완료됨';
    }
  }
}
