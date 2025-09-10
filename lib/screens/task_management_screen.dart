import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../utils/helpers.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  String _selectedCategory = 'overdue';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategorySelector(),
            Expanded(
              child: _buildCategoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Text(
            '📋 할일 관리',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildCategoryButton('기한지남', 'overdue', '⚠️'),
          _buildCategoryButton('진행중', 'scheduled', '📅'),
          _buildCategoryButton('다음행동', 'nextAction', '⚡'),
          _buildCategoryButton('위임', 'delegated', '👥'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, String category, String icon) {
    final isActive = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        List<Item> items = [];
        
        switch (_selectedCategory) {
          case 'overdue':
            items = itemProvider.overdueItems;
            break;
          case 'scheduled':
            items = itemProvider.scheduledItems;
            break;
          case 'nextAction':
            items = itemProvider.nextActionItems;
            break;
          case 'delegated':
            items = itemProvider.delegatedItems;
            break;
        }

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildTaskItem(items[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    String icon = '';
    
    switch (_selectedCategory) {
      case 'overdue':
        message = '기한이 지난 할일이 없습니다';
        icon = '✅';
        break;
      case 'scheduled':
        message = '일정이 잡힌 할일이 없습니다';
        icon = '📅';
        break;
      case 'nextAction':
        message = '다음 행동이 없습니다';
        icon = '⚡';
        break;
      case 'delegated':
        message = '위임된 할일이 없습니다';
        icon = '👥';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildPriorityIndicator(item.priority),
            ],
          ),
          if (item.content != null && item.content!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.content!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (item.dueDate != null) ...[
                _buildInfoChip(
                  Icons.schedule,
                  DateFormat('M/d HH:mm').format(item.dueDate!),
                  const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
              ],
              if (item.estimatedDuration != null) ...[
                _buildInfoChip(
                  Icons.timer,
                  item.formattedDuration,
                  const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
              ],
              if (item.context != null) ...[
                _buildInfoChip(
                  Icons.place,
                  _getContextLabel(item.context!),
                  const Color(0xFF7C3AED),
                ),
              ],
            ],
          ),
          if (item.delegatedTo != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  '위임: ${item.delegatedTo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    Color color;
    String label;
    
    switch (priority) {
      case 1:
        color = const Color(0xFFDC2626);
        label = '긴급';
        break;
      case 2:
        color = const Color(0xFFF59E0B);
        label = '높음';
        break;
      case 3:
        color = const Color(0xFF059669);
        label = '보통';
        break;
      case 4:
        color = const Color(0xFF3B82F6);
        label = '낮음';
        break;
      default:
        color = const Color(0xFF64748B);
        label = '최저';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getContextLabel(Context context) {
    switch (context) {
      case Context.home:
        return '집';
      case Context.office:
        return '사무실';
      case Context.computer:
        return '컴퓨터';
      case Context.errands:
        return '외출';
      case Context.calls:
        return '전화';
      case Context.anywhere:
        return '어디서나';
    }
  }
}
