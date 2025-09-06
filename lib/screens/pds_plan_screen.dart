import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../providers/item_provider.dart';
import '../models/pds_plan.dart';
import '../models/item.dart';

class PDSPlanScreen extends StatefulWidget {
  const PDSPlanScreen({super.key});

  @override
  State<PDSPlanScreen> createState() => _PDSPlanScreenState();
}

class _PDSPlanScreenState extends State<PDSPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _freeformPlans = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDSDiaryProvider>().loadPDSPlans();
      context.read<ItemProvider>().loadItems();
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
            Expanded(
              child: _buildPlanLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '⏰ PLAN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLayout() {
    return Consumer2<PDSDiaryProvider, ItemProvider>(
      builder: (context, pdsProvider, itemProvider, child) {
        final timeSlots = PDSPlan.generateTimeSlots();
        final dailyTasks = _getDailyTasks(itemProvider.items);

        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측: 자유 입력 칸
              Expanded(
                flex: 2,
                child: _buildLeftColumn(timeSlots),
              ),
              // 중앙: 시간표
              _buildCenterColumn(timeSlots),
              // 우측: 계획된 할일들
              Expanded(
                flex: 2,
                child: _buildRightColumn(timeSlots, dailyTasks),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(List<TimeSlot> timeSlots) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildColumnHeader('할일 메모'),
          ...timeSlots.map((slot) => _buildFreeformInput(slot)),
        ],
      ),
    );
  }

  Widget _buildCenterColumn(List<TimeSlot> timeSlots) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          _buildColumnHeader('시간'),
          ...timeSlots.map((slot) => _buildTimeDisplay(slot)),
        ],
      ),
    );
  }

  Widget _buildRightColumn(List<TimeSlot> timeSlots, List<Item> dailyTasks) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildColumnHeader('계획된 할일'),
          ...timeSlots.map((slot) => _buildScheduledTasks(slot, dailyTasks)),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFreeformInput(TimeSlot slot) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      child: TextField(
        decoration: const InputDecoration(
          hintText: '할일을 적어보세요',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          contentPadding: EdgeInsets.all(8),
          hintStyle: TextStyle(fontSize: 11),
        ),
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        onChanged: (value) {
          setState(() {
            _freeformPlans[slot.key] = value;
          });
          _saveFreeformPlan(slot.key, value);
        },
        controller: TextEditingController(
          text: _freeformPlans[slot.key] ?? '',
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(TimeSlot slot) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          slot.display,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledTasks(TimeSlot slot, List<Item> dailyTasks) {
    final slotTasks = dailyTasks.where((task) {
      if (task.dueDate == null) return false;
      final taskHour = task.dueDate!.hour;
      return taskHour == slot.hour24;
    }).toList();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      child: slotTasks.isEmpty
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          : ListView.builder(
              itemCount: slotTasks.length,
              itemBuilder: (context, index) {
                final task = slotTasks[index];
                return _buildScheduledTask(task);
              },
            ),
    );
  }

  Widget _buildScheduledTask(Item task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF4FF),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.estimatedDuration != null) ...[
            const SizedBox(height: 2),
            Text(
              '${task.estimatedDuration}분',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Item> _getDailyTasks(List<Item> allItems) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return allItems.where((item) {
      if (item.dueDate == null) return false;
      final itemDateStr = DateFormat('yyyy-MM-dd').format(item.dueDate!);
      return itemDateStr == dateStr;
    }).toList();
  }

  Future<void> _saveFreeformPlan(String timeKey, String content) async {
    try {
      await context.read<PDSDiaryProvider>().updateFreeformPlan(
        _selectedDate,
        timeKey,
        content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
