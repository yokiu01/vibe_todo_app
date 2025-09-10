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
      
      if (existingPlan != null) {
        final updatedPlan = await _databaseService.updatePDSPlan(existingPlan.id, {
          'freeform_plans': freeformPlans != null ? _mapToJson(freeformPlans) : existingPlan.freeformPlans != null ? _mapToJson(existingPlan.freeformPlans!) : null,
          'actual_activities': actualActivities != null ? _mapToJson(actualActivities) : existingPlan.actualActivities != null ? _mapToJson(existingPlan.actualActivities!) : null,
          'see_notes': seeNotes ?? existingPlan.seeNotes,
        });
        
        final index = _pdsPlans.indexWhere((plan) => plan.id == existingPlan.id);
        if (index != -1) {
          _pdsPlans[index] = updatedPlan;
        }
        notifyListeners();
        return updatedPlan;
      } else {
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
        return createdPlan;
      }
    } catch (e) {
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
    return map.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  Map<String, String> _jsonToMap(String json) {
    if (json.isEmpty) return {};
    final Map<String, String> result = {};
    final entries = json.split('|');
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length >= 2) {
        result[parts[0]] = parts.sublist(1).join(':');
      }
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

