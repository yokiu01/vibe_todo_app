import 'package:flutter/material.dart';

class MemoPadWidgetV2 extends StatefulWidget {
  const MemoPadWidgetV2({super.key});

  @override
  State<MemoPadWidgetV2> createState() => _MemoPadWidgetV2State();
}

class _MemoPadWidgetV2State extends State<MemoPadWidgetV2> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '메모 패드',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _clearContent,
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // 메모 영역
          Expanded(
            child: _buildTextArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: '하루를 메모해보세요...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
        maxLines: 3,
        textAlignVertical: TextAlignVertical.top,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _clearContent() {
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
