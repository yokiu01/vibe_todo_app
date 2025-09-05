import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/time_slot_widget.dart';
import '../widgets/task_creation_dialog.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasksForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Column(
            children: [
              // 날짜 표시
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _formatDate(taskProvider.selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              // 시간표
              Expanded(
                child: _buildTimeTable(context, taskProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskCreationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimeTable(BuildContext context, TaskProvider taskProvider) {
    final tasks = taskProvider.tasksForSelectedDate;
    final timeSlots = _generateTimeSlots();
    
    return ListView.builder(
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final slotTasks = tasks.where((task) {
          return task.startTime.hour == timeSlot.hour;
        }).toList();
        
        return TimeSlotWidget(
          timeSlot: timeSlot,
          tasks: slotTasks,
          onTaskTap: (task) => _showTaskDetails(context, task),
          onEmptySlotTap: (hour) => _showTaskCreationDialog(context, hour: hour),
        );
      },
    );
  }

  List<DateTime> _generateTimeSlots() {
    final List<DateTime> slots = [];
    for (int hour = 0; hour < 24; hour++) {
      slots.add(DateTime(2024, 1, 1, hour));
    }
    return slots;
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: context.read<TaskProvider>().selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      context.read<TaskProvider>().loadTasksForDate(picked);
    }
  }

  void _showTaskCreationDialog(BuildContext context, {int? hour}) {
    showDialog(
      context: context,
      builder: (context) => TaskCreationDialog(
        initialHour: hour,
        onTaskCreated: (task) {
          context.read<TaskProvider>().addTask(task);
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) Text(task.description!),
            const SizedBox(height: 8),
            Text('시작: ${_formatTime(task.startTime)}'),
            Text('종료: ${_formatTime(task.endTime)}'),
            Text('카테고리: ${task.category.displayName}'),
            Text('상태: ${task.status.displayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          if (task.status == TaskStatus.planned)
            TextButton(
              onPressed: () {
                context.read<TaskProvider>().updateTaskStatus(task.id, TaskStatus.inProgress);
                Navigator.of(context).pop();
              },
              child: const Text('시작'),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

