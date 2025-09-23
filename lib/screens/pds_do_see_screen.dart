import 'dart:async';
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
  Timer? _activityDebounceTimer;
  Timer? _seeNotesDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDSDiaryProvider>().loadPDSPlans();
      context.read<ItemProvider>().loadItems();
      _loadCurrentPlan();

      // PDSDiaryProvider의 변경사항을 수신
      context.read<PDSDiaryProvider>().addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    // 리스너 제거
    context.read<PDSDiaryProvider>().removeListener(_onProviderChanged);
    _activityControllers.values.forEach((controller) => controller.dispose());
    _seeNotesController.dispose();
    _activityDebounceTimer?.cancel();
    _seeNotesDebounceTimer?.cancel();
    super.dispose();
  }

  void _onProviderChanged() {
    // Provider 데이터가 변경되었을 때 현재 계획 다시 로드
    if (mounted) {
      _loadCurrentPlan();
    }
  }

  void _initializeControllers() {
    final timeSlots = PDSPlan.generateTimeSlots();
    for (final slot in timeSlots) {
      _activityControllers[slot.key] = TextEditingController();
    }
  }

  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 초기화 한 번만 실행
    if (!_hasInitialized) {
      _hasInitialized = true;
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    print('PDS DO-SEE: 데이터 새로고침 시작');
    await context.read<PDSDiaryProvider>().loadPDSPlans();
    await context.read<ItemProvider>().loadItems();
    _loadCurrentPlan();
    print('PDS DO-SEE: 데이터 새로고침 완료');
  }

  void _loadCurrentPlan() {
    final pdsProvider = context.read<PDSDiaryProvider>();
    final currentPlan = pdsProvider.getPDSPlan(_selectedDate);

    print('PDS DO-SEE: ${_selectedDate.toIso8601String().split('T')[0]} 날짜의 계획 로드');
    print('PDS DO-SEE: 현재 계획 존재 여부: ${currentPlan != null}');

    if (currentPlan != null) {
      final newActualActivities = currentPlan.actualActivities ?? {};
      final newSeeNotes = currentPlan.seeNotes ?? '';

      print('PDS DO-SEE: 실제 활동 데이터: $newActualActivities');
      print('PDS DO-SEE: 회고 노트: $newSeeNotes');

      // 데이터가 실제로 변경된 경우에만 업데이트
      bool hasChanged = false;

      if (_mapEquals(newActualActivities, _actualActivities) == false) {
        print('PDS DO-SEE: 실제 활동 데이터 변경됨');
        _actualActivities = Map<String, String>.from(newActualActivities);
        hasChanged = true;

        // 컨트롤러 업데이트 (setState 없이)
        newActualActivities.forEach((key, value) {
          if (_activityControllers.containsKey(key)) {
            if (_activityControllers[key]!.text != value) {
              _activityControllers[key]!.text = value;
            }
          }
        });
      }

      if (_seeNotes != newSeeNotes) {
        print('PDS DO-SEE: 회고 노트 변경됨');
        _seeNotes = newSeeNotes;
        hasChanged = true;

        if (_seeNotesController.text != newSeeNotes) {
          _seeNotesController.text = newSeeNotes;
        }
      }

      // 변경사항이 있을 때만 setState 호출
      if (hasChanged) {
        setState(() {});
      }
    } else {
      print('PDS DO-SEE: 새로운 날짜 - 컨트롤러 초기화');
      // Clear controllers for new date
      _activityControllers.values.forEach((controller) => controller.clear());
      _seeNotesController.clear();
      setState(() {
        _actualActivities = {};
        _seeNotes = '';
      });
    }
  }

  bool _mapEquals(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
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
              primary: Color(0xFF8B7355),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF3C2A21),
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
      await _refreshData();
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
      backgroundColor: const Color(0xFFF5F1E8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                Container(
                  constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height > 300
                ? MediaQuery.of(context).size.height - 200
                : 100,
            ),
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
              color: Color(0xFF3C2A21),
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
                    color: Color(0xFF8B7355),
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

        // Consumer 내에서는 상태 변경 없이 단순히 데이터만 표시
        // 실제 데이터 동기화는 _loadCurrentPlan에서 처리

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

    // 디버그 로그 추가
    if (plannedText.isNotEmpty) {
      print('PDS DO-SEE: ${slot.key} 시간대에 계획된 활동: $plannedText');
    }

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
        color: plannedText.isNotEmpty || slotTasks.isNotEmpty
            ? const Color(0xFFF0F9FF)
            : const Color(0xFFF5F1E8),
        border: Border.all(
          color: plannedText.isNotEmpty || slotTasks.isNotEmpty
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plannedText.isNotEmpty)
            Expanded(
              child: Text(
                plannedText,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (slotTasks.isNotEmpty) ...[
            if (plannedText.isNotEmpty) const SizedBox(height: 2),
            ...slotTasks.take(2).map((task) => Container(
              margin: const EdgeInsets.only(bottom: 1),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: task.status == ItemStatus.completed ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
          if (plannedText.isEmpty && slotTasks.isEmpty)
            const Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(TimeSlot slot) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          slot.display,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B7355),
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
            borderSide: const BorderSide(color: Color(0xFF8B7355)),
          ),
          contentPadding: const EdgeInsets.all(8),
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: _hasPlannedActivity(slot)
            ? IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF3B82F6)),
                onPressed: () => _copyPlanToActivity(slot),
                tooltip: 'Plan에서 복사하기',
              )
            : null,
        ),
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        onChanged: (value) {
          setState(() {
            _actualActivities[slot.key] = value;
          });
          // 디바운싱으로 실시간 저장
          _activityDebounceTimer?.cancel();
          _activityDebounceTimer = Timer(const Duration(seconds: 1), () {
            _saveActualActivity(slot.key, value);
          });
        },
        onSubmitted: (value) {
          _activityDebounceTimer?.cancel();
          _saveActualActivity(slot.key, value);
        },
        onEditingComplete: () {
          _activityDebounceTimer?.cancel();
          final value = _activityControllers[slot.key]?.text ?? '';
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
                  color: Color(0xFF8B7355),
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
                borderSide: const BorderSide(color: Color(0xFF8B7355)),
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
              // 디바운싱으로 실시간 저장
              _seeNotesDebounceTimer?.cancel();
              _seeNotesDebounceTimer = Timer(const Duration(seconds: 2), () {
                _saveSeeNotes(value);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveActualActivity(String timeKey, String content) async {
    try {
      print('PDS DO-SEE: 실제 활동 저장 시작 - $timeKey: $content');
      await context.read<PDSDiaryProvider>().saveActualActivity(
        _selectedDate,
        timeKey,
        content,
      );
      print('PDS DO-SEE: 실제 활동 저장 완료');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('실제 활동이 저장되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('PDS DO-SEE: 실제 활동 저장 실패: $e');
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
      print('PDS DO-SEE: 회고 노트 저장 시작 - $notes');
      await context.read<PDSDiaryProvider>().saveSeeNotes(
        _selectedDate,
        notes,
      );
      print('PDS DO-SEE: 회고 노트 저장 완료');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회고 노트가 저장되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('PDS DO-SEE: 회고 노트 저장 실패: $e');
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

  bool _hasPlannedActivity(TimeSlot slot) {
    final pdsProvider = context.read<PDSDiaryProvider>();
    final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
    final plannedText = currentPlan?.freeformPlans?[slot.key] ?? '';
    return plannedText.isNotEmpty;
  }

  void _copyPlanToActivity(TimeSlot slot) {
    final pdsProvider = context.read<PDSDiaryProvider>();
    final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
    final plannedText = currentPlan?.freeformPlans?[slot.key] ?? '';

    if (plannedText.isNotEmpty) {
      _activityControllers[slot.key]?.text = plannedText;
      setState(() {
        _actualActivities[slot.key] = plannedText;
      });

      _saveActualActivity(slot.key, plannedText);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan에서 복사되었습니다'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}



