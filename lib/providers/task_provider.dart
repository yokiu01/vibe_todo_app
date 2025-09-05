import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/lock_screen_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Task> _tasks = [];
  DateTime _selectedDate = DateTime.now();

  List<Task> get tasks => _tasks;
  DateTime get selectedDate => _selectedDate;

  List<Task> get tasksForSelectedDate {
    return _tasks.where((task) {
      final taskDate = DateTime(task.startTime.year, task.startTime.month, task.startTime.day);
      final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return taskDate.isAtSameMomentAs(selectedDateOnly);
    }).toList();
  }

  List<Task> get currentTasks {
    final now = DateTime.now();
    return _tasks.where((task) {
      return task.startTime.isBefore(now) && 
             task.endTime.isAfter(now) && 
             task.status == TaskStatus.planned;
    }).toList();
  }

  Future<void> loadTasks() async {
    try {
      print('TaskProvider: Loading all tasks from database');
      _tasks = await _databaseService.getAllTasks();
      print('TaskProvider: Loaded ${_tasks.length} tasks');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> loadTasksForDate(DateTime date) async {
    try {
      print('TaskProvider: Loading tasks for date: $date');
      _selectedDate = date;
      // 항상 데이터베이스에서 최신 데이터를 로드
      _tasks = await _databaseService.getAllTasks();
      print('TaskProvider: Loaded ${_tasks.length} tasks for date $date');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks for date: $e');
    }
  }

  Future<void> addTask(Task task) async {
    try {
      print('Adding task: ${task.title}');
      await _databaseService.insertTask(task);
      _tasks.add(task);
      print('Task added to list, total tasks: ${_tasks.length}');
      print('Tasks for selected date: ${tasksForSelectedDate.length}');
      notifyListeners();
      // 위젯 업데이트
      WidgetService.updateWidget(currentTasks);
      // 잠금화면 데이터 업데이트
      _updateLockScreenData();
    } catch (e) {
      debugPrint('Error adding task: $e');
      // 에러가 발생해도 UI에 표시
      _tasks.add(task);
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _databaseService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
        // 위젯 업데이트
        WidgetService.updateWidget(currentTasks);
        // 잠금화면 데이터 업데이트
        _updateLockScreenData();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _databaseService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      // 잠금화면 데이터 업데이트
      _updateLockScreenData();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
      // 위젯 업데이트
      WidgetService.updateWidget(currentTasks);
    } catch (e) {
      debugPrint('Error updating task status: $e');
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> updateTaskScore(String taskId, int score) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = _tasks[taskIndex].copyWith(
          score: score,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateTask(updatedTask);
        _tasks[taskIndex] = updatedTask;
        _updateLockScreenData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task score: $e');
    }
  }

  Future<void> updateTaskRecord(String taskId, String record) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = _tasks[taskIndex].copyWith(
          doRecord: record,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateTask(updatedTask);
        _tasks[taskIndex] = updatedTask;
        _updateLockScreenData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task record: $e');
    }
  }

  // 잠금화면 데이터 업데이트
  Future<void> _updateLockScreenData() async {
    try {
      await LockScreenService.updateLockScreenData(
        todayTasks: tasksForSelectedDate,
        currentTasks: currentTasks,
      );
    } catch (e) {
      debugPrint('Error updating lock screen data: $e');
    }
  }
}
