import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../providers/item_provider.dart';
import '../models/pds_plan.dart';
import '../models/item.dart';
import '../models/notion_task.dart';
import '../services/notion_auth_service.dart';

class PDSPlanScreen extends StatefulWidget {
  const PDSPlanScreen({super.key});

  @override
  State<PDSPlanScreen> createState() => _PDSPlanScreenState();
}

class _PDSPlanScreenState extends State<PDSPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _freeformPlans = {};
  Map<String, TextEditingController> _planControllers = {};
  Timer? _debounceTimer;

  List<NotionTask> _notionTasks = [];
  bool _isLoadingNotionTasks = false;
  final NotionAuthService _authService = NotionAuthService();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDSDiaryProvider>().loadPDSPlans();
      context.read<ItemProvider>().loadItems();
      _loadCurrentPlan();
      _loadNotionTasks();
    });
  }

  @override
  void dispose() {
    _planControllers.values.forEach((controller) => controller.dispose());
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeControllers() {
    final timeSlots = PDSPlan.generateTimeSlots();
    for (final slot in timeSlots) {
      _planControllers[slot.key] = TextEditingController();
    }
  }

  void _loadCurrentPlan() {
    print('PDS PLAN: _loadCurrentPlan 호출 - 날짜: ${_selectedDate.toIso8601String().split('T')[0]}');

    final pdsProvider = context.read<PDSDiaryProvider>();
    final currentPlan = pdsProvider.getPDSPlan(_selectedDate);

    print('PDS PLAN: 현재 계획 존재 여부: ${currentPlan != null}');

    // 먼저 모든 컨트롤러를 초기화
    _planControllers.values.forEach((controller) => controller.clear());

    if (currentPlan != null) {
      print('PDS PLAN: 기존 계획 데이터: ${currentPlan.freeformPlans}');

      setState(() {
        _freeformPlans = currentPlan.freeformPlans ?? {};
      });

      // Update controllers with loaded data
      _freeformPlans.forEach((key, value) {
        if (_planControllers.containsKey(key)) {
          _planControllers[key]!.text = value;
          print('PDS PLAN: 컨트롤러 업데이트 - $key: $value');
        }
      });
    } else {
      print('PDS PLAN: 새로운 날짜 - 컨트롤러 초기화');
      setState(() {
        _freeformPlans = {};
      });
    }

    print('PDS PLAN: _loadCurrentPlan 완료 - _freeformPlans: $_freeformPlans');
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
      print('PDS PLAN: 날짜 변경 - ${_selectedDate.toIso8601String().split('T')[0]} -> ${selectedDate.toIso8601String().split('T')[0]}');

      setState(() {
        _selectedDate = selectedDate;
      });

      // 날짜가 변경되면 해당 날짜의 데이터 로드
      await context.read<PDSDiaryProvider>().loadPDSPlans();
      await context.read<ItemProvider>().loadItems();

      // 강제로 다시 로드
      _loadCurrentPlan();
      await _loadNotionTasks();

      print('PDS PLAN: 날짜 변경 완료');
    }
  }


  /// Notion 할일 데이터 로드
  Future<void> _loadNotionTasks() async {
    if (!await _authService.isAuthenticated()) {
      setState(() {
        _notionTasks = [];
        _isLoadingNotionTasks = false;
      });
      return;
    }

    setState(() {
      _isLoadingNotionTasks = true;
    });

    try {
      final apiService = _authService.apiService;
      if (apiService != null) {
        final tasksData = await apiService.getTasksByDate(_selectedDate);
        final tasks = tasksData.map((data) => NotionTask.fromNotion(data)).toList();

        setState(() {
          _notionTasks = tasks;
        });
      }
    } catch (e) {
      print('Notion 할일 로드 실패: $e');
      setState(() {
        _notionTasks = [];
      });
    } finally {
      setState(() {
        _isLoadingNotionTasks = false;
      });
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
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<PDSDiaryProvider>().loadPDSPlans();
                  context.read<ItemProvider>().loadItems();
                  _loadCurrentPlan();
                  _loadNotionTasks();
                },
                child: _buildPlanLayout(),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 자유 입력 칸 (메모용)
                Expanded(
                  flex: 2,
                  child: _buildLeftColumn(timeSlots),
                ),
                const SizedBox(width: 8),
                // 중앙: 시간표
                _buildCenterColumn(timeSlots),
                const SizedBox(width: 8),
                // 우측: 해당 날짜의 Notion 할일들
                Expanded(
                  flex: 2,
                  child: _buildRightColumn(timeSlots),
                ),
              ],
            ),
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
          _buildColumnHeader('📝 Plan'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildRightColumn(List<TimeSlot> timeSlots) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildColumnHeader('📋 Scheduled'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('M월 d일', 'ko').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_isLoadingNotionTasks)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3B82F6),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _notionTasks.isEmpty ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_notionTasks.length}개',
                    style: TextStyle(
                      fontSize: 10,
                      color: _notionTasks.isEmpty ? const Color(0xFF6B7280) : const Color(0xFF166534),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 600, // 고정 높이 설정
            child: _isLoadingNotionTasks
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : _notionTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: const Color(0xFFE5E7EB),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '해당 날짜에\nNotion 할일이 없습니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _notionTasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = _notionTasks[index];
                          return _buildNotionTaskCard(task, index);
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

  /// 향상된 할일 카드 위젯
  Widget _buildEnhancedTaskCard(Item task, int index) {
    final isCompleted = task.status == ItemStatus.completed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: isCompleted ? 2 : 1,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF1E293B),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.content != null && task.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.content!,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF6B7280),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (task.dueDate != null) ...[
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(task.dueDate!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(task.status),
                  style: TextStyle(
                    fontSize: 9,
                    color: _getStatusColor(task.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Notion 할일 카드 위젯
  Widget _buildNotionTaskCard(NotionTask task, int index) {
    final isCompleted = task.isCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: isCompleted ? 2 : 1,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 8,
                      color: Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Notion',
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF1E293B),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF6B7280),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (task.dueDate != null) ...[
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(task.dueDate!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              if (task.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getNotionStatusColor(task.status!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status!,
                    style: TextStyle(
                      fontSize: 9,
                      color: _getNotionStatusColor(task.status!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (task.clarification != null && task.clarification!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '명료화: ${task.clarification}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getNotionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case '완료':
      case 'done':
        return const Color(0xFF22C55E);
      case '진행중':
      case 'in progress':
        return const Color(0xFF3B82F6);
      case '검토':
      case 'review':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.completed:
        return const Color(0xFF22C55E);
      case ItemStatus.active:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.completed:
        return '완료';
      case ItemStatus.active:
        return '진행중';
      default:
        return '대기';
    }
  }

  Widget _buildFreeformInput(TimeSlot slot) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      child: TextField(
        controller: _planControllers[slot.key],
        decoration: InputDecoration(
          hintText: 'Plan을 적어보세요',
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
          print('PDS PLAN: onChanged 호출 - ${slot.key}: $value');

          setState(() {
            _freeformPlans[slot.key] = value;
          });

          // 실시간 저장을 위한 디바운싱
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 800), () {
            _saveFreeformPlan(slot.key, value);
          });
        },
        onSubmitted: (value) {
          print('PDS PLAN: onSubmitted 호출 - ${slot.key}: $value');

          _debounceTimer?.cancel();
          _saveFreeformPlan(slot.key, value);
        },
        onEditingComplete: () {
          print('PDS PLAN: onEditingComplete 호출 - ${slot.key}');

          _debounceTimer?.cancel();
          final value = _planControllers[slot.key]?.text ?? '';
          _saveFreeformPlan(slot.key, value);
        },
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

  Future<void> _saveFreeformPlan(String timeSlot, String content) async {
    try {
      print('PDS PLAN: Plan 저장 시작 - ${_selectedDate.toIso8601String().split('T')[0]} $timeSlot: $content');

      // PDSDiaryProvider를 통해 저장
      await context.read<PDSDiaryProvider>().saveFreeformPlan(
        _selectedDate,
        timeSlot,
        content,
      );

      print('PDS PLAN: Plan 저장 완료');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan이 저장되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('PDS PLAN: Plan 저장 실패: $e');
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



