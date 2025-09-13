import 'package:flutter/material.dart';
import 'inbox_screen.dart';
import 'plan_screen.dart';
import 'organize_screen.dart';
import 'clarification_screen.dart';
import 'archive_screen.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // 홈을 기본으로 설정
  int _previousIndex = 2;

  final List<Widget> _screens = [
    const InboxScreen(),
    const ClarificationScreen(),
    const HomeScreen(),
    const PlanScreen(),
    const ArchiveScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.add_task_outlined,
      activeIcon: Icons.add_task,
      label: 'Notion',
      emoji: '📋',
      isHome: false,
    ),
    NavigationItem(
      icon: Icons.flash_off_outlined,
      activeIcon: Icons.flash_on,
      label: '명료화',
      emoji: '⚡',
      isHome: false,
    ),
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '홈',
      emoji: '🏠',
      isHome: true,
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80, // 네비게이션 바 높이 조정
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                  child: item.isHome
                      ? _buildHomeButton(item, isActive)
                      : _buildRegularButton(item, isActive),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(NavigationItem item, bool isActive) {
    return Transform.translate(
      offset: const Offset(0, -12), // 위로 12px 이동으로 더 돋보이게
      child: Container(
        width: 72, // 약간 더 크게
        height: 72,
        decoration: BoxDecoration(
          gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: isActive ? const Color(0xFF1E40AF) : const Color(0xFFE2E8F0),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(isActive ? 0.4 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? Colors.white : const Color(0xFF2563EB),
                size: 26,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF2563EB),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularButton(NavigationItem item, bool isActive) {
    return Container(
      width: 60, // 고정 너비 조정
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
