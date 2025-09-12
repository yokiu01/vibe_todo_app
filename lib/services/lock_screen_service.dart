import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class LockScreenService {
  static const MethodChannel _channel = MethodChannel('plan_do_lock_screen');
  
  // 잠금화면에서 plan과 do를 볼 수 있는지 설정
  static Future<bool> isLockScreenEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('lock_screen_enabled') ?? false;
  }
  
  static Future<void> setLockScreenEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_screen_enabled', enabled);
  }
  
  // 잠금화면에서 do를 수정할 수 있는지 설정
  static Future<bool> isLockScreenEditEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('lock_screen_edit_enabled') ?? false;
  }
  
  static Future<void> setLockScreenEditEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_screen_edit_enabled', enabled);
  }
  
  // 잠금화면에 표시할 데이터 업데이트
  static Future<void> updateLockScreenData({
    required List<Task> todayTasks,
    required List<Task> currentTasks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 오늘의 계획 (Plan)
      final planData = todayTasks.map((task) => {
        'id': task.id,
        'title': task.title,
        'startTime': task.startTime.toIso8601String(),
        'endTime': task.endTime.toIso8601String(),
        'category': task.category.displayName,
        'status': task.status.name,
      }).toList();
      
      // 현재 진행 중인 작업 (Do)
      final doData = currentTasks.map((task) => {
        'id': task.id,
        'title': task.title,
        'startTime': task.startTime.toIso8601String(),
        'endTime': task.endTime.toIso8601String(),
        'category': task.category.displayName,
        'status': task.status.name,
      }).toList();
      
      await prefs.setString('lock_screen_plan_data', jsonEncode(planData));
      await prefs.setString('lock_screen_do_data', jsonEncode(doData));
      
      // 네이티브 위젯 업데이트
      await _channel.invokeMethod('updateLockScreenWidget');
      
    } catch (e) {
      print('Error updating lock screen data: $e');
    }
  }
  
  // 잠금화면에서 작업 상태 업데이트
  static Future<void> updateTaskStatusFromLockScreen(String taskId, String status) async {
    try {
      await _channel.invokeMethod('updateTaskStatus', {
        'taskId': taskId,
        'status': status,
      });
    } catch (e) {
      print('Error updating task status from lock screen: $e');
    }
  }
  
  // 잠금화면에서 작업 완료 처리
  static Future<void> completeTaskFromLockScreen(String taskId) async {
    try {
      await _channel.invokeMethod('completeTask', {
        'taskId': taskId,
      });
    } catch (e) {
      print('Error completing task from lock screen: $e');
    }
  }
}




