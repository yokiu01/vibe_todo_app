import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class ReviewProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

