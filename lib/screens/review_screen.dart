import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/review_provider.dart';
import '../models/review.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ReviewType _reviewType = ReviewType.weekly;
  Review? _currentReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviews();
      _loadTodaysReview();
    });
  }

  Future<void> _loadTodaysReview() async {
    final reviewProvider = context.read<ReviewProvider>();
    final today = DateTime.now();
    
    try {
      _currentReview = await reviewProvider.getOrCreateTodaysReview(today, _reviewType);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleStep(String stepKey) async {
    if (_currentReview == null) return;

    try {
      _currentReview = await context.read<ReviewProvider>().toggleReviewStep(
        _currentReview!.id,
        stepKey,
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeReviewType(ReviewType type) {
    setState(() {
      _reviewType = type;
      _currentReview = null;
    });
    _loadTodaysReview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTypeSelector(),
            _buildDateTitle(),
            _buildProgressBar(),
            Expanded(
              child: _buildStepsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '✅ 점검',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (_currentReview != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentReview!.completionPercentage}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTypeButton('일간', ReviewType.daily),
          _buildTypeButton('주간', ReviewType.weekly),
          _buildTypeButton('월간', ReviewType.monthly),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, ReviewType type) {
    final isActive = _reviewType == type;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _changeReviewType(type),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            foregroundColor: isActive ? Colors.white : const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        DateFormat('yyyy년 M월 d일 EEEE', 'ko').format(DateTime.now()),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_currentReview == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _currentReview!.completionRate,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsList() {
    if (_currentReview == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final steps = context.read<ReviewProvider>().getReviewSteps(_reviewType);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = _getStepValue(step.key);
        
        return _buildStepCard(step, index + 1, isCompleted);
      },
    );
  }

  bool _getStepValue(String stepKey) {
    if (_currentReview == null) return false;
    
    switch (stepKey) {
      case 'empty_inbox_completed':
        return _currentReview!.emptyInboxCompleted;
      case 'clarify_completed':
        return _currentReview!.clarifyCompleted;
      case 'mind_sweep_completed':
        return _currentReview!.mindSweepCompleted;
      case 'next_actions_reviewed':
        return _currentReview!.nextActionsReviewed;
      case 'projects_updated':
        return _currentReview!.projectsUpdated;
      case 'goals_checked':
        return _currentReview!.goalsChecked;
      case 'calendar_planned':
        return _currentReview!.calendarPlanned;
      case 'someday_reviewed':
        return _currentReview!.somedayReviewed;
      case 'new_goals_added':
        return _currentReview!.newGoalsAdded;
      default:
        return false;
    }
  }

  Widget _buildStepCard(ReviewStep step, int stepNumber, bool isCompleted) {
    return GestureDetector(
      onTap: () => _toggleStep(step.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  isCompleted ? '✓' : stepNumber.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF059669) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      height: 1.4,
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
}

