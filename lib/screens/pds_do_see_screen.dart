import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pds_diary_provider.dart';
import '../models/pds_plan.dart';

class PDSDoSeeScreen extends StatefulWidget {
  const PDSDoSeeScreen({super.key});

  @override
  State<PDSDoSeeScreen> createState() => _PDSDoSeeScreenState();
}

class _PDSDoSeeScreenState extends State<PDSDoSeeScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _actualActivities = {};
  String _seeNotes = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDSDiaryProvider>().loadPDSPlans();
      _loadCurrentPlan();
    });
  }

  void _loadCurrentPlan() {
    final pdsProvider = context.read<PDSDiaryProvider>();
    final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
    
    if (currentPlan != null) {
      setState(() {
        _actualActivities = currentPlan.actualActivities ?? {};
        _seeNotes = currentPlan.seeNotes ?? '';
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
              child: _buildDoSeeLayout(),
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
            '✅ DO-SEE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoSeeLayout() {
    return Consumer<PDSDiaryProvider>(
      builder: (context, pdsProvider, child) {
        final timeSlots = PDSPlan.generateTimeSlots();
        final currentPlan = pdsProvider.getPDSPlan(_selectedDate);
        final plannedActivities = currentPlan?.freeformPlans ?? {};

        return SingleChildScrollView(
          child: Column(
            children: [
              // DO 레이아웃
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측: PLAN에서 작성한 내용
                  Expanded(
                    flex: 2,
                    child: _buildLeftColumn(timeSlots, plannedActivities),
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

  Widget _buildLeftColumn(List<TimeSlot> timeSlots, Map<String, String> plannedActivities) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildColumnHeader('PLAN'),
          ...timeSlots.map((slot) => _buildPlannedDisplay(slot, plannedActivities)),
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

  Widget _buildPlannedDisplay(TimeSlot slot, Map<String, String> plannedActivities) {
    final plannedText = plannedActivities[slot.key] ?? '';
    
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        plannedText,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF64748B),
          fontStyle: FontStyle.italic,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
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
        decoration: const InputDecoration(
          hintText: '실제로 한 일',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          contentPadding: EdgeInsets.all(8),
          hintStyle: TextStyle(fontSize: 11),
        ),
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        onChanged: (value) {
          setState(() {
            _actualActivities[slot.key] = value;
          });
          _saveActualActivity(slot.key, value);
        },
        controller: TextEditingController(
          text: _actualActivities[slot.key] ?? '',
        ),
      ),
    );
  }

  Widget _buildSeeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 SEE (오늘의 회고)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: '오늘 하루를 돌아보며 느낀 점, 배운 점, 개선할 점 등을 자유롭게 적어보세요...',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14),
            maxLines: 6,
            onChanged: (value) {
              setState(() {
                _seeNotes = value;
              });
              _saveSeeNotes(value);
            },
            controller: TextEditingController(text: _seeNotes),
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

