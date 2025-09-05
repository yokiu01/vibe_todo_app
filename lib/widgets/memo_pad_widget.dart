import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

class MemoPadWidget extends StatefulWidget {
  const MemoPadWidget({super.key});

  @override
  State<MemoPadWidget> createState() => _MemoPadWidgetState();
}

class _MemoPadWidgetState extends State<MemoPadWidget> {
  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  final TextEditingController _textController = TextEditingController();
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note),
                const SizedBox(width: 8),
                const Text('메모 패드'),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isDrawing ? Icons.text_fields : Icons.brush),
                      onPressed: _toggleMode,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearContent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 메모 영역
          Expanded(
            child: _isDrawing ? _buildDrawingPad() : _buildTextPad(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _textController,
        decoration: const InputDecoration(
          hintText: '메모를 입력하세요...',
          border: InputBorder.none,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  Widget _buildDrawingPad() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Signature(
        key: _signatureKey,
        color: Colors.black,
        strokeWidth: 2.0,
        backgroundPainter: _BackgroundPainter(),
        onSign: () {
          // 서명이 완료되었을 때의 처리
        },
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isDrawing = !_isDrawing;
    });
  }

  void _clearContent() {
    if (_isDrawing) {
      _signatureKey.currentState?.clear();
    } else {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.0;

    // 격자 패턴 그리기
    const double spacing = 20.0;
    
    // 세로선
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // 가로선
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
