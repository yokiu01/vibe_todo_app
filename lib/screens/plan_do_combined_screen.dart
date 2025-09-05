import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/time_slot_widget_v2.dart';
import '../widgets/modular_components/task_creation_dialog_v2.dart';
import '../widgets/modular_components/external_calendar_widget.dart';
import '../widgets/modular_components/current_task_widget_v2.dart';
import '../widgets/modular_components/score_widget_v2.dart';
import '../widgets/modular_components/memo_pad_widget_v2.dart';

class PlanDoCombinedScreen extends StatefulWidget {
  final DateTime selectedDate;

  const PlanDoCombinedScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<PlanDoCombinedScreen> createState() => _PlanDoCombinedScreenState();
}

class _PlanDoCombinedScreenState extends State<PlanDoCombinedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(widget.selectedDate)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: Row(
        children: [
          // 왼쪽: Plan 섹션
          Expanded(
            flex: 2,
            child: _buildPlanSection(),
          ),
          
          // 구분선
          Container(
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          
          // 오른쪽: Do 섹션
          Expanded(
            flex: 1,
            child: _buildDoSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '계획 세우기',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 외부 캘린더 연동
          Row(
            children: [
              Expanded(
                child: ExternalCalendarWidget(
                  type: 'google',
                  onSync: () {
                    // 구글 캘린더 동기화
                    _showSnackBar('구글 캘린더 동기화 중...');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ExternalCalendarWidget(
                  type: 'notion',
                  onSync: () {
                    // 노션 동기화
                    _showSnackBar('노션 동기화 중...');
                  },
                ),
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

  Widget _buildDoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실행 & 평가',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 현재 진행 중인 작업들
          Expanded(
            flex: 2,
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final currentTasks = taskProvider.tasksForSelectedDate;
                
                if (currentTasks.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  itemCount: currentTasks.length,
                  itemBuilder: (context, index) {
                    final task = currentTasks[index];
                    return _buildTaskWithScore(task);
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 메모 패드 (축소)
          Expanded(
            flex: 1,
            child: MemoPadWidgetV2(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTable(List<Task> tasks) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '오늘의 계획을 세워보세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskWithScore(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getTaskColor(task.category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // 점수 매기기
              ScoreWidgetV2(
                taskId: task.id,
                onScoreChanged: (score) {
                  // 점수 저장 로직
                },
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTaskColor(TaskCategory category) {
    return Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000);
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

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('홈'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('See'),
              onTap: () {
                Navigator.pop(context);
                // See 화면으로 이동
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('설정'),
              onTap: () {
                Navigator.pop(context);
                // 설정 화면으로 이동
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

