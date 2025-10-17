import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../models/item.dart';
import '../services/database_service.dart';
import '../services/notion_api_service.dart';
import '../utils/helpers.dart';

class ReviewProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotionApiService _notionService = NotionApiService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;

  // Archive review data
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _completedTasks = [];
  List<Map<String, dynamic>> _diaryEntries = [];
  Map<String, int> _projectStats = {};
  int _totalCompletedTasks = 0;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Archive review getters
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<Map<String, dynamic>> get completedTasks => _completedTasks;
  List<Map<String, dynamic>> get diaryEntries => _diaryEntries;
  Map<String, int> get projectStats => _projectStats;
  int get totalCompletedTasks => _totalCompletedTasks;
  String? get topProject => _projectStats.isEmpty
      ? null
      : _projectStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  Future<void> loadReviews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _databaseService.getAllReviews();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Review? getTodaysReview(DateTime date, ReviewType type) {
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      return _reviews.firstWhere((review) => 
        review.reviewDate.toIso8601String().split('T')[0] == dateStr &&
        review.type == type
      );
    } catch (e) {
      return null;
    }
  }

  Future<Review> createReview({
    required DateTime reviewDate,
    required ReviewType type,
    String? notes,
  }) async {
    try {
      final review = Review(
        id: Helpers.generateId(),
        reviewDate: reviewDate,
        type: type,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final createdReview = await _databaseService.createReview(review);
      _reviews.add(createdReview);
      notifyListeners();
      return createdReview;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Review> updateReview(String id, Map<String, dynamic> updates) async {
    try {
      final updatedReview = await _databaseService.updateReview(id, updates);
      final index = _reviews.indexWhere((review) => review.id == id);
      if (index != -1) {
        _reviews[index] = updatedReview;
        notifyListeners();
      }
      return updatedReview;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Review> toggleReviewStep(String id, String stepKey) async {
    try {
      final review = _reviews.firstWhere((r) => r.id == id);
      final currentValue = review.toMap()[stepKey] == 1;
      
      return await updateReview(id, {stepKey: !currentValue ? 1 : 0});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Review> getOrCreateTodaysReview(DateTime date, ReviewType type) async {
    final existingReview = getTodaysReview(date, type);
    if (existingReview != null) {
      return existingReview;
    }

    return await createReview(
      reviewDate: date,
      type: type,
    );
  }

  List<ReviewStep> getReviewSteps(ReviewType type) {
    switch (type) {
      case ReviewType.daily:
        return [
          ReviewStep(
            key: 'empty_inbox_completed',
            title: '수집함 확인',
            description: '오늘 수집된 항목들을 확인했나요?',
          ),
          ReviewStep(
            key: 'next_actions_reviewed',
            title: '오늘 할일 검토',
            description: '오늘 완료한 일과 미완료 일을 정리했나요?',
          ),
          ReviewStep(
            key: 'calendar_planned',
            title: '내일 계획',
            description: '내일 할 일을 계획했나요?',
          ),
        ];
      case ReviewType.weekly:
        return [
          ReviewStep(
            key: 'empty_inbox_completed',
            title: '수집함 정리',
            description: '모든 수집 항목을 명료화했나요?',
          ),
          ReviewStep(
            key: 'clarify_completed',
            title: '미처리 할일 명료화',
            description: '명료화되지 않은 할일들을 정리했나요?',
          ),
          ReviewStep(
            key: 'mind_sweep_completed',
            title: '머릿속 생각 비우기',
            description: '떠오르는 모든 생각을 수집함에 기록했나요?',
          ),
          ReviewStep(
            key: 'next_actions_reviewed',
            title: '다음 행동 점검',
            description: '다음 행동 목록을 검토하고 갱신했나요?',
          ),
          ReviewStep(
            key: 'projects_updated',
            title: '프로젝트 상태 갱신',
            description: '진행 중인 프로젝트 상태를 확인했나요?',
          ),
          ReviewStep(
            key: 'goals_checked',
            title: '목표 달성도 확인',
            description: '이번 주/월 목표 달성도를 점검했나요?',
          ),
          ReviewStep(
            key: 'calendar_planned',
            title: '다음 주 계획',
            description: '다음 주 일정을 달력에 계획했나요?',
          ),
          ReviewStep(
            key: 'someday_reviewed',
            title: '언젠가 목록 검토',
            description: '언젠가 할 일 목록을 살펴봤나요?',
          ),
          ReviewStep(
            key: 'new_goals_added',
            title: '새로운 목표 추가',
            description: '새로운 목표나 프로젝트를 추가했나요?',
          ),
        ];
      case ReviewType.monthly:
        return [
          ReviewStep(
            key: 'goals_checked',
            title: '월간 목표 점검',
            description: '이번 달 목표 달성도를 확인했나요?',
          ),
          ReviewStep(
            key: 'projects_updated',
            title: '프로젝트 전체 검토',
            description: '모든 프로젝트의 우선순위를 재평가했나요?',
          ),
          ReviewStep(
            key: 'someday_reviewed',
            title: '장기 계획 검토',
            description: '장기적인 목표와 비전을 검토했나요?',
          ),
        ];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== Archive Review Methods ====================

  /// Set date range for archive review
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  /// Set predefined date range (This Week, Last Week, This Month, etc.)
  void setPredefinedRange(String rangeType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (rangeType) {
      case 'today':
        _startDate = today;
        _endDate = today.add(const Duration(days: 1));
        break;
      case 'this_week':
        final weekday = today.weekday;
        _startDate = today.subtract(Duration(days: weekday - 1)); // Monday
        _endDate = today.add(Duration(days: 7 - weekday + 1)); // Sunday
        break;
      case 'last_week':
        final weekday = today.weekday;
        final lastMonday = today.subtract(Duration(days: weekday + 6));
        _startDate = lastMonday;
        _endDate = lastMonday.add(const Duration(days: 7));
        break;
      case 'this_month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last_month':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      default:
        _startDate = today.subtract(const Duration(days: 7));
        _endDate = today;
    }
    notifyListeners();
  }

  /// Fetch archive review data (Do + See)
  Future<void> fetchArchiveReviewData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch completed tasks from local database
      await _fetchCompletedTasks();

      // Fetch PDS diary entries (See section)
      await _fetchDiaryEntries();

      // Calculate statistics
      _calculateStatistics();

      _error = null;
    } catch (e) {
      _error = 'Failed to fetch archive data: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch completed tasks within date range
  Future<void> _fetchCompletedTasks() async {
    try {
      // Get all completed items from local database
      final allItems = await _databaseService.getAllItems();

      // Filter by date range and completion status
      _completedTasks = allItems
          .where((item) {
            if (item.status != ItemStatus.completed) return false;
            if (item.completionDate == null) return false;

            final completedDate = item.completionDate!;
            return completedDate.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
                   completedDate.isBefore(_endDate.add(const Duration(days: 1)));
          })
          .map((item) => item.toMap())
          .toList();

      debugPrint('Fetched ${_completedTasks.length} completed tasks');
    } catch (e) {
      debugPrint('Error fetching completed tasks: $e');
      _completedTasks = [];
    }
  }

  /// Fetch PDS diary entries within date range
  Future<void> _fetchDiaryEntries() async {
    try {
      // Query PDS database for diary entries in date range
      final startDateStr = _startDate.toIso8601String().split('T')[0];
      final endDateStr = _endDate.toIso8601String().split('T')[0];

      // Get all PDS pages
      final allPages = await _notionService.queryDatabase(
        NotionApiService.PDS_DB_ID,
        null,
      );

      // Filter by date range
      _diaryEntries = allPages.where((page) {
        try {
          final properties = page['properties'] as Map<String, dynamic>;
          final nameProperty = properties['이름'] as Map<String, dynamic>?;
          if (nameProperty == null) return false;

          final titleArray = nameProperty['title'] as List<dynamic>?;
          if (titleArray == null || titleArray.isEmpty) return false;

          final dateTitle = titleArray.first['plain_text'] as String?;
          if (dateTitle == null) return false;

          // Parse date from title (format: YYYY.MM.DD)
          final parts = dateTitle.split('.');
          if (parts.length != 3) return false;

          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);

          if (year == null || month == null || day == null) return false;

          final pageDate = DateTime(year, month, day);
          return pageDate.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
                 pageDate.isBefore(_endDate.add(const Duration(days: 1)));
        } catch (e) {
          debugPrint('Error parsing PDS page: $e');
          return false;
        }
      }).toList();

      // Sort by date (newest first)
      _diaryEntries.sort((a, b) {
        try {
          final aTitle = (a['properties']['이름']['title'][0]['plain_text'] as String);
          final bTitle = (b['properties']['이름']['title'][0]['plain_text'] as String);
          return bTitle.compareTo(aTitle); // Descending order
        } catch (e) {
          return 0;
        }
      });

      debugPrint('Fetched ${_diaryEntries.length} diary entries');
    } catch (e) {
      debugPrint('Error fetching diary entries: $e');
      _diaryEntries = [];
    }
  }

  /// Calculate statistics from completed tasks
  void _calculateStatistics() {
    _totalCompletedTasks = _completedTasks.length;
    _projectStats = {};

    for (final taskMap in _completedTasks) {
      final category = taskMap['category'] as String? ?? '기타';
      _projectStats[category] = (_projectStats[category] ?? 0) + 1;
    }

    debugPrint('Statistics: $_totalCompletedTasks tasks, ${_projectStats.length} projects');
  }

  /// Get diary content for a specific PDS page
  Future<String> getDiaryContent(String pageId) async {
    try {
      final blocks = await _notionService.getBlockChildren(pageId);
      final seeBlocks = <String>[];
      bool inSeeSection = false;

      for (final block in blocks) {
        final type = block['type'] as String?;

        // Check if we're entering See section
        if (type == 'heading_2' || type == 'heading_1') {
          final heading = block[type]?['rich_text'] as List<dynamic>?;
          if (heading != null && heading.isNotEmpty) {
            final text = heading.first['plain_text'] as String?;
            if (text != null && text.contains('See')) {
              inSeeSection = true;
              continue;
            } else {
              inSeeSection = false;
            }
          }
        }

        // Collect content if in See section
        if (inSeeSection && type == 'paragraph') {
          final paragraph = block['paragraph']?['rich_text'] as List<dynamic>?;
          if (paragraph != null && paragraph.isNotEmpty) {
            final text = paragraph.first['plain_text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              seeBlocks.add(text.trim());
            }
          }
        }
      }

      return seeBlocks.join('\n\n');
    } catch (e) {
      debugPrint('Error getting diary content: $e');
      return '';
    }
  }
}

class ReviewStep {
  final String key;
  final String title;
  final String description;

  ReviewStep({
    required this.key,
    required this.title,
    required this.description,
  });
}



