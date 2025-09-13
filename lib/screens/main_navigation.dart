import 'package:flutter/material.dart';
import 'inbox_screen.dart';
import 'plan_screen.dart';
import 'review_screen.dart';
import 'organize_screen.dart';
import 'clarification_screen.dart';
import 'archive_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = [
    const InboxScreen(),
    const ClarificationScreen(),
    const PlanScreen(),
    const ReviewScreen(),
    const ArchiveScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.add_task_outlined,
      activeIcon: Icons.add_task,
      label: 'Notion',
      emoji: '📋',
    ),
    NavigationItem(
      icon: Icons.flash_off_outlined,
      activeIcon: Icons.flash_on,
      label: '명료화',
      emoji: '⚡',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: '계획',
      emoji: '📅',
    ),
    NavigationItem(
      icon: Icons.checklist_outlined,
      activeIcon: Icons.checklist,
      label: '점검',
      emoji: '✅',
    ),
    NavigationItem(
      icon: Icons.archive_outlined,
      activeIcon: Icons.archive,
      label: '아카이브',
      emoji: '📦',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String emoji;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.emoji,
  });
}
