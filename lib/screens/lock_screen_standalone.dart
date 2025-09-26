import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../models/pds_plan.dart';
import '../services/lock_screen_service.dart';

// Korean Localization Helper
class KoreanLocalizer {
  static String formatDate(DateTime date) {
    const monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    const dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

    final month = monthNames[date.month - 1];
    final day = '${date.day}일';
    final weekday = dayNames[date.weekday - 1];

    return '$month $day $weekday';
  }

  static String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  static String formatTimeRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }
}

// 메인 앱 화면과 동일한 색상 체계를 적용한 잠금화면
class LockScreenColors {
  // 메인 앱과 동일한 베이지/크림 배경
  static const backgroundColor = Color(0xFFF5EFE7);  // 메인 앱 배경색

  // 텍스트 색상 (어두운 색 기반)
  static const textPrimary = Color(0xFF3C2A21);      // 진한 갈색 텍스트
  static const textSecondary = Color(0xFF8B7355);    // 메인 primary 색상
  static const textTertiary = Color(0xFF9E8B7A);     // 연한 갈색

  // 카드/컨테이너 배경
  static const cardBackground = Color(0xFFFFFFFF);   // 흰색 카드 배경
  static const cardBorder = Color(0xFFE8DCC6);       // 연한 베이지 테두리
  static const cardShadow = Color(0x0F000000);       // 연한 그림자

  // 버튼 색상
  static const buttonBackground = Color(0xFFFFFFFF); // 흰색 버튼 배경
  static const buttonBorder = Color(0xFFE8DCC6);     // 버튼 테두리
  static const buttonIcon = Color(0xFF8B7355);       // 버튼 아이콘
  static const buttonText = Color(0xFF3C2A21);       // 버튼 텍스트

  // 강조 색상
  static const accentBackground = Color(0xFF8B7355); // 강조 배경
  static const accentText = Color(0xFFFFFFFF);       // 강조 텍스트
}

// Simple PDS Plan Item for Lock Screen - View Only
class LockScreenPlanItem {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String type;
  final String status;

  LockScreenPlanItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.type,
    required this.status,
  });
}

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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeAnimations();
    _loadData();
    _setupUI();
    _initializeLockScreenOnly();
  }

  void _initializeLockScreenOnly() {
    print('Lock screen standalone initialized - fast mode');
  }

  void _setupUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
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

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          await context.read<PDSDiaryProvider>().loadPDSPlansForLockScreen();
          print('Lock screen data loaded - fast mode');
        } catch (e) {
          print('Error loading lock screen data: $e');
        }
      }
    });
  }

  void _closeLockScreen() async {
    try {
      await _channel.invokeMethod('closeLockScreen');
    } catch (e) {
      print('Error closing lock screen: $e');
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

  // Get today's events from PDS plan data - simple view only
  List<LockScreenPlanItem> _getTodayEvents(PDSPlan? currentPlan) {
    if (currentPlan == null) return [];

    final events = <LockScreenPlanItem>[];
    final now = DateTime.now();

    // Convert freeform plans to schedule items
    currentPlan.freeformPlans?.forEach((timeKey, planText) {
      if (planText.isNotEmpty) {
        final timeSlot = PDSPlan.generateTimeSlots()
            .firstWhere((slot) => slot.key == timeKey, orElse: () => TimeSlot(
              hour24: 9,
              display: '9시',
              display12: '오전 9:00',
              key: 'am_9'
            ));

        final startTime = DateTime(now.year, now.month, now.day, timeSlot.hour24);
        final endTime = startTime.add(const Duration(hours: 1));

        // 완료 표시(✅) 제거하고 제목만 표시
        String displayTitle = planText;
        if (planText.startsWith('✅ ')) {
          displayTitle = planText.substring(2).trim();
        }

        events.add(LockScreenPlanItem(
          id: timeKey,
          title: displayTitle,
          startTime: startTime,
          endTime: endTime,
          type: 'work',
          status: 'upcoming', // 모든 일정을 단순히 보기용으로 처리
        ));
      }
    });

    // Sort by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    print('🔒 LockScreenStandalone: Building LockScreenStandalone widget');
    return Scaffold(
      body: Container(
        color: LockScreenColors.backgroundColor,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // 헤더
                  _buildHeader(),
                  const SizedBox(height: 32),
                  // 단일 박스 내에 모든 일정 표시
                  Expanded(
                    child: _buildUnifiedEventsList(),
                  ),
                  const SizedBox(height: 32),
                  // 하단 버튼들
                  _buildBottomButtons(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 큰 시간 표시
          Text(
            DateFormat('H:mm').format(now),
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w300,
              color: LockScreenColors.textPrimary,
              letterSpacing: -3.0,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          // 한국어 날짜
          Text(
            KoreanLocalizer.formatDate(now),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: LockScreenColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // 단일 박스 내에 모든 일정 표시
  Widget _buildUnifiedEventsList() {
    return Consumer<PDSDiaryProvider>(
      builder: (context, pdsProvider, child) {
        final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
        final todayEvents = _getTodayEvents(currentPlan);

        if (todayEvents.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: LockScreenColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: LockScreenColors.cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: LockScreenColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LockScreenColors.accentBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.today,
                      size: 16,
                      color: LockScreenColors.accentText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '오늘의 할일',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: LockScreenColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: LockScreenColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${todayEvents.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LockScreenColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 일정 리스트
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ...todayEvents.map((event) => _buildSimpleEventCard(event)).toList(),
                      const SizedBox(height: 8),
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

  // 간단한 일정 카드 - 완료 기능 없이 보기만
  Widget _buildSimpleEventCard(LockScreenPlanItem event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LockScreenColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LockScreenColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LockScreenColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 시간 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: LockScreenColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              KoreanLocalizer.formatTime(event.startTime),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LockScreenColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 할일 제목
          Expanded(
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: LockScreenColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 빈 상태
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LockScreenColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: LockScreenColors.cardBorder,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 36,
              color: LockScreenColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '오늘은 여유로운 하루네요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: LockScreenColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '새로운 일정을 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: LockScreenColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 하단 버튼들
  Widget _buildBottomButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // 닫기 버튼
          Expanded(
            child: GestureDetector(
              onTap: _closeLockScreen,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: LockScreenColors.buttonBackground,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: LockScreenColors.buttonBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LockScreenColors.cardShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close,
                      size: 24,
                      color: LockScreenColors.buttonIcon,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: LockScreenColors.buttonText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 앱열기 버튼 - 닫기 버튼과 동일한 스타일
          Expanded(
            child: GestureDetector(
              onTap: _openMainApp,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: LockScreenColors.buttonBackground,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: LockScreenColors.buttonBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LockScreenColors.cardShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.launch,
                      size: 24,
                      color: LockScreenColors.buttonIcon,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '앱열기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: LockScreenColors.buttonText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메인 앱 열기 메서드 - 직접 앱 시작
  void _openMainApp() async {
    try {
      // 잠금화면을 닫고 메인 앱으로 이동
      await _channel.invokeMethod('openMainApp');
    } catch (e) {
      print('Error opening main app with native method: $e');
      try {
        // 대안 1: 잠금화면을 닫고 사용자가 직접 열도록 함
        await _channel.invokeMethod('closeLockScreen');
      } catch (e2) {
        print('Error closing lock screen: $e2');
        // 대안 2: Flutter Navigator로 메인 앱 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    }
  }
}