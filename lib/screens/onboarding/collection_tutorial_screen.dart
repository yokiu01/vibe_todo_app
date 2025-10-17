import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item.dart';

class CollectionTutorialScreen extends StatefulWidget {
  const CollectionTutorialScreen({super.key});

  @override
  State<CollectionTutorialScreen> createState() => _CollectionTutorialScreenState();
}

class _CollectionTutorialScreenState extends State<CollectionTutorialScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  bool _taskAdded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Pre-fill with suggested text
    _taskController.text = 'Vibe Todo 앱 사용법 익히기';
  }

  @override
  void dispose() {
    _taskController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) {
      return;
    }

    final itemProvider = context.read<ItemProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    // Create a new task using ItemProvider
    final createdItem = await itemProvider.addItem(
      title: _taskController.text.trim(),
      type: ItemType.task,
      status: ItemStatus.inbox,
    );

    // Save the task ID for onboarding tracking
    onboardingProvider.setSampleTaskId(createdItem.id);

    setState(() {
      _taskAdded = true;
    });

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('수집함에 추가되었습니다!'),
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

    // Auto-advance after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<OnboardingProvider>().nextPhase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('수집하기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
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

                // Animated Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  '첫 번째 할 일을\n입력해볼까요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  '떠오르는 생각이나 해야 할 일을 자유롭게 입력하세요. 나중에 명료화 과정을 거쳐 실행 가능한 작업으로 바꿀 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Input Card
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
                              Icons.tips_and_updates,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '제안',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Task Input Field
                        TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            hintText: '할 일을 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.edit),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addTask(),
                        ),

                        const SizedBox(height: 16),

                        // Add Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _taskAdded ? null : _addTask,
                            icon: Icon(_taskAdded ? Icons.check : Icons.add),
                            label: Text(
                              _taskAdded ? '추가 완료!' : '수집함에 추가하기',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: _taskAdded
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '팁',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '생각나는 대로 자유롭게 입력하세요. 완벽하게 정리하지 않아도 괜찮습니다!',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Manual Next Button (if needed)
                if (_taskAdded)
                  TextButton(
                    onPressed: () {
                      context.read<OnboardingProvider>().nextPhase();
                    },
                    child: const Text('자동으로 다음 단계로 이동합니다...'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
