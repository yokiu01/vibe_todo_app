import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../utils/helpers.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {}); // 텍스트 변화 감지하여 UI 업데이트
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isAdding = true;
    });

    try {
      await context.read<ItemProvider>().addItem(
        title: _textController.text.trim(),
      );
      _textController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('항목이 수집함에 추가되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
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
            _buildInputSection(),
            _buildQuickActions(),
            _buildRecentItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🧠 수집함',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${itemProvider.inboxItems.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '무엇이든 적어보세요...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addItem(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _textController.text.trim().isNotEmpty && !_isAdding
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _textController.text.trim().isNotEmpty && !_isAdding
                  ? _addItem
                  : null,
              icon: _isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.mic, '음성입력', const Color(0xFF2563EB)),
          _buildActionButton(Icons.camera_alt, '사진', const Color(0xFF2563EB)),
          _buildActionButton(Icons.edit, '텍스트', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 기능은 준비 중입니다')),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItems() {
    return Expanded(
      child: Consumer<ItemProvider>(
        builder: (context, itemProvider, child) {
          if (itemProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (itemProvider.inboxItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '수집함이 비어있습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '위에 무언가를 입력해보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '📋 최근 수집한 항목들',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: itemProvider.inboxItems.length,
                  itemBuilder: (context, index) {
                    final item = itemProvider.inboxItems[index];
                    return _buildInboxItem(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInboxItem(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFF94A3B8), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.content != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.content!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatTime(item.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Helpers.getRelativeTime(item.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
