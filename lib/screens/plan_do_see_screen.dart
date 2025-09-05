import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'plan_section.dart';
import 'do_see_section.dart';

class PlanDoSeeScreen extends StatefulWidget {
  final DateTime selectedDate;

  const PlanDoSeeScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<PlanDoSeeScreen> createState() => _PlanDoSeeScreenState();
}

class _PlanDoSeeScreenState extends State<PlanDoSeeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    
    // 선택된 날짜로 작업 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasksForDate(widget.selectedDate);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(widget.selectedDate)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showMenu,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          tabs: const [
            Tab(text: 'Plan'),
            Tab(text: 'Do'),
            Tab(text: 'See'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 3분할 레이아웃
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _tabController.animateTo(index);
              },
              children: [
                // Plan 섹션
                PlanSection(selectedDate: widget.selectedDate),
                
                // Do-See 섹션
                DoSeeSection(selectedDate: widget.selectedDate),
                
                // See 섹션 (별도로 구현)
                const Center(
                  child: Text('See 섹션 - 점수 및 피드백'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('홈'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('설정'),
              onTap: () {
                Navigator.pop(context);
                // 설정 화면으로 이동
              },
            ),
          ],
        ),
      ),
    );
  }
}
