import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../models/pds_plan.dart';
import '../services/lock_screen_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
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
    // Post frame callback을 사용하여 build 사이클 이후 호출
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          await context.read<PDSDiaryProvider>().loadPDSPlans();
        } catch (e) {
          print('Error loading PDS plans: $e');
        }
      }
    });
  }

  void _scrollToCurrentTime() {
    // 현재 시간에 해당하는 스크롤 위치 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final currentHour = DateTime.now().hour;
        final timeSlots = PDSDiaryProvider().getPDSPlan(_selectedDate) != null 
            ? PDSPlan.generateTimeSlots() 
            : <TimeSlot>[];
        
        // 현재 시간에 해당하는 인덱스 찾기
        int currentIndex = 0;
        for (int i = 0; i < timeSlots.length; i++) {
          if (timeSlots[i].hour24 == currentHour) {
            currentIndex = i;
            break;
          }
        }
        
        // 스크롤 위치 계산 (각 아이템 높이 약 80px)
        final scrollOffset = currentIndex * 80.0;
        _scrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
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
                  const SizedBox(height: 16),
                  // 하단 고정 버튼들
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildQuickActions(),
                  ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: const Text(
              '✨ Plan · Do · See',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
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

        return Container(
          height: 400, // 고정 높이 설정
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '오늘의 계획 & 실행',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: timeSlots.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final slot = timeSlots[index];
                    final planned = plannedActivities[slot.key] ?? '';
                    final actual = actualActivities[slot.key] ?? '';
                    final isCurrentHour = slot.hour24 == DateTime.now().hour;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentHour
                            ? const Color(0xFF3B82F6).withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              slot.display,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrentHour ? FontWeight.w600 : FontWeight.w400,
                                color: isCurrentHour
                                    ? const Color(0xFF60A5FA)
                                    : Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (planned.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          planned,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (actual.isNotEmpty) const SizedBox(height: 4),
                                ],
                                if (actual.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '실제: $actual',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (planned.isEmpty && actual.isEmpty)
                                  Text(
                                    '계획된 활동 없음',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.4),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // DO 편집 버튼 추가
                          if (_canEdit)
                            GestureDetector(
                              onTap: () => _showDoEditDialog(slot, planned, actual),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            '빠른 작업',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.playlist_add_check,
                  label: '계획 보기',
                  onTap: () => _openPlanPage(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_note,
                  label: 'DO 기록',
                  onTap: _canEdit ? () => _openDoPage() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.close,
              label: '닫기',
              onTap: () {
                // 확실히 닫기 위해 여러 방법 시도
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // Navigator.pop이 안 되면 root context로 시도
                  Navigator.of(context, rootNavigator: true).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.4),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlanPage() {
    // Navigate to planning screen
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
    // You might want to navigate to a specific tab in the main app
  }

  void _openDoPage() {
    // Navigate to do-see screen
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
    // You might want to navigate to a specific tab in the main app
  }

  void _showDoEditDialog(TimeSlot slot, String planned, String actual) {
    final TextEditingController actualController = TextEditingController(text: actual);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          '${slot.display} 실제 활동',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (planned.isNotEmpty) ...[
              Text(
                '계획: $planned',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: actualController,
              decoration: InputDecoration(
                hintText: '실제로 한 일을 입력하세요',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}

// 잠금화면이 이미 표시되고 있는지 확인하는 플래그
bool _isLockScreenShowing = false;

// Function to show lock screen
Future<void> showLockScreen(BuildContext context) async {
  print('showLockScreen called');
  
  // 이미 잠금화면이 표시되고 있으면 중복 호출 방지
  if (_isLockScreenShowing) {
    print('showLockScreen - already showing, returning');
    return;
  }
  
  final isEnabled = await LockScreenService.isLockScreenEnabled();
  print('showLockScreen - isEnabled: $isEnabled');
  if (!isEnabled) {
    print('showLockScreen - lock screen not enabled, returning');
    return;
  }

  print('showLockScreen - showing lock screen');
  _isLockScreenShowing = true;
  
  try {
    // Provider로 감싼 LockScreen 사용
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PDSDiaryProvider()),
          ],
          child: const LockScreen(),
        ),
        fullscreenDialog: true,
        maintainState: false,
      ),
    );
    print('showLockScreen - lock screen closed');
  } catch (e) {
    print('showLockScreen - error: $e');
  } finally {
    // 잠금화면이 닫힐 때 플래그 리셋
    _isLockScreenShowing = false;
  }
}