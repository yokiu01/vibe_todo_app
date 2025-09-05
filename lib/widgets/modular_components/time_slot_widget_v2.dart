import 'package:flutter/material.dart';
import '../../models/task.dart';

class TimeSlotWidgetV2 extends StatelessWidget {
  final DateTime timeSlot;
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(DateTime) onEmptySlotTap;

  const TimeSlotWidgetV2({
    super.key,
    required this.timeSlot,
    required this.tasks,
    required this.onTaskTap,
    required this.onEmptySlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          // 시간 표시
          Container(
            width: 80,
                      child: Text(
            _formatTime(timeSlot),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          ),
          const SizedBox(width: 8),
          // 작업들
          Expanded(
                      child: GestureDetector(
            onTap: () {
              print('TimeSlot tapped: $timeSlot, tasks.isEmpty: ${tasks.isEmpty}');
              if (tasks.isEmpty) {
                print('Calling onEmptySlotTap');
                onEmptySlotTap(timeSlot);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        '탭하여 작업 추가',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return GestureDetector(
                            onTap: () => onTaskTap(task),
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getTaskColor(task.category),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTaskColor(TaskCategory category) {
    return Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
