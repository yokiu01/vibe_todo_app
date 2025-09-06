import 'package:flutter/foundation.dart';
import '../models/daily_plan.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class DailyPlanProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<DailyPlan> _dailyPlans = [];
  bool _isLoading = false;
  String? _error;

  List<DailyPlan> get dailyPlans => _dailyPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDailyPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyPlans = await _databaseService.getAllDailyPlans();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DailyPlan? getDailyPlan(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      return _dailyPlans.firstWhere((plan) => 
        plan.date.toIso8601String().split('T')[0] == dateStr
      );
    } catch (e) {
      return null;
    }
  }

  Future<DailyPlan> createOrUpdateDailyPlan({
    required DateTime date,
    List<String>? planMorning,
    List<String>? planAfternoon,
    List<String>? planEvening,
    List<String>? actualItems,
    String? seeNotes,
  }) async {
    try {
      final existingPlan = getDailyPlan(date);
      
      if (existingPlan != null) {
        final updatedPlan = await _databaseService.updateDailyPlan(existingPlan.id, {
          'plan_morning': planMorning?.join(',') ?? existingPlan.planMorning?.join(','),
          'plan_afternoon': planAfternoon?.join(',') ?? existingPlan.planAfternoon?.join(','),
          'plan_evening': planEvening?.join(',') ?? existingPlan.planEvening?.join(','),
          'actual_items': actualItems?.join(',') ?? existingPlan.actualItems?.join(','),
          'see_notes': seeNotes ?? existingPlan.seeNotes,
        });
        
        final index = _dailyPlans.indexWhere((plan) => plan.id == existingPlan.id);
        if (index != -1) {
          _dailyPlans[index] = updatedPlan;
        }
        notifyListeners();
        return updatedPlan;
      } else {
        final newPlan = DailyPlan(
          id: Helpers.generateId(),
          date: date,
          planMorning: planMorning,
          planAfternoon: planAfternoon,
          planEvening: planEvening,
          actualItems: actualItems,
          seeNotes: seeNotes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final createdPlan = await _databaseService.createDailyPlan(newPlan);
        _dailyPlans.add(createdPlan);
        notifyListeners();
        return createdPlan;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addItemToTimeSlot(DateTime date, String itemId, String timeSlot) async {
    final plan = getDailyPlan(date);
    List<String>? morningItems = plan?.planMorning ?? [];
    List<String>? afternoonItems = plan?.planAfternoon ?? [];
    List<String>? eveningItems = plan?.planEvening ?? [];

    switch (timeSlot) {
      case 'morning':
        if (!morningItems.contains(itemId)) {
          morningItems.add(itemId);
        }
        break;
      case 'afternoon':
        if (!afternoonItems.contains(itemId)) {
          afternoonItems.add(itemId);
        }
        break;
      case 'evening':
        if (!eveningItems.contains(itemId)) {
          eveningItems.add(itemId);
        }
        break;
    }

    await createOrUpdateDailyPlan(
      date: date,
      planMorning: morningItems,
      planAfternoon: afternoonItems,
      planEvening: eveningItems,
    );
  }

  Future<void> removeItemFromTimeSlot(DateTime date, String itemId, String timeSlot) async {
    final plan = getDailyPlan(date);
    if (plan == null) return;

    List<String>? morningItems = plan.planMorning ?? [];
    List<String>? afternoonItems = plan.planAfternoon ?? [];
    List<String>? eveningItems = plan.planEvening ?? [];

    switch (timeSlot) {
      case 'morning':
        morningItems.remove(itemId);
        break;
      case 'afternoon':
        afternoonItems.remove(itemId);
        break;
      case 'evening':
        eveningItems.remove(itemId);
        break;
    }

    await createOrUpdateDailyPlan(
      date: date,
      planMorning: morningItems,
      planAfternoon: afternoonItems,
      planEvening: eveningItems,
    );
  }

  Future<void> markItemAsCompleted(DateTime date, String itemId) async {
    final plan = getDailyPlan(date);
    if (plan == null) return;

    List<String> actualItems = plan.actualItems ?? [];
    if (!actualItems.contains(itemId)) {
      actualItems.add(itemId);
    }

    await createOrUpdateDailyPlan(
      date: date,
      actualItems: actualItems,
    );
  }

  Future<void> updateSeeNotes(DateTime date, String notes) async {
    await createOrUpdateDailyPlan(
      date: date,
      seeNotes: notes,
    );
  }

  List<String> getItemsForTimeSlot(DateTime date, String timeSlot) {
    final plan = getDailyPlan(date);
    if (plan == null) return [];

    switch (timeSlot) {
      case 'morning':
        return plan.planMorning ?? [];
      case 'afternoon':
        return plan.planAfternoon ?? [];
      case 'evening':
        return plan.planEvening ?? [];
      default:
        return [];
    }
  }

  int getTotalPlannedItems(DateTime date) {
    final plan = getDailyPlan(date);
    return plan?.totalPlannedItems ?? 0;
  }

  int getCompletedItems(DateTime date) {
    final plan = getDailyPlan(date);
    return plan?.completedItems ?? 0;
  }

  double getCompletionRate(DateTime date) {
    final plan = getDailyPlan(date);
    return plan?.completionRate ?? 0.0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
