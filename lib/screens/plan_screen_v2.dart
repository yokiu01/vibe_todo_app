import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/modular_components/task_creation_dialog_v2.dart';
import 'do_see_screen_v2.dart';
import 'settings_screen.dart';

class PlanScreenV2 extends StatefulWidget {
  const PlanScreenV2({super.key});

  @override
  State<PlanScreenV2> createState() => _PlanScreenV2State();
}

class _PlanScreenV2State extends State<PlanScreenV2> {
  @override
  void initState() {
    super.initState();
    // 화면 로드 시 선택된 날짜의 작업들 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      final selectedDate = taskProvider.selectedDate;
      taskProvider.loadTasksForDate(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            return GestureDetector(
              onTap: _selectDate,
              child: Text(
                _formatDate(taskProvider.selectedDate),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
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
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.tasksForSelectedDate;
          return _buildTimeTable(tasks);
        },
      ),
    );
  }

  Widget _buildTimeTable(List<Task> tasks) {
    print('Building time table with ${tasks.length} tasks');
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final selectedDate = taskProvider.selectedDate;
        
        // 시간별로 그룹화된 작업들 (시작 시간 기준)
        final Map<String, List<Task>> tasksByHour = {};
        for (int hour = 0; hour < 24; hour++) {
          tasksByHour['$hour'] = tasks.where((task) {
            return task.startTime.hour == hour;
          }).toList();
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Plan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 시간표
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(24, (hour) {
                      final hourTasks = tasksByHour['$hour'] ?? [];
                      return _buildTimeRow(hour, hourTasks, selectedDate);
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeRow(int hour, List<Task> tasks, DateTime selectedDate) {
    // 해당 시간에 시작하는 작업들만 필터링
    final startingTasks = tasks.where((task) => task.startTime.hour == hour).toList();
    
    // 이 시간에 시작하는 작업들의 최대 높이 계산
    double maxHeight = 60; // 기본 높이
    for (final task in startingTasks) {
      final duration = task.endTime.difference(task.startTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final taskHeight = (hours * 60 + (minutes / 60) * 60).clamp(60.0, double.infinity);
      if (taskHeight > maxHeight) {
        maxHeight = taskHeight;
      }
    }
    
    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 표시 (고정 크기)
          Container(
            width: 60,
            height: maxHeight,
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // 작업들
          Expanded(
            child: Container(
              height: maxHeight,
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  // + 버튼 (항상 표시)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        final time = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          hour,
                          0,
                        );
                        _showTaskCreationDialog(context, time);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 작업 블록들 (불투명하게)
                  if (startingTasks.isNotEmpty)
                    ...startingTasks.map((task) => _buildTaskBlock(task, hour, selectedDate)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTaskBlock(Task task, int hour, DateTime selectedDate) {
    final duration = task.endTime.difference(task.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    // 작업의 높이 계산 (시간당 60px, 최소 60px)
    final height = (hours * 60 + (minutes / 60) * 60).clamp(60.0, double.infinity);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: GestureDetector(
        onTap: () => _showTaskDetails(context, task),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTaskColor(task.category).withOpacity(0.9), // 불투명하게
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getTaskColor(task.category).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getTaskColor(task.category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (task.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 2),
              Text(
                '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
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
    final taskProvider = context.read<TaskProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: taskProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      taskProvider.loadTasksForDate(picked);
    }
  }

  void _showTaskCreationDialog(BuildContext context, DateTime time) async {
    print('Task creation dialog called for time: $time');
    
    await showDialog(
      context: context,
      builder: (context) => TaskCreationDialogV2(
        initialTime: time,
        onTaskCreated: (task) async {
          print('Task created: ${task.title}');
          
          // TaskProvider를 통해 작업 추가
          await context.read<TaskProvider>().addTask(task);
          
          print('Task added successfully');
        },
      ),
    );
    
    // 다이얼로그가 닫힌 후 화면 새로고침
    setState(() {});
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
            child: Text(
              '닫기',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showTaskEditDialog(context, task);
            },
            child: const Text('수정'),
          ),
          ElevatedButton(
            onPressed: () {
              // 작업 삭제
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.of(context).pop();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showTaskEditDialog(BuildContext context, Task task) async {
    print('Task edit dialog called for task: ${task.title}');
    
    await showDialog(
      context: context,
      builder: (context) => TaskCreationDialogV2(
        initialTime: task.startTime,
        initialTask: task,
        onTaskCreated: (updatedTask) async {
          print('Task updated: ${updatedTask.title}');
          
          // TaskProvider를 통해 작업 업데이트
          await context.read<TaskProvider>().updateTask(updatedTask);
          
          print('Task updated successfully');
        },
      ),
    );
    
    // 다이얼로그가 닫힌 후 화면 새로고침
    setState(() {});
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
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                'Do & See',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToDoSee();
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

  void _navigateToDoSee() {
    final taskProvider = context.read<TaskProvider>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DoSeeScreenV2(selectedDate: taskProvider.selectedDate),
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