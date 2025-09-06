import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';

class ClarifyScreen extends StatefulWidget {
  const ClarifyScreen({super.key});

  @override
  State<ClarifyScreen> createState() => _ClarifyScreenState();
}

class _ClarifyScreenState extends State<ClarifyScreen> {
  bool? _isActionable;
  ClarificationType? _clarificationType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  // 현재 처리할 항목 (항상 첫 번째 항목)
  Item? get _currentItem {
    final itemProvider = context.read<ItemProvider>();
    if (itemProvider.inboxItems.isEmpty) {
      return null;
    }
    return itemProvider.inboxItems.first;
  }

  void _handleActionableChoice(bool actionable) {
    setState(() {
      _isActionable = actionable;
      _clarificationType = null;
    });
  }

  Future<void> _handleClarificationChoice(ClarificationType type, {DateTime? selectedDate, ItemType? itemType, Context? itemContext}) async {
    setState(() {
      _clarificationType = type;
    });

    if (_currentItem == null) return;

    try {
      Map<String, dynamic> updates = {
        'status': ItemStatus.clarified.name,
      };

      // 선택된 아이템 타입이 있으면 사용
      if (itemType != null) {
        updates['type'] = itemType.name;
      } else {
        // 기본 타입 설정
        switch (type) {
          case ClarificationType.schedule:
            updates['type'] = ItemType.task.name;
            break;
          case ClarificationType.nextAction:
            updates['type'] = ItemType.task.name;
            updates['status'] = ItemStatus.active.name;
            break;
          case ClarificationType.waitingFor:
            updates['status'] = ItemStatus.waiting.name;
            break;
          case ClarificationType.someday:
            updates['status'] = ItemStatus.someday.name;
            break;
          case ClarificationType.reference:
            updates['type'] = ItemType.note.name;
            break;
          case ClarificationType.project:
            updates['type'] = ItemType.project.name;
            break;
        }
      }

      // 선택된 날짜가 있으면 dueDate 설정
      if (selectedDate != null) {
        updates['due_date'] = selectedDate.toIso8601String();
      }

      // 선택된 맥락이 있으면 context 설정
      if (itemContext != null) {
        updates['context'] = itemContext.name;
      }

      await context.read<ItemProvider>().updateItem(_currentItem!.id, updates);
      
      // 다음 항목으로 이동
      _handleNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNext() {
    final itemProvider = context.read<ItemProvider>();
    
    // 상태 초기화 - 항목이 제거된 후 다음 항목 처리 준비
    setState(() {
      _isActionable = null;
      _clarificationType = null;
    });

    // 잠시 후 항목 목록이 업데이트되었는지 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final updatedProvider = context.read<ItemProvider>();
        if (updatedProvider.inboxItems.isEmpty) {
          // 모든 항목이 처리되었을 때 완료 메시지 표시
          _showCompletionDialog();
        }
      }
    });
  }

  void _handleSkip() {
    // 건너뛰기도 다음 항목으로 이동
    _handleNext();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('완료!'),
        content: const Text('모든 항목을 명료화했습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isActionable = null;
                _clarificationType = null;
              });
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<ItemProvider>(
          builder: (context, itemProvider, child) {
            if (itemProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_currentItem == null) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildHeader(itemProvider.inboxItems.length),
                Expanded(
                  child: _buildClarificationCard(),
                ),
                _buildBottomButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎉 명료화 완료!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '모든 항목이 정리되었습니다.',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '⚡ 명료화',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '남은 항목: $totalItems',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClarificationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentItem!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          if (_currentItem!.content != null) ...[
            const SizedBox(height: 8),
            Text(
              _currentItem!.content!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_isActionable == null) _buildActionableQuestion(),
          if (_isActionable == false) _buildNonActionableOptions(),
          if (_isActionable == true) _buildActionableOptions(),
        ],
      ),
    );
  }

  Widget _buildActionableQuestion() {
    return Column(
      children: [
        const Text(
          '실행 가능한가요?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleActionableChoice(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('예'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleActionableChoice(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('아니오'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNonActionableOptions() {
    return Column(
      children: [
        const Text(
          '어떻게 보관하시겠어요?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTypeButton('⏰', '나중에 보기', () => _handleClarificationChoice(ClarificationType.someday)),
            _buildTypeButton('📄', '중간작업물', () => _handleClarificationChoice(ClarificationType.reference)),
            _buildTypeButton('📚', '레퍼런스', () => _handleClarificationChoice(ClarificationType.reference)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionableOptions() {
    return Column(
      children: [
        const Text(
          '어떤 유형인가요?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // 2열 그리드로 배치
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildTypeButton('⏰', '다시알림', () => _handleReminderChoice()),
            _buildTypeButton('🔮', '언젠가', () => _handleClarificationChoice(ClarificationType.someday)),
            _buildTypeButton('👥', '위임', () => _handleClarificationChoice(ClarificationType.waitingFor)),
            _buildTypeButton('▶️', '다음행동', () => _handleNextActionChoice()),
            _buildTypeButton('📅', '일정', () => _handleScheduleChoice()),
            _buildTypeButton('🎯', '목표·프로젝트', () => _handleGoalProjectChoice()),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TextButton(
          onPressed: _handleSkip,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          child: const Text(
            '건너뛰기',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // 다시알림 선택 시 날짜 선택
  void _handleReminderChoice() {
    _showDatePicker((selectedDate) {
      _handleClarificationChoice(ClarificationType.someday, selectedDate: selectedDate);
    });
  }

  // 일정 선택 시 날짜 선택
  void _handleScheduleChoice() {
    _showDatePicker((selectedDate) {
      _handleClarificationChoice(ClarificationType.schedule, selectedDate: selectedDate);
    });
  }

  // 다음행동 선택 시 상황/맥락 선택
  void _handleNextActionChoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다음행동 상황 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContextOption('단순노동', '🔨', Context.errands),
            _buildContextOption('컴퓨터', '💻', Context.computer),
            _buildContextOption('스마트폰', '📱', Context.calls),
            _buildContextOption('집에서', '🏠', Context.home),
            _buildContextOption('사무실', '🏢', Context.office),
            _buildContextOption('밖에서', '🚶', Context.errands),
            _buildContextOption('어디서나', '🌍', Context.anywhere),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Widget _buildContextOption(String title, String icon, Context itemContext) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop();
        _handleClarificationChoice(ClarificationType.nextAction, itemContext: itemContext);
      },
    );
  }

  // 목표·프로젝트 선택 시 타입 선택
  void _handleGoalProjectChoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표·프로젝트 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🎯', style: TextStyle(fontSize: 24)),
              title: const Text('목표'),
              onTap: () {
                Navigator.of(context).pop();
                _handleClarificationChoice(ClarificationType.project, itemType: ItemType.goal);
              },
            ),
            ListTile(
              leading: const Text('📋', style: TextStyle(fontSize: 24)),
              title: const Text('프로젝트'),
              onTap: () {
                Navigator.of(context).pop();
                _handleClarificationChoice(ClarificationType.project, itemType: ItemType.project);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // 날짜 선택 다이얼로그
  void _showDatePicker(Function(DateTime) onDateSelected) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    ).then((selectedDate) {
      if (selectedDate != null) {
        onDateSelected(selectedDate);
      }
    });
  }
}