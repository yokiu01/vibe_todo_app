import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../main_navigation.dart';
import 'welcome_screen.dart';
import 'notion_connection_screen.dart';
import 'completion_screen.dart';

/// Main onboarding flow controller that manages the different phases
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, onboardingProvider, child) {
        // Show the appropriate screen based on the current phase
        Widget currentScreen;

        switch (onboardingProvider.currentPhase) {
          case OnboardingPhase.welcome:
            currentScreen = const WelcomeScreen();
            break;

          case OnboardingPhase.notionConnection:
            currentScreen = const NotionConnectionScreen();
            break;

          case OnboardingPhase.collection:
          case OnboardingPhase.clarification:
          case OnboardingPhase.planning:
          case OnboardingPhase.execution:
            // 수집 단계부터는 메인 네비게이션으로 이동 (수집 탭 = 인덱스 1)
            // CollectionClarificationScreen에서 온보딩 오버레이가 표시됨
            currentScreen = const MainNavigation(initialIndex: 1);
            break;

          case OnboardingPhase.completion:
            currentScreen = const CompletionScreen();
            break;

          case OnboardingPhase.finished:
            // This should not be displayed as the onboarding is complete
            currentScreen = const SizedBox.shrink();
            break;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(onboardingProvider.currentPhase),
            child: currentScreen,
          ),
        );
      },
    );
  }
}
