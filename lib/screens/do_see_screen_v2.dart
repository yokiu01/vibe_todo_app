import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/current_task_widget_v2.dart';
import '../widgets/modular_components/score_widget_v2.dart';
import 'plan_screen_v2.dart';
import 'settings_screen.dart';

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
  final Map<String, TextEditingController> _recordControllers = {};

  @override
  void initState() {
    super.initState();
    // 선택된 날짜의 작업들 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      taskProvider.loadTasksForDate(widget.selectedDate);
    });
  }

  @override
  void dispose() {
    // 컨트롤러들 정리
    for (var controller in _recordControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _selectDate,
          child: Text(
            '${_formatDate(widget.selectedDate)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 좌측: Plan (오늘의 계획)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<TaskProvider>(
                      builder: (context, taskProvider, child) {
                        final todayTasks = taskProvider.tasksForSelectedDate;
                        
                        if (todayTasks.isEmpty) {
                          return _buildEmptyPlanState();
                        }
                        
                        return ListView.builder(
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            return _buildPlanTask(task);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 우측: Do & See (시간별 기록 및 점수)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do & See',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<TaskProvider>(
                      builder: (context, taskProvider, child) {
                        final todayTasks = taskProvider.tasksForSelectedDate;
                        
                        if (todayTasks.isEmpty) {
                          return _buildEmptyDoState();
                        }
                        
                        return ListView.builder(
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            return _buildDoTaskWithScore(task);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlanState() {
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDoState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_arrow_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '계획을 실행하고 평가해보세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTask(Task task) {
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
            ],
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoTaskWithScore(Task task) {
    // 컨트롤러가 없으면 생성
    if (!_recordControllers.containsKey(task.id)) {
      _recordControllers[task.id] = TextEditingController(text: task.doRecord ?? '');
    }

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
                initialScore: task.score,
                onScoreChanged: (score) {
                  // 점수 저장
                  context.read<TaskProvider>().updateTaskScore(task.id, score);
                  _showSnackBar('점수 저장됨: $score점');
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 시간별 기록 입력
          TextField(
            controller: _recordControllers[task.id],
            decoration: InputDecoration(
              hintText: 'Do.',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
            maxLines: 2,
            onChanged: (value) {
              // 기록 저장
              context.read<TaskProvider>().updateTaskRecord(task.id, value);
            },
          ),
        ],
      ),
    );
  }

  void _saveTimeRecord(String taskId, String record) {
    // 시간별 기록 저장 로직 (향후 구현)
    print('Time record saved for task $taskId: $record');
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

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      // 기존 컨트롤러들 정리
      for (var controller in _recordControllers.values) {
        controller.dispose();
      }
      _recordControllers.clear();
      
      // 선택된 날짜로 작업 로드
      context.read<TaskProvider>().loadTasksForDate(picked);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DoSeeScreenV2(selectedDate: picked),
        ),
      );
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                'Plan',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToPlan();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                '설정',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlan() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PlanScreenV2(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
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


