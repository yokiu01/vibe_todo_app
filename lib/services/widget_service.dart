import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('plan_do_widget');
  
  static Future<void> updateWidget(List<Task> currentTasks) async {
    try {
      // 현재 진행 중인 작업들 중 첫 번째 작업을 위젯에 표시
      String currentTaskTitle = "현재 진행 중인 작업이 없습니다";
      String taskTime = "";
      
      if (currentTasks.isNotEmpty) {
        final task = currentTasks.first;
        currentTaskTitle = task.title;
        taskTime = "${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}";
      }
      
      // SharedPreferences에 데이터 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_task', currentTaskTitle);
      await prefs.setString('task_time', taskTime);
      
      // 위젯 업데이트 요청
      await _channel.invokeMethod('updateWidget');
      
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
  
  static Future<void> updateWidgetWithTask(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_task', task.title);
      await prefs.setString('task_time', "${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}");
      
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      print('Error updating widget with task: $e');
    }
  }
  
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
