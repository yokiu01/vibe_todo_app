import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class SeeScreen extends StatefulWidget {
  const SeeScreen({super.key});

  @override
  State<SeeScreen> createState() => _SeeScreenState();
}

class _SeeScreenState extends State<SeeScreen> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'daily'; // daily, weekly, monthly

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasksForDate(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('See'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _viewMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'daily', child: Text('일간')),
              const PopupMenuItem(value: 'weekly', child: Text('주간')),
              const PopupMenuItem(value: 'monthly', child: Text('월간')),
            ],
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Column(
            children: [
              // 날짜 선택 및 뷰 모드
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getViewTitle(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                  ],
                ),
              ),
              // 통계 카드들
              Expanded(
                child: _buildStatistics(context, taskProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, TaskProvider taskProvider) {
    final tasks = taskProvider.tasksForSelectedDate;
    final stats = _calculateStatistics(tasks);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 계획 vs 실제 완료율
        _buildStatCard(
          context,
          '완료율',
          '${stats['completionRate'].toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(height: 16),
        // 카테고리별 시간 분배
        _buildCategoryStats(context, stats['categoryStats'] as Map<TaskCategory, int>),
        const SizedBox(height: 16),
        // 시간별 생산성
        _buildProductivityChart(context, tasks),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStats(BuildContext context, Map<TaskCategory, int> categoryStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('카테고리별 시간', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...categoryStats.entries.map((entry) {
              final total = categoryStats.values.fold(0, (a, b) => a + b);
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(int.parse(entry.key.color.substring(1), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key.displayName),
                    ),
                    Text('${entry.value}시간 (${percentage.toStringAsFixed(1)}%)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityChart(BuildContext context, List<Task> tasks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시간별 생산성', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            // 간단한 막대 차트 (실제로는 더 정교한 차트 라이브러리 사용 권장)
            ...List.generate(24, (hour) {
              final hourTasks = tasks.where((task) => task.startTime.hour == hour).length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: hourTasks / 5, // 최대 5개 작업으로 정규화
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hourTasks > 0 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$hourTasks'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getViewTitle() {
    switch (_viewMode) {
      case 'weekly':
        return '주간 리뷰';
      case 'monthly':
        return '월간 리뷰';
      default:
        return '일간 리뷰';
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      context.read<TaskProvider>().loadTasksForDate(picked);
    }
  }

  Map<TaskCategory, int> _calculateCategoryStats(List<Task> tasks) {
    final Map<TaskCategory, int> stats = {};
    
    for (final task in tasks) {
      final duration = task.endTime.difference(task.startTime).inHours;
      stats[task.category] = (stats[task.category] ?? 0) + duration;
    }
    
    return stats;
  }

  double _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).length;
    return (completedTasks / tasks.length) * 100;
  }

  Map<String, dynamic> _calculateStatistics(List<Task> tasks) {
    return {
      'completionRate': _calculateCompletionRate(tasks),
      'categoryStats': _calculateCategoryStats(tasks),
    };
  }
}
