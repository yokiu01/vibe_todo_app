import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/time_slot_widget_v2.dart';
import '../widgets/modular_components/task_creation_dialog_v2.dart';
import '../widgets/modular_components/external_calendar_widget.dart';

class PlanSection extends StatefulWidget {
  final DateTime selectedDate;

  const PlanSection({
    super.key,
    required this.selectedDate,
  });

  @override
  State<PlanSection> createState() => _PlanSectionState();
}

class _PlanSectionState extends State<PlanSection> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 왼쪽: 계획 입력 영역
        Expanded(
          flex: 2,
          child: _buildPlanningArea(),
        ),
        
        // 구분선
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        
        // 오른쪽: 외부 일정 연동
        Expanded(
          flex: 1,
          child: _buildExternalCalendarArea(),
        ),
      ],
    );
  }

  Widget _buildPlanningArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 선택 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '계획 세우기',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
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

  Widget _buildTimeTable(List tasks) {
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
        
        return TimeSlotWidgetV2(
          timeSlot: timeSlot,
          tasks: slotTasks,
          onTaskTap: (task) => _showTaskDetails(context, task),
          onEmptySlotTap: (time) => _showTaskCreationDialog(context, time),
        );
      },
    );
  }

  Widget _buildExternalCalendarArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '외부 일정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 구글 캘린더 연동
          ExternalCalendarWidget(
            type: 'google',
            onSync: () {
              // 구글 캘린더 동기화
            },
          ),
          
          const SizedBox(height: 16),
          
          // 노션 연동
          ExternalCalendarWidget(
            type: 'notion',
            onSync: () {
              // 노션 동기화
            },
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => TaskCreationDialogV2(
        initialTime: time,
        onTaskCreated: (task) {
          context.read<TaskProvider>().addTask(task);
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, task) {
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
