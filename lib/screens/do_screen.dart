import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/current_task_widget.dart';
import '../widgets/memo_pad_widget.dart';

class DoScreen extends StatefulWidget {
  const DoScreen({super.key});

  @override
  State<DoScreen> createState() => _DoScreenState();
}

class _DoScreenState extends State<DoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Do'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final currentTasks = taskProvider.currentTasks;
          
          return Column(
            children: [
              // 현재 시간 표시
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _getCurrentTimeString(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              // 현재 진행 중인 작업들
              if (currentTasks.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: currentTasks.length,
                    itemBuilder: (context, index) {
                      return CurrentTaskWidget(
                        task: currentTasks[index],
                        onStatusUpdate: (task, status) {
                          taskProvider.updateTaskStatus(task.id, status);
                        },
                      );
                    },
                  ),
                )
              else
                Expanded(
                  flex: 2,
                  child: const Center(
                    child: Text('현재 진행 중인 작업이 없습니다'),
                  ),
                ),
              // 메모 패드
              Expanded(
                flex: 3,
                child: MemoPadWidget(),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

