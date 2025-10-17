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

class _PDSPlanScreenState extends State<PDSPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _freeformPlans = {};
  Map<String, TextEditingController> _planControllers = {};
  Map<String, FocusNode> _focusNodes = {};
  Timer? _debounceTimer;

  List<NotionTask> _notionTasks = [];
  bool _isLoadingNotionTasks = false;
  final NotionAuthService _authService = NotionAuthService();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    _planControllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((focusNode) => focusNode.dispose());
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeControllers() {
    final timeSlots = PDSPlan.generateTimeSlots();
    for (final slot in timeSlots) {
      _planControllers[slot.key] = TextEditingController();
      _focusNodes[slot.key] = FocusNode();
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
              onSurface: Color(0xFF3C2A21),
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
      backgroundColor: const Color(0xFFF5F1E8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 계획 탭
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<PDSDiaryProvider>().loadPDSPlans();
                      context.read<ItemProvider>().loadItems();
                      _loadCurrentPlan();
                      _loadNotionTasks();
                    },
                    child: _buildPlanLayout(),
                  ),
                  // 루틴 탭
                  RefreshIndicator(
                    onRefresh: () async {
                      // 루틴 데이터 새로고침
                    },
                    child: _buildRoutineLayout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8), // AppColors.cardBackground
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0)), // AppColors.borderColor
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B7355).withOpacity(0.1), // AppColors.primaryBrown
                      const Color(0xFF9C8B73).withOpacity(0.1), // AppColors.primaryBrownLight
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time,
                  color: const Color(0xFF8B7355), // AppColors.primaryBrown
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '계획',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C2A21), // AppColors.textPrimary
                      ),
                    ),
                    Text(
                      '일일 계획과 루틴 관리',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6B7280), // AppColors.textSecondary
                      ),
                    ),
                  ],
                ),
              ),
              // Notion 동기화 버튼
              GestureDetector(
                onTap: _syncToNotion,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync,
                        size: 16,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Notion',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 날짜 선택기
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
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
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFF5F1E8), // AppColors.cardBackground
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B7355), // AppColors.primaryBrown
              const Color(0xFF9C8B73), // AppColors.primaryBrownLight
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7355).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF8B7355), // AppColors.primaryBrown
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(
            child: SizedBox.expand(
              child: Center(
                child: Text('계획'),
              ),
            ),
          ),
          Tab(
            child: SizedBox.expand(
              child: Center(
                child: Text('루틴'),
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

        return Container(
          child: Column(
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
                        'Scheduled',
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
              // 메인 컨텐츠 영역
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 좌측: 시간 슬롯과 계획 입력 (스크롤 가능)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
                        child: _buildPlanColumn(timeSlots),
                      ),
                    ),
                    // 우측: 해당 날짜의 Notion 할일들 (드래그 가능)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 8, right: 16, bottom: 16),
                        child: _buildScheduledColumn(timeSlots),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanColumn(List<TimeSlot> timeSlots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timeSlots.map((slot) => _buildTimeSlotCard(slot)).toList(),
    );
  }

  Widget _buildScheduledColumn(List<TimeSlot> timeSlots) {
    final sortedTasks = List<NotionTask>.from(_notionTasks)
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingNotionTasks)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
              ),
            ),
          )
        else if (sortedTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: const Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '해당 날짜에\nNotion 할일이 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...sortedTasks.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDraggableNotionTaskCard(entry.value, entry.key),
            );
          }).toList(),
      ],
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
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF8B7355),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF3C2A21),
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
                  color: const Color(0xFF8B7355),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(task.dueDate!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8B7355),
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

  /// 드래그 가능한 Notion 할일 카드 위젯
  Widget _buildDraggableNotionTaskCard(NotionTask task, int index) {
    return Draggable<NotionTask>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          child: _buildNotionTaskCard(task, index, isDragging: true),
        ),
      ),
      childWhenDragging: Container(
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.drag_handle,
            color: Color(0xFF9CA3AF),
            size: 16,
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {});
      },
      onDragEnd: (details) {
        setState(() {});
      },
      child: GestureDetector(
        onTap: () => _showTaskDetailDialog(task),
        child: _buildNotionTaskCard(task, index),
      ),
    );
  }

  /// 태스크 세부 정보 다이얼로그
  void _showTaskDetailDialog(NotionTask task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.project != null) ...[
                        _buildDetailRow(Icons.folder_outlined, '프로젝트', task.project!),
                        const SizedBox(height: 12),
                      ],
                      GestureDetector(
                        onTap: () => _showDateTimePicker(task),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF8B7355)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '날짜 및 시간',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.dueDate != null
                                          ? '${DateFormat('M월 d일 (E) HH:mm', 'ko').format(task.dueDate!)} ${_getDaysRemaining(task.dueDate!)}'
                                          : '날짜 설정하기',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF374151),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit, size: 16, color: Color(0xFF9CA3AF)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (task.status != null) ...[
                        _buildDetailRow(Icons.flag_outlined, '상태', task.status!),
                        const SizedBox(height: 12),
                      ],
                      if (task.clarification != null) ...[
                        _buildDetailRow(Icons.lightbulb_outline, '명료화', task.clarification!),
                        const SizedBox(height: 12),
                      ],
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          '설명',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('확인', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDateTimePicker(NotionTask task) async {
    final now = DateTime.now();
    final initialDate = task.dueDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ko', 'KR'),
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      final apiService = _authService.apiService;
      if (apiService != null) {
        await apiService.updateTaskDateTime(task.id, newDateTime);
        await _loadNotionTasks();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${task.title}의 날짜가 ${DateFormat('M월 d일 HH:mm', 'ko').format(newDateTime)}로 변경되었습니다',
              ),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('날짜 변경 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B7355)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDaysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return 'D+${-diff}';
    if (diff == 0) return 'D-Day';
    return 'D-$diff';
  }

  /// Notion 할일 카드 위젯
  Widget _buildNotionTaskCard(NotionTask task, int index, {bool isDragging = false}) {
    final isCompleted = task.isCompleted;
    final daysRemaining = task.dueDate != null ? _getDaysRemaining(task.dueDate!) : null;

    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF22C55E)
              : (isDragging
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE2E8F0)),
          width: isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.2 : 0.05),
            blurRadius: isDragging ? 8 : 2,
            offset: Offset(0, isDragging ? 2 : 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.project != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 10,
                        color: const Color(0xFF8B7355),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          task.project!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8B7355),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              if (task.dueDate != null) ...[
                Icon(
                  Icons.access_time,
                  size: 10,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 2),
                Text(
                  DateFormat('HH:mm').format(task.dueDate!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (daysRemaining != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDaysRemainingColor(daysRemaining),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    daysRemaining,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDaysRemainingColor(String daysRemaining) {
    if (daysRemaining.contains('D+')) return const Color(0xFFEF4444);
    if (daysRemaining == 'D-Day') return const Color(0xFFF59E0B);
    final days = int.tryParse(daysRemaining.replaceAll('D-', '')) ?? 999;
    if (days <= 3) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
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
        return const Color(0xFF8B7355);
    }
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.completed:
        return const Color(0xFF22C55E);
      case ItemStatus.active:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B7355);
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

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final hasContent = _planControllers[slot.key]?.text.isNotEmpty ?? false;
    final isCurrentTime = _isCurrentTimeSlot(slot);

    return DragTarget<NotionTask>(
      builder: (context, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;

        return Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: isDragOver
                ? const Color(0xFFEFF6FF)
                : (hasContent ? const Color(0xFFFEF3C7) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDragOver
                  ? const Color(0xFF3B82F6)
                  : (hasContent ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
              width: isDragOver ? 2 : (hasContent ? 2 : 1),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _focusTimeSlot(slot),
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
                  // 계획 입력 영역
                  Expanded(
                    child: TextField(
                      controller: _planControllers[slot.key],
                      focusNode: _focusNodes[slot.key],
                      decoration: InputDecoration(
                        hintText: hasContent ? null : '계획 입력...',
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
                          _freeformPlans[slot.key] = value;
                        });

                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
                          _saveFreeformPlan(slot.key, value);
                        });
                      },
                      onSubmitted: (value) {
                        _debounceTimer?.cancel();
                        _saveFreeformPlan(slot.key, value);
                      },
                      onEditingComplete: () {
                        _debounceTimer?.cancel();
                        final value = _planControllers[slot.key]?.text ?? '';
                        _saveFreeformPlan(slot.key, value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onWillAccept: (data) => data != null,
      onAccept: (NotionTask task) {
        _handleTaskDropToSlot(task, slot);
      },
    );
  }

  bool _isCurrentTimeSlot(TimeSlot slot) {
    final now = DateTime.now();
    return now.hour == slot.hour24;
  }

  void _focusTimeSlot(TimeSlot slot) {
    _focusNodes[slot.key]?.requestFocus();
  }



  Future<void> _saveFreeformPlan(String timeSlot, String content) async {
    try {
      await context.read<PDSDiaryProvider>().saveFreeformPlan(
        _selectedDate,
        timeSlot,
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

  /// 특정 시간 슬롯에 드래그 앤 드롭 핸들러
  void _handleTaskDropToSlot(NotionTask task, TimeSlot slot) async {
    print('PDS PLAN: 태스크 드롭됨 - ${task.title} to ${slot.key}');

    // 기존 텍스트 가져오기
    String existingText = _planControllers[slot.key]?.text ?? '';

    // 새로운 텍스트 구성 - 기존 텍스트와 합치기
    String newText = '';
    if (existingText.isNotEmpty) {
      newText = '$existingText\n• ${task.title}';
    } else {
      newText = '• ${task.title}';
    }

    // 컨트롤러 업데이트
    _planControllers[slot.key]?.text = newText;

    // 상태 업데이트
    setState(() {
      _freeformPlans[slot.key] = newText;
    });

    // 저장
    _saveFreeformPlan(slot.key, newText);

    // Notion 페이지의 날짜 속성 업데이트
    await _updateNotionTaskTime(task, slot);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${task.title}이 ${slot.display} 시간대에 추가되었습니다'),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Notion 태스크의 시간을 업데이트
  Future<void> _updateNotionTaskTime(NotionTask task, TimeSlot slot) async {
    try {
      if (await _authService.isAuthenticated()) {
        final apiService = _authService.apiService;
        if (apiService != null) {
          // 선택된 날짜와 시간 슬롯을 결합하여 새로운 DateTime 생성
          final slotHour = slot.hour24;
          final updatedDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            slotHour,
            0, // 분은 0으로 설정
          );

          // Notion API를 통해 페이지의 날짜 속성 업데이트
          await apiService.updateTaskDateTime(task.id, updatedDateTime);
          print('PDS PLAN: Notion 페이지 시간 업데이트 완료 - ${task.title}: ${updatedDateTime}');
        }
      }
    } catch (e) {
      print('PDS PLAN: Notion 페이지 시간 업데이트 실패: $e');
      // 실패해도 로컬 계획은 그대로 유지
    }
  }

  /// 최적의 타임슬롯 찾기
  String _findBestTimeSlot(NotionTask task) {
    final timeSlots = PDSPlan.generateTimeSlots();

    // 태스크에 시간이 설정되어 있으면 해당 시간 슬롯으로
    if (task.dueDate != null) {
      final taskHour = task.dueDate!.hour;
      for (final slot in timeSlots) {
        if (slot.hour24 == taskHour) {
          return slot.key;
        }
      }
    }

    // 현재 시간과 가장 가까운 슬롯으로
    final now = DateTime.now();
    final currentHour = now.hour;

    for (final slot in timeSlots) {
      if (slot.hour24 >= currentHour) {
        return slot.key;
      }
    }

    // 기본값으로 첫 번째 슬롯
    return timeSlots.first.key;
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
            backgroundColor: Color(0xFF3B82F6),
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

  /// 루틴 레이아웃
  Widget _buildRoutineLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoutineSection(
          title: '🌅 아침 루틴',
          routines: [
            {'time': '06:00', 'name': '기상', 'icon': Icons.wb_sunny},
            {'time': '06:30', 'name': '운동', 'icon': Icons.fitness_center},
            {'time': '07:00', 'name': '아침 식사', 'icon': Icons.restaurant},
            {'time': '07:30', 'name': '샤워', 'icon': Icons.shower},
          ],
        ),
        const SizedBox(height: 24),
        _buildRoutineSection(
          title: '🌆 저녁 루틴',
          routines: [
            {'time': '18:00', 'name': '저녁 식사', 'icon': Icons.dinner_dining},
            {'time': '19:00', 'name': '독서', 'icon': Icons.book},
            {'time': '20:00', 'name': '명상', 'icon': Icons.self_improvement},
            {'time': '21:00', 'name': '일기 작성', 'icon': Icons.edit_note},
          ],
        ),
        const SizedBox(height: 24),
        _buildRoutineSection(
          title: '💤 취침 루틴',
          routines: [
            {'time': '22:00', 'name': '스트레칭', 'icon': Icons.accessibility_new},
            {'time': '22:30', 'name': '내일 계획', 'icon': Icons.calendar_today},
            {'time': '23:00', 'name': '취침', 'icon': Icons.bedtime},
          ],
        ),
        const SizedBox(height: 16),
        _buildAddRoutineButton(),
      ],
    );
  }

  Widget _buildRoutineSection({
    required String title,
    required List<Map<String, dynamic>> routines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD4C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDDD4C0)),
          ...routines.map((routine) => _buildRoutineItem(routine)),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> routine) {
    return InkWell(
      onTap: () {
        // 루틴 수정 다이얼로그
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFDDD4C0), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                routine['icon'] as IconData,
                color: const Color(0xFF8B7355),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine['name'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C2A21),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routine['time'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9C8B73),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: false,
              onChanged: (value) {
                // 완료 상태 토글
              },
              activeColor: const Color(0xFF8B7355),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRoutineButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          // 새 루틴 추가 다이얼로그
          _showAddRoutineDialog();
        },
        icon: const Icon(Icons.add, color: Color(0xFF8B7355)),
        label: const Text(
          '새 루틴 추가',
          style: TextStyle(color: Color(0xFF8B7355)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF8B7355)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showAddRoutineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '새 루틴 추가',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C2A21),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '루틴 이름',
                hintText: '예: 아침 운동',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '시간',
                hintText: '예: 06:00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF8B7355)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // 루틴 저장 로직
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

}



