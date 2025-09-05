import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/modular_components/quote_widget.dart';
import '../widgets/modular_components/calendar_widget.dart';
import '../services/quote_service.dart';
import 'plan_screen_v2.dart';
import 'do_see_screen_v2.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _dailyQuote;
  String? _quoteAuthor;
  Map<DateTime, int> _taskCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDailyQuote();
    _loadTaskCounts();
  }

  void _loadDailyQuote() {
    final quote = QuoteService.getRandomQuote();
    setState(() {
      _dailyQuote = quote['text'];
      _quoteAuthor = quote['author'];
    });
  }

  void _loadTaskCounts() {
    // 실제 구현에서는 TaskProvider에서 데이터를 가져와야 함
    setState(() {
      _taskCounts = {
        DateTime.now(): 3,
        DateTime.now().subtract(const Duration(days: 1)): 2,
        DateTime.now().add(const Duration(days: 1)): 1,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan·Do'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘의 명언
            if (_dailyQuote != null && _quoteAuthor != null)
              QuoteWidget(
                quote: _dailyQuote!,
                author: _quoteAuthor!,
                onTap: _loadDailyQuote,
              ),
            
            // 달력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CalendarWidget(
                selectedDate: context.watch<TaskProvider>().selectedDate,
                onDateSelected: (date) {
                  context.read<TaskProvider>().loadTasksForDate(date);
                  _navigateToPlan(date);
                },
                taskCounts: _taskCounts,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 오늘의 할 일
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:             Text(
              '오늘의 할 일',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            ),
            
            const SizedBox(height: 16),
            
            // 할 일 리스트
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final todayTasks = taskProvider.tasksForSelectedDate;
                
                if (todayTasks.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayTasks.length,
                  itemBuilder: (context, index) {
                    final task = todayTasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '오늘의 계획을 세워보세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '계획하기 버튼을 눌러 하루를 시작해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(int.parse(task.category.color.substring(1), radix: 16) + 0xFF000000),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getStatusIcon(task.status),
            color: _getStatusColor(task.status),
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(status) {
    switch (status.toString()) {
      case 'TaskStatus.planned':
        return Icons.schedule;
      case 'TaskStatus.inProgress':
        return Icons.play_arrow;
      case 'TaskStatus.completed':
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getStatusColor(status) {
    switch (status.toString()) {
      case 'TaskStatus.planned':
        return Colors.blue;
      case 'TaskStatus.inProgress':
        return Colors.orange;
      case 'TaskStatus.completed':
        return Colors.green;
      default:
        return Colors.grey;
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
                _navigateToPlan(DateTime.now());
              },
            ),
            ListTile(
              leading: Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                'Do & See',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToDoSee(DateTime.now());
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

  void _navigateToPlan(DateTime date) {
    // TaskProvider의 selectedDate를 먼저 설정
    context.read<TaskProvider>().loadTasksForDate(date);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlanScreenV2(),
      ),
    );
  }

  void _navigateToDoSee(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoSeeScreenV2(selectedDate: date),
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
}
