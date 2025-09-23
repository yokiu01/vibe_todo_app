import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../models/pds_plan.dart';
import '../services/lock_screen_service.dart';

class LockScreenStandalone extends StatefulWidget {
  const LockScreenStandalone({super.key});

  @override
  State<LockScreenStandalone> createState() => _LockScreenStandaloneState();
}

class _LockScreenStandaloneState extends State<LockScreenStandalone>
    with TickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('plan_do_lock_screen');
  DateTime _selectedDate = DateTime.now();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _canEdit = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeAnimations();
    _checkEditPermission();
    _loadData();
    _scrollToCurrentTime();
    _setupUI();
    
    // 락 스크린 전용 초기화 (빠른 시작)
    _initializeLockScreenOnly();
  }

  void _initializeLockScreenOnly() {
    print('Lock screen standalone initialized - fast mode');
    // 락 스크린에 필요한 최소한의 초기화만 수행
  }

  void _setupUI() {
    // 전체화면 설정
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 세로 방향 고정
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 시스템 UI 스타일 설정
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }


  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkEditPermission() async {
    final canEdit = await LockScreenService.isLockScreenEditEnabled();
    setState(() {
      _canEdit = canEdit;
    });
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          // 락 스크린용 최소한의 데이터만 로드
          await context.read<PDSDiaryProvider>().loadPDSPlansForLockScreen();
          print('Lock screen data loaded - fast mode');
        } catch (e) {
          print('Error loading lock screen data: $e');
          // 오류 시에도 기본 데이터로 표시
          _loadFallbackData();
        }
      }
    });
  }

  void _loadFallbackData() {
    // 락 스크린용 기본 데이터 로드
    print('Loading fallback data for lock screen');
  }

  void _scrollToCurrentTime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final currentHour = DateTime.now().hour;
        final timeSlots = PDSPlan.generateTimeSlots();

        int currentIndex = 0;
        for (int i = 0; i < timeSlots.length; i++) {
          if (timeSlots[i].hour24 == currentHour) {
            currentIndex = i;
            break;
          }
        }

        // 현재 시간이 맨 위에 오도록 스크롤 (이미 정렬되어 있으므로 0으로 스크롤)
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _closeLockScreen() async {
    try {
      // Android 잠금화면으로 돌아가기 위해 Activity를 종료
      await _channel.invokeMethod('closeLockScreen');
    } catch (e) {
      print('Error closing lock screen: $e');
      // Activity를 종료하여 Android 잠금화면으로 돌아감
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔒 LockScreenStandalone: Building LockScreenStandalone widget');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F1E8),
              Color(0xFFEFE7D3),
              Color(0xFFDDD4C0),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // 상단 헤더
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 16),
                  // 중간 스크롤 가능한 영역
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPlanDoSection(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3C2A21),
            ),
          ),
          IconButton(
            onPressed: _closeLockScreen,
            icon: const Icon(
              Icons.close,
              color: Color(0xFF8B7355),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPlanDoSection() {
    return Consumer<PDSDiaryProvider>(
      builder: (context, pdsProvider, child) {
        final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
        final timeSlots = PDSPlan.generateTimeSlots();
        final plannedActivities = currentPlan?.freeformPlans ?? {};
        final actualActivities = currentPlan?.actualActivities ?? {};
        final currentHour = DateTime.now().hour;

        // 모든 시간대를 표시하되, 현재 시간을 맨 위에
        final allSlots = List<TimeSlot>.from(timeSlots);
        allSlots.sort((a, b) {
          if (a.hour24 == currentHour) return -1;
          if (b.hour24 == currentHour) return 1;
          return a.hour24.compareTo(b.hour24);
        });

        return _buildPerspectiveScrollView(
          allSlots: allSlots,
          plannedActivities: plannedActivities,
          actualActivities: actualActivities,
          currentHour: currentHour,
        );
      },
    );
  }

  Widget _buildPerspectiveScrollView({
    required List<TimeSlot> allSlots,
    required Map<String, String> plannedActivities,
    required Map<String, String> actualActivities,
    required int currentHour,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // 화면의 60% 높이
      child: Stack(
        children: [
          // 상단 페이드 효과
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5F1E8).withOpacity(0.9),
                    const Color(0xFFF5F1E8).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // 하단 페이드 효과
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5F1E8).withOpacity(0.0),
                    const Color(0xFFF5F1E8).withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          
          // 스크롤 가능한 리스트
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: allSlots.length,
            itemBuilder: (context, index) {
              final slot = allSlots[index];
              final planned = plannedActivities[slot.key] ?? '';
              final actual = actualActivities[slot.key] ?? '';
              final isCurrentTime = slot.hour24 == currentHour;
              
              return _buildPerspectiveCard(
                slot: slot,
                planned: planned,
                actual: actual,
                isCurrentTime: isCurrentTime,
                index: index,
                totalItems: allSlots.length,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveCard({
    required TimeSlot slot,
    required String planned,
    required String actual,
    required bool isCurrentTime,
    required int index,
    required int totalItems,
  }) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // 스크롤 위치에 따른 3D 효과 계산
        final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
        final itemHeight = 120.0; // 각 카드의 높이
        final itemTop = index * itemHeight;
        final itemCenter = itemTop + itemHeight / 2;
        final viewportHeight = MediaQuery.of(context).size.height * 0.6;
        final viewportCenter = viewportHeight / 2;
        
        // 화면 중앙으로부터의 거리 (정규화)
        final distanceFromCenter = (itemCenter - scrollOffset - viewportCenter).abs() / viewportCenter;
        
        // 3D 효과 계산
        final scale = (1.0 - distanceFromCenter * 0.3).clamp(0.7, 1.0);
        final opacity = (1.0 - distanceFromCenter * 0.5).clamp(0.3, 1.0);
        final rotationX = (distanceFromCenter * 0.1).clamp(0.0, 0.1);
        
        // 상단/하단 경계에서의 추가 페이드 효과
        final itemBottom = itemTop + itemHeight;
        final fadeTop = scrollOffset;
        final fadeBottom = scrollOffset + viewportHeight;
        
        double fadeOpacity = 1.0;
        if (itemTop < fadeTop + 50) {
          fadeOpacity = ((itemTop - fadeTop + 50) / 50).clamp(0.0, 1.0);
        } else if (itemBottom > fadeBottom - 50) {
          fadeOpacity = ((fadeBottom - itemBottom + 50) / 50).clamp(0.0, 1.0);
        }
        
        final finalOpacity = (opacity * fadeOpacity).clamp(0.0, 1.0);
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 원근감을 위한 z축 변환
            ..rotateX(rotationX)
            ..scale(scale),
          child: Opacity(
            opacity: finalOpacity,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: isCurrentTime 
                ? _buildCurrentTimeCard(slot, {slot.key: planned}, {slot.key: actual})
                : _buildScheduleCard(slot, planned, actual, false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTimeCard(TimeSlot currentSlot, Map<String, String> plannedActivities, Map<String, String> actualActivities) {
    final planned = plannedActivities[currentSlot.key] ?? '';
    final actual = actualActivities[currentSlot.key] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '지금',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                currentSlot.display,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (planned.isNotEmpty) ...[
            const Text(
              '계획',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE8DCC6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              planned,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            if (actual.isNotEmpty) const SizedBox(height: 12),
          ],
          if (actual.isNotEmpty) ...[
            const Text(
              '실제',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE8DCC6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              actual,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFF5F1E8),
                height: 1.3,
              ),
            ),
          ],
          if (planned.isEmpty && actual.isEmpty) ...[
            const Text(
              '현재 시간대에 등록된 일정이 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFE8DCC6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (_canEdit) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showDoEditDialog(currentSlot, planned, actual),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '편집',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard(TimeSlot slot, String planned, String actual, bool isHighlighted) {
    final hasContent = planned.isNotEmpty || actual.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasContent 
          ? Colors.white.withOpacity(0.95)
          : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasContent 
            ? const Color(0xFFE0E7FF).withOpacity(0.8)
            : Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: hasContent ? [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasContent ? [
                  const Color(0xFF667eea).withOpacity(0.1),
                  const Color(0xFF764ba2).withOpacity(0.1),
                ] : [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasContent 
                  ? const Color(0xFF667eea).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${slot.hour24}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasContent 
                      ? const Color(0xFF667eea)
                      : Colors.grey.withOpacity(0.7),
                  ),
                ),
                Text(
                  slot.hour24 < 12 ? 'AM' : 'PM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: hasContent 
                      ? const Color(0xFF667eea).withOpacity(0.8)
                      : Colors.grey.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (planned.isNotEmpty) ...[
                  Text(
                    planned,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasContent 
                        ? const Color(0xFF1F2937)
                        : Colors.grey.withOpacity(0.7),
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actual.isNotEmpty) const SizedBox(height: 8),
                ] else if (!hasContent) ...[
                  Text(
                    '일정 없음',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (actual.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            actual,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_canEdit)
            GestureDetector(
              onTap: () => _showDoEditDialog(slot, planned, actual),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: const Color(0xFF667eea),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEFE7D3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE7D3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 24,
              color: Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '오늘 등록된 일정이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3C2A21),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '계획을 세워보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9C8B73),
            ),
          ),
        ],
      ),
    );
  }


  void _showDoEditDialog(TimeSlot slot, String planned, String actual) {
    final TextEditingController actualController = TextEditingController(text: actual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        title: Text(
          '${slot.display} 실제 활동',
          style: const TextStyle(color: Color(0xFF3C2A21)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (planned.isNotEmpty) ...[
              Text(
                '계획: $planned',
                style: const TextStyle(
                  color: Color(0xFF8B7355),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: actualController,
              decoration: InputDecoration(
                hintText: '실제로 한 일을 입력하세요',
                hintStyle: const TextStyle(color: Color(0xFF9C8B73)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDD4C0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDD4C0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8B7355)),
                ),
                filled: true,
                fillColor: const Color(0xFFEFE7D3),
              ),
              style: const TextStyle(color: Color(0xFF3C2A21)),
              maxLines: 3,
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
          TextButton(
            onPressed: () async {
              final content = actualController.text.trim();
              try {
                await context.read<PDSDiaryProvider>().saveActualActivity(
                  _selectedDate,
                  slot.key,
                  content,
                );
                Navigator.of(context).pop();
                setState(() {}); // UI 업데이트
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('실제 활동이 저장되었습니다'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('저장 실패: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              '저장',
              style: TextStyle(color: Color(0xFF8B7355)),
            ),
          ),
        ],
      ),
    );
  }
}