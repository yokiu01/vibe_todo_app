import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/time_slot_widget_v2.dart';
import '../widgets/modular_components/task_creation_dialog_v2.dart';
import '../widgets/modular_components/external_calendar_widget.dart';

class PlanScreenV2 extends StatefulWidget {
  const PlanScreenV2({super.key});

  @override
  State<PlanScreenV2> createState() => _PlanScreenV2State();
}

class _PlanScreenV2State extends State<PlanScreenV2> {
  @override
  void initState() {
    super.initState();
    // 화면 로드 시 선택된 날짜의 작업들 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = context.read<TaskProvider>().selectedDate;
      context.read<TaskProvider>().loadTasksForDate(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            return Text(
              _formatDate(taskProvider.selectedDate),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            );
          },
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
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final selectedDate = taskProvider.selectedDate;
        return ListView.builder(
          itemCount: 48, // 30분 단위로 24시간 = 48개
          itemBuilder: (context, index) {
            final hour = index ~/ 2;
            final minute = (index % 2) * 30;
            final timeSlot = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              hour,
              minute,
            );
        
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
    final taskProvider = context.read<TaskProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: taskProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      taskProvider.loadTasksForDate(picked);
    }
  }

  void _showTaskCreationDialog(BuildContext context, DateTime time) async {
    print('Task creation dialog called for time: $time');
    
    await showDialog(
      context: context,
      builder: (context) => TaskCreationDialogV2(
        initialTime: time,
        onTaskCreated: (task) async {
          print('Task created: ${task.title}');
          
          // TaskProvider를 통해 작업 추가
          await context.read<TaskProvider>().addTask(task);
          
          print('Task added successfully');
        },
      ),
    );
    
    // 다이얼로그가 닫힌 후 화면 새로고침
    setState(() {});
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
          ElevatedButton(
            onPressed: () {
              // 작업 수정 기능 (향후 구현)
              Navigator.of(context).pop();
            },
            child: const Text('수정'),
          ),
          ElevatedButton(
            onPressed: () {
              // 작업 삭제
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.of(context).pop();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('삭제'),
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