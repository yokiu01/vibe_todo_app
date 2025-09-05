import 'package:flutter/material.dart';

class ScoreWidgetV2 extends StatefulWidget {
  final String taskId;
  final Function(int) onScoreChanged;

  const ScoreWidgetV2({
    super.key,
    required this.taskId,
    required this.onScoreChanged,
  });

  @override
  State<ScoreWidgetV2> createState() => _ScoreWidgetV2State();
}

class _ScoreWidgetV2State extends State<ScoreWidgetV2> {
  int _currentScore = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final score = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentScore = score;
            });
            widget.onScoreChanged(score);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              Icons.star,
              size: 16,
              color: score <= _currentScore 
                  ? Colors.amber 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }
}
