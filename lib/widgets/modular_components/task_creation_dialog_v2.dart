import 'package:flutter/material.dart';
import '../../models/task.dart';

class TaskCreationDialogV2 extends StatefulWidget {
  final DateTime initialTime;
  final Task? initialTask; // 기존 작업 (수정 모드일 때)
  final Function(Task) onTaskCreated;

  const TaskCreationDialogV2({
    super.key,
    required this.initialTime,
    this.initialTask,
    required this.onTaskCreated,
  });

  @override
  State<TaskCreationDialogV2> createState() => _TaskCreationDialogV2State();
}

class _TaskCreationDialogV2State extends State<TaskCreationDialogV2> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskCategory _selectedCategory = TaskCategory.work;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    
    if (widget.initialTask != null) {
      // 수정 모드: 기존 작업 데이터로 초기화
      final task = widget.initialTask!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedCategory = task.category;
      _startTime = task.startTime;
      _endTime = task.endTime;
    } else {
      // 생성 모드: 기본값으로 초기화
      _startTime = widget.initialTime;
      _endTime = widget.initialTime.add(const Duration(minutes: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        widget.initialTask != null ? '작업 수정' : '새 작업 추가',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: '제목',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: '설명 (선택사항)',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // 카테고리 선택
            DropdownButtonFormField<TaskCategory>(
              value: _selectedCategory,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: '카테고리',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: TaskCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.displayName,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // 시간 선택
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '시작 시간',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: _selectStartTime,
                          child: Text(
                            _formatTime(_startTime),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '종료 시간',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: _selectEndTime,
                          child: Text(
                            _formatTime(_endTime),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: _createTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(widget.initialTask != null ? '수정' : '추가'),
        ),
      ],
    );
  }

  void _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    
    if (picked != null) {
      setState(() {
        // 날짜는 initialTime의 날짜로 유지, 시간만 변경
        _startTime = DateTime(
          widget.initialTime.year,
          widget.initialTime.month,
          widget.initialTime.day,
          picked.hour,
          picked.minute,
        );
        if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
          _endTime = _startTime.add(const Duration(minutes: 30));
        }
      });
    }
  }

  void _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    
    if (picked != null) {
      setState(() {
        // 날짜는 initialTime의 날짜로 유지, 시간만 변경
        _endTime = DateTime(
          widget.initialTime.year,
          widget.initialTime.month,
          widget.initialTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('제목을 입력해주세요'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final task = widget.initialTask != null 
        ? widget.initialTask!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            category: _selectedCategory,
            updatedAt: DateTime.now(),
          )
        : Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            category: _selectedCategory,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    print('${widget.initialTask != null ? 'Updating' : 'Creating'} task: ${task.title} at ${task.startTime}');
    
    // 작업 생성/수정 후 콜백 호출
    widget.onTaskCreated(task);
    
    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('작업이 ${widget.initialTask != null ? '수정' : '추가'}되었습니다: ${task.title}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 다이얼로그 닫기
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}