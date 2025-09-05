import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/current_task_widget_v2.dart';
import '../widgets/modular_components/score_widget_v2.dart';
import '../widgets/modular_components/memo_pad_widget_v2.dart';

class DoSeeScreenV2 extends StatefulWidget {
  final DateTime selectedDate;

  const DoSeeScreenV2({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DoSeeScreenV2> createState() => _DoSeeScreenV2State();
}

class _DoSeeScreenV2State extends State<DoSeeScreenV2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '실행 & 평가 - ${_formatDate(widget.selectedDate)}',
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
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            
            // 메모 패드
            Expanded(
              flex: 1,
              child: MemoPadWidgetV2(),
            ),
          ],
        ),
      ),
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
            '오늘의 계획을 먼저 세워보세요',
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
                  _showSnackBar('점수 저장됨: $score점');
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

