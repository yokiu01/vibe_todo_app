import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../utils/app_colors.dart';
import 'routine_form_screen.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool isPaused;

  const RoutineCard({
    super.key,
    required this.routine,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaused
              ? Colors.orange.withOpacity(0.3)
              : AppColors.borderColor,
        ),
      ),
      child: InkWell(
        onTap: () => _editRoutine(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPaused
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (routine.description != null && routine.description!.isNotEmpty)
                          Text(
                            routine.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: routine.status == 'Active',
                    onChanged: (value) => _toggleRoutine(context, value),
                    activeTrackColor: AppColors.accentBlue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFrequencyChips(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    routine.scheduledTime ?? '시간 미설정',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (routine.estimatedMinutes != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${routine.estimatedMinutes}분',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    final icon = routine.category ?? '📋';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          icon.split(' ')[0], // Extract emoji
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    if (routine.category?.contains('운동') ?? false) {
      return Colors.red;
    } else if (routine.category?.contains('공부') ?? false) {
      return Colors.blue;
    } else if (routine.category?.contains('명상') ?? false) {
      return Colors.purple;
    } else if (routine.category?.contains('업무') ?? false) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildFrequencyChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: routine.frequency.map((day) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.accentBlue.withOpacity(0.3),
            ),
          ),
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accentBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleRoutine(BuildContext context, bool isActive) {
    final provider = context.read<RoutineProvider>();
    provider.toggleRoutineStatus(routine.id).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive ? '루틴이 활성화되었습니다' : '루틴이 일시정지되었습니다',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _editRoutine(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineFormScreen(routine: routine),
      ),
    );
  }
}
