import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../services/notion_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutineProvider with ChangeNotifier {
  final NotionApiService _notionService = NotionApiService();

  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastAutoGenerationCheck;

  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Routine> get activeRoutines =>
      _routines.where((r) => r.status == 'Active').toList();

  RoutineProvider() {
    _loadLastAutoGenerationCheck();
  }

  /// Load last auto-generation check time from SharedPreferences
  Future<void> _loadLastAutoGenerationCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('last_routine_auto_generation');
      if (timestamp != null) {
        _lastAutoGenerationCheck = DateTime.parse(timestamp);
      }
    } catch (e) {
      debugPrint('Error loading last auto-generation check: $e');
    }
  }

  /// Save last auto-generation check time to SharedPreferences
  Future<void> _saveLastAutoGenerationCheck(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_routine_auto_generation',
        time.toIso8601String(),
      );
      _lastAutoGenerationCheck = time;
    } catch (e) {
      debugPrint('Error saving last auto-generation check: $e');
    }
  }

  /// Fetch all routines from Notion
  Future<void> fetchRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedNotionPages = await _notionService.fetchRoutines();
      _routines = fetchedNotionPages
          .map((notionPage) {
            try {
              return Routine.fromNotion(notionPage as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing routine: $e');
              return null;
            }
          })
          .where((r) => r != null)
          .cast<Routine>()
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch routines: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new routine
  Future<bool> createRoutine(Routine routine) async {
    try {
      final createdPage = await _notionService.createRoutine(routine);
      if (createdPage != null) {
        final createdRoutine = Routine.fromNotion(createdPage as Map<String, dynamic>);
        _routines.add(createdRoutine);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to create routine: $e';
      debugPrint(_error);
      return false;
    }
  }

  /// Update an existing routine
  Future<bool> updateRoutine(String routineId, Routine updatedRoutine) async {
    try {
      final success = await _notionService.updateRoutine(routineId, updatedRoutine);
      if (success) {
        final index = _routines.indexWhere((r) => r.id == routineId);
        if (index != -1) {
          _routines[index] = updatedRoutine;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update routine: $e';
      debugPrint(_error);
      return false;
    }
  }

  /// Delete a routine
  Future<bool> deleteRoutine(String routineId) async {
    try {
      final success = await _notionService.deleteRoutine(routineId);
      if (success) {
        _routines.removeWhere((r) => r.id == routineId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete routine: $e';
      debugPrint(_error);
      return false;
    }
  }

  /// Toggle routine status (Active <-> Paused)
  Future<bool> toggleRoutineStatus(String routineId) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      final newStatus = routine.status == 'Active' ? 'Paused' : 'Active';
      final updatedRoutine = routine.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      return await updateRoutine(routineId, updatedRoutine);
    } catch (e) {
      _error = 'Failed to toggle routine status: $e';
      debugPrint(_error);
      return false;
    }
  }

  /// Check and generate tasks from routines for today
  /// This should be called when the app starts or at midnight
  Future<List<String>> checkAndGenerateRoutineTasks({DateTime? targetDate}) async {
    final date = targetDate ?? DateTime.now();
    final today = DateTime(date.year, date.month, date.day);

    // Check if we already ran today
    if (_lastAutoGenerationCheck != null) {
      final lastCheck = DateTime(
        _lastAutoGenerationCheck!.year,
        _lastAutoGenerationCheck!.month,
        _lastAutoGenerationCheck!.day,
      );
      if (lastCheck.isAtSameMomentAs(today)) {
        debugPrint('Routine task generation already ran today');
        return [];
      }
    }

    final generatedTaskIds = <String>[];

    try {
      // Fetch latest routines
      await fetchRoutines();

      // Get active routines that should run today
      final routinesToRun = _routines.where((routine) {
        return routine.shouldRunToday(date);
      }).toList();

      debugPrint('Found ${routinesToRun.length} routines to generate for ${date.toString()}');

      // Generate tasks for each routine
      for (final routine in routinesToRun) {
        try {
          final taskId = await _generateTaskFromRoutine(routine, date);
          if (taskId != null) {
            generatedTaskIds.add(taskId);

            // Update routine's lastGenerated date
            final updatedRoutine = routine.copyWith(
              lastGenerated: date,
              updatedAt: DateTime.now(),
            );
            await updateRoutine(routine.id, updatedRoutine);
          }
        } catch (e) {
          debugPrint('Error generating task for routine ${routine.title}: $e');
        }
      }

      // Save the check time
      await _saveLastAutoGenerationCheck(date);

      debugPrint('Successfully generated ${generatedTaskIds.length} tasks from routines');
    } catch (e) {
      _error = 'Failed to generate routine tasks: $e';
      debugPrint(_error);
    }

    return generatedTaskIds;
  }

  /// Generate a task from a routine
  Future<String?> _generateTaskFromRoutine(Routine routine, DateTime date) async {
    try {
      // Create task title with routine prefix
      final taskTitle = '📅[루틴] ${routine.title}';

      // Prepare task data
      final taskData = <String, dynamic>{
        'title': taskTitle,
        'description': routine.description ?? '',
        'category': routine.category,
        'scheduled_time': routine.scheduledTime,
        'estimated_minutes': routine.estimatedMinutes,
        'due_date': date.toIso8601String().split('T')[0],
        'status': 'Not started',
        'is_routine': true,
        'routine_id': routine.id,
      };

      // Create task in Notion
      final taskId = await _notionService.createTaskFromRoutine(taskData);

      if (taskId != null) {
        debugPrint('Created task "$taskTitle" from routine');
      }

      return taskId;
    } catch (e) {
      debugPrint('Error in _generateTaskFromRoutine: $e');
      return null;
    }
  }

  /// Get routines for a specific day of the week
  List<Routine> getRoutinesForDay(int weekday) {
    final dayName = _getWeekdayName(weekday);
    return _routines.where((routine) {
      return routine.status == 'Active' &&
          (routine.frequency.contains('매일') ||
              routine.frequency.contains(dayName) ||
              (routine.frequency.contains('주중') &&
                  weekday >= 1 &&
                  weekday <= 5) ||
              (routine.frequency.contains('주말') &&
                  (weekday == 6 || weekday == 7)));
    }).toList();
  }

  /// Get Korean weekday name
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  /// Manually trigger routine task generation (for testing)
  Future<List<String>> manuallyGenerateRoutineTasks({DateTime? date}) async {
    // Reset the last check to allow generation
    _lastAutoGenerationCheck = null;
    return await checkAndGenerateRoutineTasks(targetDate: date);
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh routines
  Future<void> refresh() async {
    await fetchRoutines();
  }
}
