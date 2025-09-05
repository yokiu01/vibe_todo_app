import 'package:flutter/material.dart';
import '../models/task.dart';

class TimeSlotWidget extends StatelessWidget {
  final DateTime timeSlot;
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(int) onEmptySlotTap;

  const TimeSlotWidget({
    super.key,
    required this.timeSlot,
    required this.tasks,
    required this.onTaskTap,
    required this.onEmptySlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // 시간 표시
          Container(
            width: 60,
            child: Text(
              '${timeSlot.hour.toString().padLeft(2, '0')}:00',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          // 작업들
          Expanded(
            child: GestureDetector(
              onTap: () => onEmptySlotTap(timeSlot.hour),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: tasks.isEmpty
                    ? const Center(
                        child: Text(
                          '탭하여 작업 추가',
                          style: TextStyle(color: Colors.grey),
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
                              width: 120,
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
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
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

