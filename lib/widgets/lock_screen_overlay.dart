import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../models/pds_plan.dart';
import '../services/lock_screen_service.dart';

class LockScreenOverlay extends StatefulWidget {
  const LockScreenOverlay({super.key});

  @override
  State<LockScreenOverlay> createState() => _LockScreenOverlayState();
}

class _LockScreenOverlayState extends State<LockScreenOverlay> {
  DateTime _selectedDate = DateTime.now();
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _checkLockScreenSettings();
  }

  Future<void> _checkLockScreenSettings() async {
    final isEnabled = await LockScreenService.isLockScreenEnabled();
    if (!isEnabled) {
      Navigator.of(context).pop();
    }
  }

  void _dismiss() {
    setState(() {
      _isVisible = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '📅 오늘의 계획 & 실행',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _dismiss,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<PDSDiaryProvider>(
      builder: (context, pdsProvider, child) {
        final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
        final timeSlots = PDSPlan.generateTimeSlots();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildTimeTable(timeSlots, currentPlan),
              const SizedBox(height: 16),
              if (currentPlan?.seeNotes?.isNotEmpty == true) ...[
                _buildSeeSection(currentPlan!.seeNotes!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeTable(List<TimeSlot> timeSlots, PDSPlan? currentPlan) {
    final plannedActivities = currentPlan?.freeformPlans ?? {};
    final actualActivities = currentPlan?.actualActivities ?? {};

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'PLAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '시간',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ...timeSlots.take(12).map((slot) => _buildTimeRow(
                slot,
                plannedActivities[slot.key] ?? '',
                actualActivities[slot.key] ?? '',
              )),
        ],
      ),
    );
  }

  Widget _buildTimeRow(TimeSlot slot, String planned, String actual) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: planned.isNotEmpty ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                planned.isEmpty ? '-' : planned,
                style: TextStyle(
                  fontSize: 11,
                  color: planned.isNotEmpty ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              slot.display,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: actual.isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                actual.isEmpty ? '-' : actual,
                style: TextStyle(
                  fontSize: 11,
                  color: actual.isNotEmpty ? const Color(0xFF15803D) : const Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeSection(String seeNotes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD97706)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 오늘의 회고',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            seeNotes,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

// 잠금화면 오버레이를 표시하는 함수
Future<void> showLockScreenOverlay(BuildContext context) async {
  final isEnabled = await LockScreenService.isLockScreenEnabled();
  if (!isEnabled) return;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const LockScreenOverlay(),
  );
}