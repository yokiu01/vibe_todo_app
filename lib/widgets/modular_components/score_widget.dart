import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';

class ScoreWidget extends StatefulWidget {
  final DateTime selectedDate;

  const ScoreWidget({
    super.key,
    required this.selectedDate,
  });

  @override
  State<ScoreWidget> createState() => _ScoreWidgetState();
}

class _ScoreWidgetState extends State<ScoreWidget> {
  Map<String, int> _hourlyScores = {};
  String _overallMemo = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시간별 점수',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 시간별 점수 그리드
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final tasks = taskProvider.tasksForSelectedDate;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 24, // 24시간
                  itemBuilder: (context, index) {
                    final hour = index;
                    final score = _hourlyScores[hour.toString()] ?? 0;
                    final hasTask = tasks.any((task) => 
                      task.startTime.hour <= hour && task.endTime.hour > hour);
                    
                    return GestureDetector(
                      onTap: () => _showScoreDialog(hour),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasTask 
                              ? _getScoreColor(score).withOpacity(0.3)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasTask 
                                ? _getScoreColor(score)
                                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${hour.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasTask 
                                    ? _getScoreColor(score)
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            if (score > 0) ...[
                              const SizedBox(height: 2),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: _getScoreColor(score),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 전체 메모
          TextField(
            decoration: const InputDecoration(
              labelText: '전체 메모',
              hintText: '오늘 하루를 돌아보며 메모를 남겨보세요',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _overallMemo = value;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showScoreDialog(int hour) {
    final currentScore = _hourlyScores[hour.toString()] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${hour.toString().padLeft(2, '0')}시 점수'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('이 시간대의 성취도를 평가해주세요'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final score = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _hourlyScores[hour.toString()] = score;
                    });
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.star,
                    size: 32,
                    color: score <= currentScore 
                        ? Colors.amber 
                        : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}


