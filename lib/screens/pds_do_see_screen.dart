import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../providers/item_provider.dart';
import '../models/pds_plan.dart';
import '../models/item.dart';
import '../services/notion_auth_service.dart';

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
  final NotionAuthService _authService = NotionAuthService();

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
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: _buildDoSeeLayout(),
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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'DO-SEE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              // Notion 동기화 버튼
              GestureDetector(
                onTap: _syncToNotion,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync,
                        size: 14,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Notion',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showDatePicker,
            child: Row(
              children: [
                Text(
                  DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
              ],
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

        return Column(
          children: [
            // 헤더 섹션
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Do',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // 메인 스크롤 영역 (Plan과 Do가 함께 스크롤)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Plan과 Do가 나란히 배치된 시간 슬롯들
                    ...timeSlots.map((slot) => _buildTimeSlotRow(slot, plannedActivities, dailyTasks)),
                    const SizedBox(height: 24),
                    // 하단: SEE (회고 메모)
                    _buildSeeSection(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSlotRow(TimeSlot slot, Map<String, String> plannedActivities, List<Item> dailyTasks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: Plan (시간 포함)
          Expanded(
            child: _buildPlanCard(slot, plannedActivities, dailyTasks),
          ),
          const SizedBox(width: 8),
          // 우측: Do (시간 없음)
          Expanded(
            child: _buildDoCard(slot),
          ),
        ],
      ),
    );
  }


  Widget _buildPlanCard(TimeSlot slot, Map<String, String> plannedActivities, List<Item> dailyTasks) {
    final plannedText = plannedActivities[slot.key] ?? '';

    // 해당 시간대의 할일 찾기
    final slotTasks = dailyTasks.where((task) {
      if (task.dueDate == null) return false;
      final taskHour = task.dueDate!.hour;
      return taskHour == slot.hour24;
    }).toList();

    final hasContent = plannedText.isNotEmpty || slotTasks.isNotEmpty;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: hasContent ? const Color(0xFFFEF3C7) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasContent ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: hasContent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간 표시 (왼쪽 상단)
            Text(
              slot.display,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasContent ? const Color(0xFFF59E0B) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            // 계획 내용 영역
            Expanded(
              child: plannedText.isNotEmpty
                  ? Text(
                      plannedText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  : slotTasks.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: slotTasks.take(2).map((task) => Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.status == ItemStatus.completed ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                        )
                      : const Text(
                          '계획 없음',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoCard(TimeSlot slot) {
    final hasContent = _activityControllers[slot.key]?.text.isNotEmpty ?? false;
    final hasPlannedActivity = _hasPlannedActivity(slot);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: hasContent ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasContent ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: hasContent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 액션 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasPlannedActivity)
                  GestureDetector(
                    onTap: () => _copyPlanToActivity(slot),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.copy,
                        size: 12,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                if (hasContent) ...[
                  if (hasPlannedActivity) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ],
            ),
            // 실제 활동 입력 영역
            Expanded(
              child: TextField(
                controller: _activityControllers[slot.key],
                decoration: InputDecoration(
                  hintText: hasContent ? null : '실제로 한 일...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1F2937),
                  height: 1.4,
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _actualActivities[slot.key] = value;
                  });
                  _activityDebounceTimer?.cancel();
                  _activityDebounceTimer = Timer(const Duration(milliseconds: 1200), () {
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
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentTimeSlot(TimeSlot slot) {
    final now = DateTime.now();
    return now.hour == slot.hour24;
  }

  Widget _buildSeeSection() {
    final hasContent = _seeNotesController.text.isNotEmpty;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SEE (오늘의 회고)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasContent ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
                width: hasContent ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘 하루를 되돌아보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _seeNotesController,
                  decoration: const InputDecoration(
                    hintText: '• 오늘 잘한 점은 무엇인가요?\n• 어떤 어려움이 있었나요?\n• 내일은 어떻게 개선할 수 있을까요?\n• 새롭게 배운 점이 있나요?',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      height: 1.6,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    height: 1.6,
                  ),
                  maxLines: null,
                  minLines: 6,
                  onChanged: (value) {
                    setState(() {
                      _seeNotes = value;
                    });
                    _seeNotesDebounceTimer?.cancel();
                    _seeNotesDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
                      _saveSeeNotes(value);
                    });
                  },
                  onEditingComplete: () {
                    _seeNotesDebounceTimer?.cancel();
                    _saveSeeNotes(_seeNotesController.text);
                  },
                ),
                if (hasContent) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '회고가 저장되었습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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

  /// Notion에 수동 동기화
  Future<void> _syncToNotion() async {
    try {
      if (!await _authService.isAuthenticated()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notion API 키가 설정되지 않았습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 로딩 상태 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Notion에 동기화 중...'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }

      final pdsProvider = context.read<PDSDiaryProvider>();
      final currentPlan = pdsProvider.getPDSPlan(_selectedDate);

      if (currentPlan != null) {
        final apiService = _authService.apiService;
        if (apiService != null) {
          await apiService.syncPDSData(
            _selectedDate,
            currentPlan.freeformPlans,
            currentPlan.actualActivities,
            currentPlan.seeNotes,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notion 동기화 완료!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('동기화할 데이터가 없습니다'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      print('수동 Notion 동기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동기화 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}



