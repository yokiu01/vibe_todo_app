import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/modular_components/current_task_widget_v2.dart';
import '../widgets/modular_components/score_widget.dart';
import '../widgets/modular_components/memo_pad_widget_v2.dart';

class DoSeeSection extends StatefulWidget {
  final DateTime selectedDate;

  const DoSeeSection({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DoSeeSection> createState() => _DoSeeSectionState();
}

class _DoSeeSectionState extends State<DoSeeSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 현재 시간 표시
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCurrentTimeString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 현재 진행 중인 작업들
          Expanded(
            flex: 2,
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final currentTasks = taskProvider.currentTasks;
                
                if (currentTasks.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  itemCount: currentTasks.length,
                  itemBuilder: (context, index) {
                    return CurrentTaskWidgetV2(
                      task: currentTasks[index],
                      onStatusUpdate: (task, status) {
                        taskProvider.updateTaskStatus(task.id, status);
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 점수 매기기 섹션
          Expanded(
            flex: 1,
            child: ScoreWidget(
              selectedDate: widget.selectedDate,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 메모 패드
          Expanded(
            flex: 2,
            child: MemoPadWidgetV2(),
          ),
        ],
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
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '현재 진행 중인 작업이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan 섹션에서 오늘의 계획을 세워보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
