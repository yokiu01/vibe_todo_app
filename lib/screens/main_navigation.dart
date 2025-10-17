import 'package:flutter/material.dart';
import 'collection_clarification_screen.dart';
import 'plan_screen.dart';
import 'organize_screen.dart';
import 'archive_screen.dart';
import 'home_screen.dart';
import '../utils/app_colors.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const CollectionClarificationScreen(),
    const PlanScreen(),
    const ArchiveScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '홈',
      emoji: '🏠',
      isHome: false, // 이제 특별한 스타일 없음
    ),
    NavigationItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: '수집',
      emoji: '💡',
      isHome: false,
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: '계획',
      emoji: '📅',
      isHome: false,
    ),
    NavigationItem(
      icon: Icons.archive_outlined,
      activeIcon: Icons.archive,
      label: '아카이브',
      emoji: '📦',
      isHome: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    print('🏠 MainNavigation: Building with current index: $_currentIndex');
    print('🏠 MainNavigation: Current screen: ${_screens[_currentIndex].runtimeType}');
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFDDD4C0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navigationItems.length, (index) {
                final item = _navigationItems[index];
                final isActive = _currentIndex == index;

                return GestureDetector(
                  onTap: () {
                    if (_currentIndex != index) {
                      setState(() {
                        _previousIndex = _currentIndex;
                        _currentIndex = index;
                      });
                    }
                  },
                  child: _buildRegularButton(item, isActive, index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRegularButton(NavigationItem item, bool isActive, int index) {
    // Different colors for different tabs based on their function
    Color getActiveColor() {
      switch (index) {
        case 0: return const Color(0xFF8B7355); // Home - Brown
        case 1: return const Color(0xFFF5A623); // Collection - Orange
        case 2: return const Color(0xFF4A90E2); // Plan - Blue
        case 3: return const Color(0xFF7ED321); // Archive - Green
        default: return const Color(0xFF8B7355);
      }
    }

    final activeColor = getActiveColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  activeColor,
                  activeColor.withOpacity(0.8),
                ],
              )
            : null,
        color: isActive ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? Colors.white : activeColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF666666),
            ),
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String emoji;
  final bool isHome;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.emoji,
    this.isHome = false,
  });
}
