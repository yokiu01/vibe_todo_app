import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/notion_task.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/lock_screen_service.dart';
import '../services/notion_api_service.dart';
import '../services/notion_oauth_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotionApiService _notionApi = NotionApiService();
  final NotionOAuthService _oauthService = NotionOAuthService();
  
  List<Task> _tasks = [];
  DateTime _selectedDate = DateTime.now();
  bool _isNotionAuthenticated = false;
  bool _isSyncing = false;

  List<Task> get tasks => _tasks;
  DateTime get selectedDate => _selectedDate;
  bool get isNotionAuthenticated => _isNotionAuthenticated;
  bool get isSyncing => _isSyncing;

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

  // Notion 인증 상태 확인
  Future<void> checkNotionAuthentication() async {
    _isNotionAuthenticated = await _oauthService.isAuthenticated();
    notifyListeners();
  }

  // Notion 로그인
  Future<bool> loginToNotion() async {
    try {
      final result = await _oauthService.authenticate();
      if (result != null) {
        await checkNotionAuthentication();
        return _isNotionAuthenticated;
      }
      return false;
    } catch (e) {
      debugPrint('Notion login error: $e');
      return false;
    }
  }

  // Notion 로그아웃
  Future<void> logoutFromNotion() async {
    await _oauthService.clearTokens();
    _isNotionAuthenticated = false;
    notifyListeners();
  }

  // Notion과 동기화
  Future<void> syncWithNotion() async {
    if (!_isNotionAuthenticated) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      // 로컬 작업을 Notion으로 동기화
      for (final task in _tasks) {
        await _syncTaskToNotion(task);
      }

      // Notion에서 최신 데이터 가져오기
      await _loadTasksFromNotion();

      notifyListeners();
    } catch (e) {
      debugPrint('Sync with Notion error: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  // 개별 작업을 Notion으로 동기화
  Future<void> _syncTaskToNotion(Task task) async {
    try {
      // Notion에 해당 작업이 이미 있는지 확인
      final existingTasks = await _notionApi.queryDatabase(
        NotionApiService.CLARIFY_DB_ID,
        {
          'property': 'title',
          'title': {
            'equals': task.title,
          }
        },
      );

      if (existingTasks.isEmpty) {
        // 새 작업 생성
        await _notionApi.createClarifyItem(
          task.title,
          description: task.description,
          status: _convertTaskStatusToNotion(task.status),
          dueDate: task.endTime,
        );
      } else {
        // 기존 작업 업데이트
        final notionTask = NotionTask.fromNotion(existingTasks.first);
        await _notionApi.updatePage(notionTask.id, {
          'status': {
            'select': {
              'name': _convertTaskStatusToNotion(task.status),
            }
          },
          'completed': {
            'checkbox': task.status == TaskStatus.completed,
          },
        });
      }
    } catch (e) {
      debugPrint('Error syncing task to Notion: $e');
    }
  }

  // Notion에서 작업 로드
  Future<void> _loadTasksFromNotion() async {
    try {
      final items = await _notionApi.queryDatabase(
        NotionApiService.CLARIFY_DB_ID,
        null,
      );

      final notionTasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      // Notion 작업을 로컬 Task로 변환하여 추가
      for (final notionTask in notionTasks) {
        final existingTask = _tasks.firstWhere(
          (task) => task.title == notionTask.title,
          orElse: () => Task.empty(),
        );

        if (existingTask.id.isEmpty) {
          // 새 작업으로 추가
          final newTask = Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: notionTask.title,
            description: notionTask.description ?? '',
            startTime: notionTask.dueDate ?? DateTime.now(),
            endTime: notionTask.dueDate ?? DateTime.now().add(const Duration(hours: 1)),
            status: _convertNotionStatusToTask(notionTask.status),
            priority: 3,
            category: 'work',
            color: '#2563EB',
            score: 0,
            doRecord: '',
            createdAt: notionTask.createdAt,
            updatedAt: notionTask.updatedAt,
          );
          
          await _databaseService.insertTask(newTask);
          _tasks.add(newTask);
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks from Notion: $e');
    }
  }

  // Notion 작업 생성
  Future<void> createNotionTask(String title, {String? description}) async {
    if (!_isNotionAuthenticated) return;

    try {
      await _notionApi.createTodo(title, description: description);
      await _loadTasksFromNotion();
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating Notion task: $e');
    }
  }

  // Notion 작업 업데이트
  Future<void> updateNotionTask(String pageId, Map<String, dynamic> updates) async {
    if (!_isNotionAuthenticated) return;

    try {
      await _notionApi.updatePage(pageId, updates);
      await _loadTasksFromNotion();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating Notion task: $e');
    }
  }

  // Task 상태를 Notion 상태로 변환
  String _convertTaskStatusToNotion(TaskStatus status) {
    switch (status) {
      case TaskStatus.planned:
        return '진행중';
      case TaskStatus.completed:
        return '완료';
      case TaskStatus.cancelled:
        return '취소';
      default:
        return '대기';
    }
  }

  // Notion 상태를 Task 상태로 변환
  TaskStatus _convertNotionStatusToTask(String? status) {
    switch (status) {
      case '진행중':
        return TaskStatus.planned;
      case '완료':
        return TaskStatus.completed;
      case '취소':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.planned;
    }
  }

  // setState 메서드 추가 (상태 업데이트용)
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
