import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/item_provider.dart';
import '../providers/daily_plan_provider.dart';
import '../models/item.dart';
import '../utils/helpers.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
      context.read<DailyPlanProvider>().loadDailyPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDateTitle(),
            _buildOverdueSection(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTimeSlot('morning', '오전', '🌅'),
                    _buildTimeSlot('afternoon', '오후', '☀️'),
                    _buildTimeSlot('evening', '저녁', '🌙'),
                  ],
                ),
              ),
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
            '📋 할일 관리',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          _buildViewModeSelector(),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildViewModeButton('오늘', 'today'),
          _buildViewModeButton('내일', 'tomorrow'),
          _buildViewModeButton('주간', 'week'),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String label, String mode) {
    final isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
          if (mode == 'tomorrow') {
            _selectedDate = DateTime.now().add(const Duration(days: 1));
          } else if (mode == 'today') {
            _selectedDate = DateTime.now();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        DateFormat('yyyy년 M월 d일 EEEE', 'ko').format(_selectedDate),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildOverdueSection() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.overdueItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFFDC2626), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ 기한 지남 (${itemProvider.overdueItems.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 8),
              ...itemProvider.overdueItems.take(3).map((item) => _buildOverdueItem(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverdueItem(Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Text(
            '지연 ${item.daysOverdue}일',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String slot, String title, String icon) {
    return Consumer2<ItemProvider, DailyPlanProvider>(
      builder: (context, itemProvider, planProvider, child) {
        final itemIds = planProvider.getItemsForTimeSlot(_selectedDate, slot);
        final items = itemIds
            .map((id) => itemProvider.items.firstWhere((item) => item.id == id))
            .toList();
        
        final totalDuration = items.fold<int>(
          0,
          (sum, item) => sum + (item.estimatedDuration ?? 0),
        );

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$icon $title (${items.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Helpers.formatDuration(totalDuration),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _buildPlanItem(item)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showAddItemDialog(slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '할일 추가',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanItem(Item item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            item.formattedDuration,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String timeSlot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할일 추가'),
        content: const Text('이 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
