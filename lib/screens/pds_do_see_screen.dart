import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../providers/item_provider.dart';
import '../models/pds_plan.dart';
import '../models/item.dart';

class PDSDoSeeScreen extends StatefulWidget {
  const PDSDoSeeScreen({super.key});

  @override
  State<PDSDoSeeScreen> createState() => _PDSDoSeeScreenState();
}

class _PDSDoSeeScreenState extends State<PDSDoSeeScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _actualActivities = {};
  String _seeNotes = '';
  Map<String, TextEditingController> _activityControllers = {};
  TextEditingController _seeNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDSDiaryProvider>().loadPDSPlans();
      context.read<ItemProvider>().loadItems();
      _loadCurrentPlan();
    });
  }

  @override
  void dispose() {
    _activityControllers.values.forEach((controller) => controller.dispose());
    _seeNotesController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final timeSlots = PDSPlan.generateTimeSlots();
    for (final slot in timeSlots) {
      _activityControllers[slot.key] = TextEditingController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침
    context.read<PDSDiaryProvider>().loadPDSPlans();
    context.read<ItemProvider>().loadItems();
  }

  void _loadCurrentPlan() {
    final pdsProvider = context.read<PDSDiaryProvider>();
    final currentPlan = pdsProvider.getPDSPlan(_selectedDate);

    if (currentPlan != null) {
      setState(() {
        _actualActivities = currentPlan.actualActivities ?? {};
        _seeNotes = currentPlan.seeNotes ?? '';
      });

      // Update controllers with loaded data
      _actualActivities.forEach((key, value) {
        if (_activityControllers.containsKey(key)) {
          _activityControllers[key]!.text = value;
        }
      });
      _seeNotesController.text = _seeNotes;
    } else {
      // Clear controllers for new date
      _activityControllers.values.forEach((controller) => controller.clear());
      _seeNotesController.clear();
      setState(() {
        _actualActivities = {};
        _seeNotes = '';
      });
    }
  }

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
              primary: Color(0xFF2563EB),
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
      _loadCurrentPlan();
    }
  }

  /// 해당 날짜의 할일 가져오기
  List<Item> _getDailyTasks(List<Item> allItems) {
    return allItems.where((item) {
      if (item.dueDate == null) return false;
      return item.dueDate!.year == _selectedDate.year &&
             item.dueDate!.month == _selectedDate.month &&
             item.dueDate!.day == _selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<PDSDiaryProvider>().loadPDSPlans();
            context.read<ItemProvider>().loadItems();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: _buildDoSeeLayout(),
                ),
              ],
            ),
          ),
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
            '✅ DO-SEE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      fontSize: 16,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoSeeLayout() {
    return Consumer2<PDSDiaryProvider, ItemProvider>(
      builder: (context, pdsProvider, itemProvider, child) {
        final timeSlots = PDSPlan.generateTimeSlots();
        final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
        final plannedActivities = currentPlan?.freeformPlans ?? {};
        final dailyTasks = _getDailyTasks(itemProvider.items);

        return SingleChildScrollView(
          child: Column(
            children: [
              // DO 레이아웃
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측: PLAN에서 작성한 내용과 할일
                  Expanded(
                    flex: 2,
                    child: _buildLeftColumn(timeSlots, plannedActivities, dailyTasks),
                  ),
                  // 중앙: 시간표
                  _buildCenterColumn(timeSlots),
                  // 우측: 실제로 한 일 (DO)
                  Expanded(
                    flex: 2,
                    child: _buildRightColumn(timeSlots),
                  ),
                ],
              ),
              // 하단: SEE (회고 메모)
              _buildSeeSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(List<TimeSlot> timeSlots, Map<String, String> plannedActivities, List<Item> dailyTasks) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildColumnHeader('PLAN'),
          ...timeSlots.map((slot) => _buildPlannedDisplay(slot, plannedActivities, dailyTasks)),
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

  Widget _buildRightColumn(List<TimeSlot> timeSlots) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildColumnHeader('DO (실제 한 일)'),
          ...timeSlots.map((slot) => _buildActualInput(slot)),
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

  Widget _buildPlannedDisplay(TimeSlot slot, Map<String, String> plannedActivities, List<Item> dailyTasks) {
    final plannedText = plannedActivities[slot.key] ?? '';
    
    // 해당 시간대의 할일 찾기
    final slotTasks = dailyTasks.where((task) {
      if (task.dueDate == null) return false;
      final taskHour = task.dueDate!.hour;
      return taskHour == slot.hour24;
    }).toList();
    
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plannedText.isNotEmpty)
            Text(
              plannedText,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (slotTasks.isNotEmpty) ...[
            if (plannedText.isNotEmpty) const SizedBox(height: 4),
            ...slotTasks.map((task) => Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: task.status == ItemStatus.completed ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ],
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

  Widget _buildActualInput(TimeSlot slot) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      child: TextField(
        controller: _activityControllers[slot.key],
        decoration: InputDecoration(
          hintText: '실제로 한 일',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
          contentPadding: const EdgeInsets.all(8),
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        onChanged: (value) {
          setState(() {
            _actualActivities[slot.key] = value;
          });
          _saveActualActivity(slot.key, value);
        },
      ),
    );
  }

  Widget _buildSeeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📝 SEE (오늘의 회고)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _seeNotesController,
            decoration: InputDecoration(
              hintText: '오늘 하루를 돌아보며 느낀 점, 배운 점, 개선할 점 등을 자유롭게 적어보세요...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
              contentPadding: const EdgeInsets.all(16),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 14),
            maxLines: 6,
            onChanged: (value) {
              setState(() {
                _seeNotes = value;
              });
              _saveSeeNotes(value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveActualActivity(String timeKey, String content) async {
    try {
      await context.read<PDSDiaryProvider>().updateActualActivity(
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

  Future<void> _saveSeeNotes(String notes) async {
    try {
      await context.read<PDSDiaryProvider>().updateSeeNotes(
        _selectedDate,
        notes,
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



