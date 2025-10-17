import 'package:flutter/material.dart';
import '../models/notion_block.dart';
import '../services/notion_api_service.dart';

/// Notion 스타일의 블록 기반 편집기
/// 각 블록을 인라인으로 편집하고 실시간으로 Notion API와 동기화
class NotionBlockEditor extends StatefulWidget {
  final String pageId;
  final NotionApiService notionService;

  const NotionBlockEditor({
    super.key,
    required this.pageId,
    required this.notionService,
  });

  @override
  State<NotionBlockEditor> createState() => _NotionBlockEditorState();
}

class _NotionBlockEditorState extends State<NotionBlockEditor> {
  List<NotionBlock> _blocks = [];
  bool _isLoading = true;
  Map<String, TextEditingController> _controllers = {};
  Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// 페이지의 모든 블록 로드
  Future<void> _loadBlocks() async {
    setState(() => _isLoading = true);
    try {
      final blocksJson = await widget.notionService.getBlockChildren(widget.pageId);

      // Convert JSON to NotionBlock objects
      final blocks = blocksJson
          .map((json) => NotionBlock.fromJson(json))
          .toList();

      setState(() {
        _blocks = blocks;
        _isLoading = false;

        // Create controllers for each block
        for (var block in _blocks) {
          _controllers[block.id] = TextEditingController(text: block.plainText);
          _focusNodes[block.id] = FocusNode();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('블록 로드 실패: $e')),
        );
      }
    }
  }

  /// 블록 텍스트 업데이트
  Future<void> _updateBlock(NotionBlock block, String newText) async {
    try {
      final blockData = {
        'type': block.type,
        block.type: {
          'rich_text': [
            {
              'type': 'text',
              'text': {'content': newText},
            }
          ],
          // to_do 블록인 경우 checked 상태 유지
          if (block.type == 'to_do') 'checked': block.isChecked,
        },
      };

      await widget.notionService.updateBlock(block.id, blockData);

      // Update local state
      setState(() {
        final index = _blocks.indexWhere((b) => b.id == block.id);
        if (index != -1) {
          _blocks[index] = block.updateText(newText);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('블록 업데이트 실패: $e')),
        );
      }
    }
  }

  /// 새 블록 추가
  Future<void> _addBlock(int afterIndex, {String type = 'paragraph'}) async {
    try {
      // 임시 블록 생성
      NotionBlock newBlock;
      switch (type) {
        case 'heading_1':
        case 'heading_2':
        case 'heading_3':
          final level = int.parse(type.split('_').last);
          newBlock = NotionBlock.createHeading('', level);
          break;
        case 'to_do':
          newBlock = NotionBlock.createTodo('', false);
          break;
        default:
          newBlock = NotionBlock.createParagraph('');
      }

      // API를 통해 블록 추가
      final blockData = newBlock.toJson();
      await widget.notionService.appendBlockChildren(widget.pageId, [blockData]);

      // 블록 다시 로드
      await _loadBlocks();

      // 새 블록에 포커스
      if (_blocks.length > afterIndex + 1) {
        final newBlockId = _blocks[afterIndex + 1].id;
        _focusNodes[newBlockId]?.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('블록 추가 실패: $e')),
        );
      }
    }
  }

  /// 블록 삭제
  Future<void> _deleteBlock(NotionBlock block) async {
    try {
      await widget.notionService.deleteBlock(block.id);

      setState(() {
        _blocks.removeWhere((b) => b.id == block.id);
        _controllers[block.id]?.dispose();
        _focusNodes[block.id]?.dispose();
        _controllers.remove(block.id);
        _focusNodes.remove(block.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('블록 삭제 실패: $e')),
        );
      }
    }
  }

  /// 블록 복제
  Future<void> _duplicateBlock(NotionBlock block, int index) async {
    try {
      final blockData = block.toJson();
      await widget.notionService.appendBlockChildren(widget.pageId, [blockData]);
      await _loadBlocks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('블록 복제 실패: $e')),
        );
      }
    }
  }

  /// To-do 블록 체크 상태 토글
  Future<void> _toggleTodoCheck(NotionBlock block) async {
    try {
      final newChecked = !block.isChecked;
      final blockData = {
        'type': 'to_do',
        'to_do': {
          'rich_text': [
            {
              'type': 'text',
              'text': {'content': block.plainText},
            }
          ],
          'checked': newChecked,
        },
      };

      await widget.notionService.updateBlock(block.id, blockData);

      setState(() {
        final index = _blocks.indexWhere((b) => b.id == block.id);
        if (index != -1) {
          _blocks[index] = block.toggleChecked();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('체크 상태 변경 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('블록이 없습니다'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addBlock(-1),
              icon: const Icon(Icons.add),
              label: const Text('블록 추가'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _blocks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final block = _blocks[index];
        return _buildBlockWidget(block, index);
      },
    );
  }

  /// 블록 타입에 따라 적절한 위젯 생성
  Widget _buildBlockWidget(NotionBlock block, int index) {
    final controller = _controllers[block.id];
    final focusNode = _focusNodes[block.id];

    if (controller == null || focusNode == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 블록 타입 아이콘 및 액션 버튼
          _buildBlockActions(block, index),

          const SizedBox(width: 8),

          // 블록 콘텐츠
          Expanded(
            child: _buildBlockContent(block, controller, focusNode, index),
          ),
        ],
      ),
    );
  }

  /// 블록 액션 버튼 (드래그, 메뉴 등)
  Widget _buildBlockActions(NotionBlock block, int index) {
    return PopupMenuButton<String>(
      icon: Icon(
        _getBlockIcon(block),
        size: 20,
        color: Colors.grey[600],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('복제'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('삭제', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_below',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('아래에 블록 추가'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'duplicate':
            _duplicateBlock(block, index);
            break;
          case 'delete':
            _deleteBlock(block);
            break;
          case 'add_below':
            _addBlock(index);
            break;
        }
      },
    );
  }

  /// 블록 타입에 맞는 아이콘 반환
  IconData _getBlockIcon(NotionBlock block) {
    switch (block.type) {
      case 'heading_1':
        return Icons.title;
      case 'heading_2':
        return Icons.text_fields;
      case 'heading_3':
        return Icons.short_text;
      case 'to_do':
        return Icons.check_box_outlined;
      case 'toggle':
        return Icons.arrow_right;
      default:
        return Icons.drag_indicator;
    }
  }

  /// 블록 콘텐츠 위젯 생성
  Widget _buildBlockContent(
    NotionBlock block,
    TextEditingController controller,
    FocusNode focusNode,
    int index,
  ) {
    // To-do 블록
    if (block.type == 'to_do') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: block.isChecked,
            onChanged: (_) => _toggleTodoCheck(block),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'To-do',
              ),
              style: TextStyle(
                decoration: block.isChecked ? TextDecoration.lineThrough : null,
              ),
              onChanged: (text) => _updateBlock(block, text),
              onSubmitted: (_) => _addBlock(index),
            ),
          ),
        ],
      );
    }

    // 헤딩 블록
    if (block.type.startsWith('heading_')) {
      final level = block.headingLevel ?? 1;
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Heading $level',
        ),
        style: TextStyle(
          fontSize: level == 1 ? 24 : (level == 2 ? 20 : 18),
          fontWeight: FontWeight.bold,
        ),
        onChanged: (text) => _updateBlock(block, text),
        onSubmitted: (_) => _addBlock(index),
      );
    }

    // 일반 텍스트 블록
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: '내용을 입력하세요',
      ),
      maxLines: null,
      onChanged: (text) => _updateBlock(block, text),
      onSubmitted: (_) => _addBlock(index),
    );
  }
}
