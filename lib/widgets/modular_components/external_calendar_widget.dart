import 'package:flutter/material.dart';

class ExternalCalendarWidget extends StatelessWidget {
  final String type;
  final VoidCallback onSync;

  const ExternalCalendarWidget({
    super.key,
    required this.type,
    required this.onSync,
  });

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
          Row(
            children: [
              Icon(
                _getIcon(),
                color: _getColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getTitle(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getDescription(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSync,
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('동기화'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case 'google':
        return Icons.calendar_today;
      case 'notion':
        return Icons.note;
      default:
        return Icons.calendar_month;
    }
  }

  Color _getColor() {
    switch (type) {
      case 'google':
        return const Color(0xFF4285F4);
      case 'notion':
        return const Color(0xFF000000);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _getTitle() {
    switch (type) {
      case 'google':
        return '구글 캘린더';
      case 'notion':
        return '노션';
      default:
        return '외부 캘린더';
    }
  }

  String _getDescription() {
    switch (type) {
      case 'google':
        return '구글 캘린더의 일정을 가져옵니다';
      case 'notion':
        return '노션 데이터베이스의 작업을 가져옵니다';
      default:
        return '외부 서비스와 연동합니다';
    }
  }
}
