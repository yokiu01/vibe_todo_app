import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item.dart';

class ExecutionTutorialScreen extends StatefulWidget {
  const ExecutionTutorialScreen({super.key});

  @override
  State<ExecutionTutorialScreen> createState() => _ExecutionTutorialScreenState();
}

class _ExecutionTutorialScreenState extends State<ExecutionTutorialScreen> {
  bool _taskClarified = false;
  bool _taskAddedToPlan = false;
  bool _taskCompleted = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _clarifyTask() async {
    setState(() {
      _taskClarified = true;
      _currentStep = 1;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('명료화 완료!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _addToPlan() async {
    if (!_taskClarified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 명료화를 진행해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final onboardingProvider = context.read<OnboardingProvider>();
    final itemProvider = context.read<ItemProvider>();
    final sampleTaskId = onboardingProvider.sampleTaskId;

    if (sampleTaskId != null) {
      // Update item status to active (today's tasks)
      await itemProvider.updateItem(sampleTaskId, {
        'status': ItemStatus.active.name,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    setState(() {
      _taskAddedToPlan = true;
      _currentStep = 2;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('오늘 할 일에 추가되었습니다!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _completeTask() async {
    if (!_taskAddedToPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 오늘 할 일에 추가해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final onboardingProvider = context.read<OnboardingProvider>();
    final itemProvider = context.read<ItemProvider>();
    final sampleTaskId = onboardingProvider.sampleTaskId;

    if (sampleTaskId != null) {
      await itemProvider.completeItem(sampleTaskId);
    }

    setState(() {
      _taskCompleted = true;
      _currentStep = 3;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.white),
              SizedBox(width: 12),
              Text('첫 번째 할 일 완료! 축하합니다!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Move to completion phase after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          onboardingProvider.nextPhase();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 관리하기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: onboardingProvider.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              // Icon
              Icon(
                Icons.task_alt,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                '수집에서 실행까지',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                '이제 수집한 할 일을 명료화하고, 계획에 추가한 뒤, 실행해봅시다!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Task Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _taskCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: _taskCompleted
                                ? Colors.green
                                : Colors.grey[400],
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vibe Todo 앱 사용법 익히기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: _taskCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: _taskCompleted
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_taskClarified) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '명료화 완료',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_taskAddedToPlan) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '오늘 할 일에 추가됨',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step 1: Clarify
              _buildActionButton(
                title: '1. 명료화하기',
                description: '이 할 일이 무엇인지 구체화합니다',
                icon: Icons.lightbulb,
                onPressed: _taskClarified ? null : _clarifyTask,
                isCompleted: _taskClarified,
                isActive: _currentStep == 0,
              ),

              const SizedBox(height: 16),

              // Step 2: Add to Plan
              _buildActionButton(
                title: '2. 오늘 할 일에 추가',
                description: '명료화한 할 일을 오늘의 계획에 추가합니다',
                icon: Icons.today,
                onPressed: _taskAddedToPlan ? null : _addToPlan,
                isCompleted: _taskAddedToPlan,
                isActive: _currentStep == 1,
              ),

              const SizedBox(height: 16),

              // Step 3: Complete
              _buildActionButton(
                title: '3. 완료하기',
                description: '할 일을 실행하고 완료 표시합니다',
                icon: Icons.check_circle,
                onPressed: _taskCompleted ? null : _completeTask,
                isCompleted: _taskCompleted,
                isActive: _currentStep == 2,
              ),

              const SizedBox(height: 32),

              // Progress Summary
              _buildProgressSummary(),

              if (_taskCompleted) ...[
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '자동으로 다음 단계로 이동합니다...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Card(
      elevation: isActive ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : isActive
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.check : icon,
                  color: isCompleted
                      ? Colors.green
                      : isActive
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive && !isCompleted)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final completedSteps = [_taskClarified, _taskAddedToPlan, _taskCompleted]
        .where((step) => step)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '진행 상황',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$completedSteps',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Text(
                ' / 3',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completedSteps / 3,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
