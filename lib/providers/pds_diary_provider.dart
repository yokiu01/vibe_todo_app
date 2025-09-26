import 'package:flutter/foundation.dart';
import '../models/pds_plan.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class PDSDiaryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<PDSPlan> _pdsPlans = [];
  bool _isLoading = false;
  String? _error;

  List<PDSPlan> get pdsPlans => _pdsPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPDSPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pdsPlans = await _databaseService.getAllPDSPlans();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 락 스크린용 최적화된 데이터 로딩
  Future<void> loadPDSPlansForLockScreen() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 오늘 날짜의 데이터만 빠르게 로드
      final today = DateTime.now();
      _pdsPlans = await _databaseService.getPDSPlansForDate(today);
      print('Lock screen data loaded: ${_pdsPlans.length} plans');
    } catch (e) {
      _error = e.toString();
      print('Error loading lock screen data: $e');
      // 오류 시 빈 리스트로 설정
      _pdsPlans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PDSPlan? getPDSPlan(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      return _pdsPlans.firstWhere((plan) => 
        plan.date.toIso8601String().split('T')[0] == dateStr
      );
    } catch (e) {
      return null;
    }
  }

  Future<PDSPlan> createOrUpdatePDSPlan({
    required DateTime date,
    Map<String, String>? freeformPlans,
    Map<String, String>? actualActivities,
    String? seeNotes,
  }) async {
    try {
      final existingPlan = getPDSPlan(date);

      print('PDSDiaryProvider: createOrUpdatePDSPlan - 기존 계획: ${existingPlan != null}');

      if (existingPlan != null) {
        print('PDSDiaryProvider: 기존 계획 업데이트');

        final updatedPlan = await _databaseService.updatePDSPlan(existingPlan.id, {
          'freeform_plans': freeformPlans != null ? _mapToJson(freeformPlans) : existingPlan.freeformPlans != null ? _mapToJson(existingPlan.freeformPlans!) : null,
          'actual_activities': actualActivities != null ? _mapToJson(actualActivities) : existingPlan.actualActivities != null ? _mapToJson(existingPlan.actualActivities!) : null,
          'see_notes': seeNotes ?? existingPlan.seeNotes,
        });

        final index = _pdsPlans.indexWhere((plan) => plan.id == existingPlan.id);
        if (index != -1) {
          _pdsPlans[index] = updatedPlan;
          print('PDSDiaryProvider: 로컬 데이터 업데이트 완료');
        } else {
          print('PDSDiaryProvider: 인덱스를 찾을 수 없음, 리스트에 추가');
          _pdsPlans.add(updatedPlan);
        }

        notifyListeners();
        print('PDSDiaryProvider: notifyListeners 호출');
        return updatedPlan;
      } else {
        print('PDSDiaryProvider: 새로운 계획 생성');

        final newPlan = PDSPlan(
          id: Helpers.generateId(),
          date: date,
          freeformPlans: freeformPlans,
          actualActivities: actualActivities,
          seeNotes: seeNotes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdPlan = await _databaseService.createPDSPlan(newPlan);
        _pdsPlans.add(createdPlan);
        notifyListeners();
        print('PDSDiaryProvider: 새 계획 생성 완료');
        return createdPlan;
      }
    } catch (e) {
      print('PDSDiaryProvider: createOrUpdatePDSPlan 오류: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFreeformPlan(DateTime date, String timeKey, String content) async {
    final currentPlan = getPDSPlan(date);
    Map<String, String> freeformPlans = currentPlan?.freeformPlans ?? {};
    freeformPlans[timeKey] = content;
    
    await createOrUpdatePDSPlan(
      date: date,
      freeformPlans: freeformPlans,
    );
  }

  Future<void> updateActualActivity(DateTime date, String timeKey, String content) async {
    final currentPlan = getPDSPlan(date);
    Map<String, String> actualActivities = currentPlan?.actualActivities ?? {};
    actualActivities[timeKey] = content;
    
    await createOrUpdatePDSPlan(
      date: date,
      actualActivities: actualActivities,
    );
  }

  Future<void> updateSeeNotes(DateTime date, String notes) async {
    await createOrUpdatePDSPlan(
      date: date,
      seeNotes: notes,
    );
  }

  String _mapToJson(Map<String, String> map) {
    return map.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, String> _jsonToMap(String json) {
    if (json.isEmpty) return {};
    final Map<String, String> result = {};

    // 기존 형식(콜론과 파이프) 지원을 위한 migration
    if (json.contains('|') && json.contains(':')) {
      final entries = json.split('|');
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length >= 2) {
          result[parts[0]] = parts.sublist(1).join(':');
        }
      }
    } else {
      // 새로운 형식(등호와 앰퍼샌드)
      final entries = json.split('&');
      for (final entry in entries) {
        final parts = entry.split('=');
        if (parts.length >= 2) {
          result[parts[0]] = parts.sublist(1).join('=');
        }
      }
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updatePDSPlan(PDSPlan plan) async {
    try {
      print('PDSDiaryProvider: updatePDSPlan 호출 - ${plan.id}');
      
      // 데이터베이스에서 업데이트
      final updatedPlan = await _databaseService.updatePDSPlan(plan.id, plan.toMap());
      
      // 로컬 리스트에서 해당 계획 찾아서 업데이트
      final index = _pdsPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _pdsPlans[index] = updatedPlan;
        print('PDSDiaryProvider: 로컬 데이터 업데이트 완료');
      } else {
        print('PDSDiaryProvider: 해당 계획을 찾을 수 없음, 새로 추가');
        _pdsPlans.add(updatedPlan);
      }
      
      notifyListeners();
      print('PDSDiaryProvider: updatePDSPlan 완료');
    } catch (e) {
      print('PDSDiaryProvider: updatePDSPlan 오류: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveFreeformPlan(DateTime date, String timeSlot, String content) async {
    try {
      print('PDSDiaryProvider: saveFreeformPlan 호출 - ${date.toIso8601String().split('T')[0]} $timeSlot: $content');

      final existingPlan = getPDSPlan(date);
      Map<String, String> freeformPlans = {};

      if (existingPlan != null && existingPlan.freeformPlans != null) {
        freeformPlans = Map<String, String>.from(existingPlan.freeformPlans!);
      }

      if (content.trim().isEmpty) {
        freeformPlans.remove(timeSlot);
      } else {
        freeformPlans[timeSlot] = content.trim();
      }

      print('PDSDiaryProvider: 업데이트할 freeformPlans: $freeformPlans');

      final updatedPlan = await createOrUpdatePDSPlan(
        date: date,
        freeformPlans: freeformPlans,
        actualActivities: existingPlan?.actualActivities,
        seeNotes: existingPlan?.seeNotes,
      );

      print('PDSDiaryProvider: PDS 계획 저장 완료');
      print('PDSDiaryProvider: 저장된 계획 데이터: ${updatedPlan.freeformPlans}');

      // 저장 즉시 로컬 데이터 강제 업데이트
      final index = _pdsPlans.indexWhere((plan) =>
        plan.date.toIso8601String().split('T')[0] == date.toIso8601String().split('T')[0]);

      if (index != -1) {
        _pdsPlans[index] = updatedPlan;
      } else {
        _pdsPlans.add(updatedPlan);
      }

      // 변경 알림
      notifyListeners();
      print('PDSDiaryProvider: 데이터 업데이트 및 알림 완료');
    } catch (e) {
      print('PDSDiaryProvider: saveFreeformPlan 오류: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveActualActivity(DateTime date, String timeSlot, String content) async {
    try {
      print('PDSDiaryProvider: saveActualActivity 호출 - ${date.toIso8601String().split('T')[0]} $timeSlot: $content');

      final existingPlan = getPDSPlan(date);
      Map<String, String> actualActivities = {};

      if (existingPlan != null && existingPlan.actualActivities != null) {
        actualActivities = Map<String, String>.from(existingPlan.actualActivities!);
      }

      if (content.trim().isEmpty) {
        actualActivities.remove(timeSlot);
      } else {
        actualActivities[timeSlot] = content.trim();
      }

      print('PDSDiaryProvider: 업데이트할 actualActivities: $actualActivities');

      final updatedPlan = await createOrUpdatePDSPlan(
        date: date,
        freeformPlans: existingPlan?.freeformPlans,
        actualActivities: actualActivities,
        seeNotes: existingPlan?.seeNotes,
      );

      print('PDSDiaryProvider: 실제 활동 저장 완료');
      print('PDSDiaryProvider: 저장된 실제 활동 데이터: ${updatedPlan.actualActivities}');

      // 저장 즉시 로컬 데이터 강제 업데이트
      final index = _pdsPlans.indexWhere((plan) =>
        plan.date.toIso8601String().split('T')[0] == date.toIso8601String().split('T')[0]);

      if (index != -1) {
        _pdsPlans[index] = updatedPlan;
      } else {
        _pdsPlans.add(updatedPlan);
      }

      // 변경 알림
      notifyListeners();
      print('PDSDiaryProvider: 실제 활동 데이터 업데이트 및 알림 완료');
    } catch (e) {
      print('PDSDiaryProvider: saveActualActivity 오류: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveSeeNotes(DateTime date, String notes) async {
    try {
      print('PDSDiaryProvider: saveSeeNotes 호출 - ${date.toIso8601String().split('T')[0]}: $notes');

      final existingPlan = getPDSPlan(date);

      final updatedPlan = await createOrUpdatePDSPlan(
        date: date,
        freeformPlans: existingPlan?.freeformPlans,
        actualActivities: existingPlan?.actualActivities,
        seeNotes: notes.trim().isEmpty ? null : notes.trim(),
      );

      print('PDSDiaryProvider: 회고 노트 저장 완료');

      // 저장 즉시 로컬 데이터 강제 업데이트
      final index = _pdsPlans.indexWhere((plan) =>
        plan.date.toIso8601String().split('T')[0] == date.toIso8601String().split('T')[0]);

      if (index != -1) {
        _pdsPlans[index] = updatedPlan;
      } else {
        _pdsPlans.add(updatedPlan);
      }

      // 변경 알림
      notifyListeners();
      print('PDSDiaryProvider: 회고 노트 데이터 업데이트 및 알림 완료');
    } catch (e) {
      print('PDSDiaryProvider: saveSeeNotes 오류: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}



