import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class ItemProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered lists
  List<Item> get inboxItems => _items
      .where((item) => item.status == ItemStatus.inbox)
      .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  List<Item> get activeItems => _items.where((item) => item.status == ItemStatus.active).toList();
  List<Item> get completedItems => _items.where((item) => item.status == ItemStatus.completed).toList();
  List<Item> get waitingItems => _items.where((item) => item.status == ItemStatus.waiting).toList();
  List<Item> get somedayItems => _items.where((item) => item.status == ItemStatus.someday).toList();
  List<Item> get areaItems => _items.where((item) => item.type == ItemType.area).toList();
  List<Item> get resourceItems => _items.where((item) => item.type == ItemType.resource).toList();
  
  List<Item> get overdueItems => _items.where((item) => item.isOverdue).toList();

  // 새로운 카테고리별 getter들
  List<Item> get scheduledItems => _items
      .where((item) => 
          item.status == ItemStatus.active && 
          item.dueDate != null && 
          !item.isOverdue)
      .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  List<Item> get nextActionItems => _items
      .where((item) => 
          item.status == ItemStatus.active && 
          item.dueDate == null && 
          item.delegatedTo == null)
      .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

  List<Item> get delegatedItems => _items
      .where((item) => 
          item.status == ItemStatus.waiting && 
          item.delegatedTo != null)
      .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _databaseService.getAllItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Item> addItem({
    required String title,
    String? content,
    ItemType type = ItemType.task,
    ItemStatus status = ItemStatus.inbox,
    int priority = 3,
    EnergyLevel? energyLevel,
    Context? context,
    DateTime? dueDate,
    DateTime? reminderDate,
    int? estimatedDuration,
  }) async {
    try {
      final item = Item(
        id: Helpers.generateId(),
        type: type,
        title: title,
        content: content,
        status: status,
        priority: priority,
        energyLevel: energyLevel,
        context: context,
        dueDate: dueDate,
        reminderDate: reminderDate,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdItem = await _databaseService.createItem(item);
      _items.insert(0, createdItem);
      notifyListeners();
      return createdItem;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Item> updateItem(String id, Map<String, dynamic> updates) async {
    try {
      final updatedItem = await _databaseService.updateItem(id, updates);
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
      return updatedItem;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _databaseService.deleteItem(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completeItem(String id) async {
    await updateItem(id, {
      'status': ItemStatus.completed.name,
      'completion_date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> archiveItem(String id) async {
    await updateItem(id, {
      'status': ItemStatus.archived.name,
    });
  }

  Future<void> moveToSomeday(String id) async {
    await updateItem(id, {
      'status': ItemStatus.someday.name,
    });
  }

  Future<void> moveToWaiting(String id, {String? waitingFor}) async {
    await updateItem(id, {
      'status': ItemStatus.waiting.name,
      'waiting_for': waitingFor,
    });
  }

  // Statistics
  Map<String, dynamic> getItemStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final completedThisWeek = completedItems.where((item) => 
      item.completionDate != null && 
      item.completionDate!.isAfter(weekStart)
    ).length;

    final totalTasks = _items.where((item) => item.type == ItemType.task).length;
    final completedTasks = completedItems.where((item) => item.type == ItemType.task).length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;

    final activeProjects = _items.where((item) => 
      item.type == ItemType.project && item.status == ItemStatus.active
    ).length;

    return {
      'completedThisWeek': completedThisWeek,
      'completionRate': completionRate,
      'activeProjects': activeProjects,
      'totalTasks': totalTasks,
      'overdueCount': overdueItems.length,
      'inboxCount': inboxItems.length,
      'scheduledCount': scheduledItems.length,
      'nextActionCount': nextActionItems.length,
      'delegatedCount': delegatedItems.length,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
