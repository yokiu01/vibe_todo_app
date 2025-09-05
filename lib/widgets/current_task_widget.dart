import 'package:flutter/material.dart';
import '../models/task.dart';

class CurrentTaskWidget extends StatelessWidget {
  final Task task;
  final Function(Task, TaskStatus) onStatusUpdate;

  const CurrentTaskWidget({
    super.key,
    required this.task,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getTaskColor(task.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<TaskStatus>(
                  onSelected: (status) => onStatusUpdate(task, status),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: TaskStatus.planned,
                      child: Text('계획됨'),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text('진행중'),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.completed,
                      child: Text('완료'),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.cancelled,
                      child: Text('취소됨'),
                    ),
                  ],
                ),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.category.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 진행률 표시
            LinearProgressIndicator(
              value: _calculateProgress(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getTaskColor(task.category)),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_calculateProgress() * 100).toInt()}% 완료',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTaskColor(TaskCategory category) {
    return Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _calculateProgress() {
    final now = DateTime.now();
    final totalDuration = task.endTime.difference(task.startTime).inMilliseconds;
    final elapsedDuration = now.difference(task.startTime).inMilliseconds;
    
    if (elapsedDuration <= 0) return 0.0;
    if (elapsedDuration >= totalDuration) return 1.0;
    
    return elapsedDuration / totalDuration;
  }
}
