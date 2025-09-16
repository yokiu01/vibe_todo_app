import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class LockScreenService {
  static const MethodChannel _channel = MethodChannel('plan_do_lock_screen');
  static Function? _onScreenOn;
  static bool _isInitialized = false;
  static DateTime? _lastScreenOnTime;

  // 초기화 및 네이티브 이벤트 리스너 설정
  static void initialize({Function? onScreenOn}) {
    if (_isInitialized) return;

    _onScreenOn = onScreenOn;
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }

  // 네이티브에서 오는 콜백 처리
  static Future<void> _handleMethodCall(MethodCall call) async {
    print('LockScreenService: Method call received: ${call.method}');
    switch (call.method) {
      case 'onScreenOn':
        final now = DateTime.now();
        print('LockScreenService: Screen on event received at $now');
        
        // 중복 호출 방지 (1초 이내 중복 호출 무시)
        if (_lastScreenOnTime != null && 
            now.difference(_lastScreenOnTime!).inSeconds < 1) {
          print('LockScreenService: Skipping duplicate screen on event');
          return;
        }
        
        _lastScreenOnTime = now;
        final isEnabled = await isLockScreenEnabled();
        print('LockScreenService: Screen on event received, lock screen enabled: $isEnabled');
        print('LockScreenService: _onScreenOn callback is null: ${_onScreenOn == null}');
        
        if (_onScreenOn != null && isEnabled) {
          print('LockScreenService: Calling _onScreenOn callback');
          _onScreenOn!();
        } else {
          print('LockScreenService: Not calling callback - _onScreenOn: ${_onScreenOn != null}, isEnabled: $isEnabled');
        }
        break;
      case 'onUserPresent':
        print('User present event received');
        // 사용자가 잠금해제했을 때는 오버레이를 닫을 수도 있음
        break;
    }
  }

  // 오버레이 권한 확인
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('checkOverlayPermission');
      return result as bool;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  // 오버레이 권한 요청
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('Error requesting overlay permission: $e');
    }
  }

  // 수동으로 오버레이 표시 (테스트용)
  static Future<void> showOverlayManually() async {
    try {
      print('LockScreenService: showOverlayManually called');
      print('LockScreenService: _onScreenOn is null: ${_onScreenOn == null}');
      
      // 새로운 lockscreen을 직접 호출
      if (_onScreenOn != null) {
        print('LockScreenService: Calling _onScreenOn callback directly');
        _onScreenOn!();
        return;
      }

      print('LockScreenService: _onScreenOn is null, trying native method');
      // 기존 네이티브 방식 호출 (백업)
      await _channel.invokeMethod('showLockScreenOverlay');
    } catch (e) {
      print('Error showing overlay manually: $e');
    }
  }

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




