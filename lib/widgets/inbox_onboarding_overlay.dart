import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

/// 수집함에서 사용되는 온보딩 오버레이
/// 실제 화면 위에 반투명 가이드를 표시하여 직관적인 사용법을 안내
class InboxOnboardingOverlay extends StatefulWidget {
  final VoidCallback onAddItem;
  final VoidCallback onClarify;
  final bool hasItems;

  const InboxOnboardingOverlay({
    super.key,
    required this.onAddItem,
    required this.onClarify,
    required this.hasItems,
  });

  @override
  State<InboxOnboardingOverlay> createState() => InboxOnboardingOverlayState();
}

class InboxOnboardingOverlayState extends State<InboxOnboardingOverlay> {
  int _currentStep = 0; // 0: 항목 추가, 1: 명료화 클릭

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();

    // 온보딩이 완료되었거나 수집 단계가 아니면 표시하지 않음
    if (onboardingProvider.isOnboardingCompleted ||
        onboardingProvider.currentPhase != OnboardingPhase.collection) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 반투명 배경
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // 배경 클릭 방지
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),

        // 가이드 메시지
        _buildGuideMessage(),

        // 건너뛰기 버튼
        Positioned(
          top: 40,
          right: 16,
          child: TextButton(
            onPressed: () {
              onboardingProvider.skipOnboarding();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideMessage() {
    if (_currentStep == 0) {
      // 첫 단계: 항목 추가 안내
      return Positioned(
        bottom: 180,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '1단계: 생각을 수집하세요',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '머릿속에 떠오르는 생각이나 해야 할 일을 자유롭게 입력하세요. 완벽하게 정리하지 않아도 괜찮습니다!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '예: "포커스 데이즈 앱 사용법 익히기"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '아래 입력창에 내용을 작성하고 + 버튼을 눌러보세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // 두 번째 단계: 명료화 안내
      return Positioned(
        top: 200,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '2단계: 명료화하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '수집한 항목을 클릭하면 명료화 화면으로 이동합니다. 명료화 탭에서 모호한 생각을 구체적인 행동으로 바꿔보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 명료화란?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '막연한 생각을 "언제, 어디서, 무엇을, 어떻게" 할지 구체화하는 과정입니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // 명료화 탭으로 이동
                      context.read<OnboardingProvider>().nextPhase();
                      widget.onClarify();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '명료화 탭으로 이동하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// 항목이 추가되었을 때 호출
  void onItemAdded() {
    setState(() {
      _currentStep = 1;
    });
  }
}
