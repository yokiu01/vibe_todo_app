import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/time_slot_widget_v2.dart';
import '../widgets/modular_components/task_creation_dialog_v2.dart';
import '../widgets/modular_components/external_calendar_widget.dart';

class PlanScreenV2 extends StatefulWidget {
  final DateTime selectedDate;

  const PlanScreenV2({
    super.key,
    required this.selectedDate,
  });

  @override
  State<PlanScreenV2> createState() => _PlanScreenV2State();
}

class _PlanScreenV2State extends State<PlanScreenV2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '계획 세우기 - ${_formatDate(widget.selectedDate)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // 외부 캘린더 연동
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ExternalCalendarWidget(
                    type: 'google',
                    onSync: () {
                      _showSnackBar('구글 캘린더 동기화 중...');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ExternalCalendarWidget(
                    type: 'notion',
                    onSync: () {
                      _showSnackBar('노션 동기화 중...');
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 시간표
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final tasks = taskProvider.tasksForSelectedDate;
                return _buildTimeTable(tasks);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTable(List<Task> tasks) {
    print('Building time table with ${tasks.length} tasks');
    return ListView.builder(
      itemCount: 48, // 30분 단위로 24시간 = 48개
      itemBuilder: (context, index) {
        final hour = index ~/ 2;
        final minute = (index % 2) * 30;
        final timeSlot = DateTime(2024, 1, 1, hour, minute);
        
        final slotTasks = tasks.where((task) {
          final taskStart = task.startTime;
          final taskEnd = task.endTime;
          final slotStart = timeSlot;
          final slotEnd = timeSlot.add(const Duration(minutes: 30));
          
          return (taskStart.isBefore(slotEnd) && taskEnd.isAfter(slotStart));
        }).toList().cast<Task>();
        
        if (slotTasks.isNotEmpty) {
          print('Time slot ${timeSlot.hour}:${timeSlot.minute.toString().padLeft(2, '0')} has ${slotTasks.length} tasks');
        }
        
        return TimeSlotWidgetV2(
          timeSlot: timeSlot,
          tasks: slotTasks,
          onTaskTap: (task) => _showTaskDetails(context, task),
          onEmptySlotTap: (time) => _showTaskCreationDialog(context, time),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      context.read<TaskProvider>().loadTasksForDate(picked);
    }
  }

  void _showTaskCreationDialog(BuildContext context, DateTime time) {
    print('Task creation dialog called for time: $time');
    showDialog(
      context: context,
      builder: (context) => TaskCreationDialogV2(
        initialTime: time,
        onTaskCreated: (task) {
          print('Task created: ${task.title}');
          context.read<TaskProvider>().addTask(task);
          // 다이얼로그 닫기
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          task.title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) 
              Text(
                task.description!,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            const SizedBox(height: 8),
            Text(
              '시작: ${_formatTime(task.startTime)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            Text(
              '종료: ${_formatTime(task.endTime)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            Text(
              '카테고리: ${task.category.displayName}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '닫기',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
