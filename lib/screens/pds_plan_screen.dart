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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침
    context.read<PDSDiaryProvider>().loadPDSPlans();
    context.read<ItemProvider>().loadItems();
  }

  /// 날짜 선택 다이얼로그
  Future<void> _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
      });
      // 날짜가 변경되면 해당 날짜의 데이터 로드
      context.read<PDSDiaryProvider>().loadPDSPlans();
      context.read<ItemProvider>().loadItems();
    }
  }


  /// 로컬에 할일 추가
  Future<void> _addTaskToLocal(TimeSlot slot) async {
    final taskText = _freeformPlans[slot.key]?.trim();
    if (taskText == null || taskText.isEmpty) return;

    try {
      // 선택된 날짜와 시간으로 DateTime 생성
      final taskDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slot.hour24,
        0, // 분은 0으로 설정
      );

      // 로컬 데이터베이스에 할일 추가
      await context.read<ItemProvider>().addItem(
        title: taskText,
        content: '시간: ${slot.display}',
        type: ItemType.task,
        status: ItemStatus.active,
        dueDate: taskDateTime,
      );

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$taskText"이(가) 추가되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 입력 필드 초기화
      setState(() {
        _freeformPlans[slot.key] = '';
      });

      // 데이터 새로고침
      context.read<ItemProvider>().loadItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('할일 추가 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
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
              // 우측: 해당 날짜의 Notion 할일들
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
          _buildColumnHeader('해당 날짜의 할일'),
          if (dailyTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '해당 날짜에 등록된 할일이 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dailyTasks.length,
                itemBuilder: (context, index) {
                  final task = dailyTasks[index];
                  return _buildLocalTaskCard(task);
                },
              ),
            ),
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

  /// 로컬 할일 카드 위젯
  Widget _buildLocalTaskCard(Item task) {
    final isCompleted = task.status == ItemStatus.completed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF1E293B),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          if (task.content != null && task.content!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.content!,
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF64748B),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
          if (task.dueDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '시간: ${DateFormat('HH:mm').format(task.dueDate!)}',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeformInput(TimeSlot slot) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      child: TextField(
        decoration: InputDecoration(
          hintText: '할일을 적어보세요',
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          contentPadding: const EdgeInsets.all(8),
          hintStyle: const TextStyle(fontSize: 11),
          suffixIcon: (_freeformPlans[slot.key]?.isNotEmpty == true)
              ? IconButton(
                  icon: const Icon(Icons.add_circle, size: 20, color: Color(0xFF3B82F6)),
                  onPressed: () => _addTaskToLocal(slot),
                )
              : null,
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



