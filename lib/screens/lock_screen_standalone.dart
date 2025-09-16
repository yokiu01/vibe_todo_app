import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../models/pds_plan.dart';
import '../services/lock_screen_service.dart';

// LockScreenActivity 전용 독립 화면
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkEditPermission();
    _loadData();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'showLockScreen':
          print('LockScreenStandalone: showLockScreen called');
          // 이미 표시되어 있으므로 아무것도 하지 않음
          break;
      }
    });
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
          await context.read<PDSDiaryProvider>().loadPDSPlans();
        } catch (e) {
          print('Error loading PDS plans: $e');
        }
      }
    });
  }

  void _closeLockScreen() async {
    try {
      await _channel.invokeMethod('closeLockScreen');
    } catch (e) {
      print('Error closing lock screen: $e');
      // 폴백: SystemNavigator 사용
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildPlanDoSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
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

        final currentHour = DateTime.now().hour;
        final relevantSlots = timeSlots.where((slot) {
          return slot.hour24 >= currentHour && slot.hour24 < currentHour + 6;
        }).toList();

        return Container(
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
                      '다음 6시간의 계획',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: relevantSlots.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  final slot = relevantSlots[index];
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3B82F6),
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
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
                      ],
                    ),
                  );
                },
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
                  onTap: () => _openMainApp(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_note,
                  label: 'DO 기록',
                  onTap: _canEdit ? () => _openMainApp() : null,
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
              onTap: () => _closeLockScreen(),
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

  void _openMainApp() {
    // 메인 앱 열기 (MainActivity)
    _closeLockScreen();
  }
}