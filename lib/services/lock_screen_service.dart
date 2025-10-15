import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class LockScreenService {
  static const _channel = MethodChannel('plan_do_lock_screen');
  static Function? _onScreenOn;
  static bool _isInitialized = false;
  static DateTime? _lastScreenOnTime;

  static void initialize({Function? onScreenOn}) {
    if (_isInitialized) return;
    _onScreenOn = onScreenOn;
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenOn':
        final now = DateTime.now();
        if (_lastScreenOnTime != null &&
            now.difference(_lastScreenOnTime!).inSeconds < 1) return;

        _lastScreenOnTime = now;
        final isEnabled = await isLockScreenEnabled();
        if (_onScreenOn != null && isEnabled) _onScreenOn!();
        break;
      case 'onUserPresent':
        break;
    }
  }

  static Future<bool> hasOverlayPermission() async => true;
  static Future<void> requestOverlayPermission() async {}

  static Future<void> showOverlayManually() async {
    if (_onScreenOn != null) _onScreenOn!();
  }

  static Future<bool> isLockScreenEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('flutter.lock_screen_enabled') ?? true;
  }

  static Future<void> setLockScreenEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flutter.lock_screen_enabled', enabled);

    // Foreground Service 시작/중지
    try {
      if (enabled) {
        await startForegroundService();
      } else {
        await stopForegroundService();
      }
    } catch (e) {
      print('Foreground service control error: $e');
    }
  }

  static Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
    } catch (e) {
      print('Start foreground service error: $e');
    }
  }

  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (e) {
      print('Stop foreground service error: $e');
    }
  }

  static Future<bool> isLockScreenEditEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('lock_screen_edit_enabled') ?? false;
  }

  static Future<void> setLockScreenEditEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_screen_edit_enabled', enabled);
  }

  static Future<void> updateLockScreenData({
    required List<Task> todayTasks,
    required List<Task> currentTasks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final planData = todayTasks.map((t) => {
        'id': t.id,
        'title': t.title,
        'startTime': t.startTime.toIso8601String(),
        'endTime': t.endTime.toIso8601String(),
        'category': t.category.displayName,
        'status': t.status.name,
      }).toList();

      final doData = currentTasks.map((t) => {
        'id': t.id,
        'title': t.title,
        'startTime': t.startTime.toIso8601String(),
        'endTime': t.endTime.toIso8601String(),
        'category': t.category.displayName,
        'status': t.status.name,
      }).toList();

      await prefs.setString('lock_screen_plan_data', jsonEncode(planData));
      await prefs.setString('lock_screen_do_data', jsonEncode(doData));
      await _channel.invokeMethod('updateLockScreenWidget');
    } catch (_) {}
  }

  static Future<void> updateTaskStatusFromLockScreen(String taskId, String status) async {
    try {
      await _channel.invokeMethod('updateTaskStatus', {
        'taskId': taskId,
        'status': status,
      });
    } catch (_) {}
  }

  static Future<void> completeTaskFromLockScreen(String taskId) async {
    try {
      await _channel.invokeMethod('completeTask', {'taskId': taskId});
    } catch (_) {}
  }
}




