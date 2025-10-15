import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class WidgetService {
  static const _channel = MethodChannel('plan_do_widget');

  static Future<void> updateWidget(List<Task> currentTasks) async {
    try {
      String currentTaskTitle = "현재 진행 중인 작업이 없습니다";
      String taskTime = "";

      if (currentTasks.isNotEmpty) {
        final task = currentTasks.first;
        currentTaskTitle = task.title;
        taskTime = "${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}";
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_task', currentTaskTitle);
      await prefs.setString('task_time', taskTime);
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }

  static Future<void> updateWidgetWithTask(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_task', task.title);
      await prefs.setString('task_time', "${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}");
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }

  static String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

