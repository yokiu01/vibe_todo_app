import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../utils/app_colors.dart';

class RoutineFormScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineFormScreen({super.key, this.routine});

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeController;

  String _category = '🏠 생활';
  int _estimatedMinutes = 30;
  List<String> _frequency = ['매일'];

  final List<String> _categories = [
    '🏃 운동',
    '📚 공부',
    '🧘 명상',
    '💼 업무',
    '🏠 생활',
  ];

  final List<String> _frequencies = [
    '매일',
    '주중',
    '주말',
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.title);
    _descriptionController = TextEditingController(text: widget.routine?.description);
    _timeController = TextEditingController(text: widget.routine?.scheduledTime ?? '08:00');

    if (widget.routine != null) {
      _category = widget.routine!.category ?? _category;
      _estimatedMinutes = widget.routine!.estimatedMinutes ?? _estimatedMinutes;
      _frequency = widget.routine!.frequency.isNotEmpty
          ? List.from(widget.routine!.frequency)
          : ['매일'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.routine == null ? '루틴 추가' : '루틴 수정'),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        actions: [
          if (widget.routine != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteRoutine,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '루틴 이름',
                hintText: '예: 아침 운동',
                prefixIcon: Icon(Icons.title, color: AppColors.accentBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? '이름을 입력하세요' : null,
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '설명 (선택)',
                hintText: '이 루틴에 대한 간단한 설명',
                prefixIcon: Icon(Icons.description, color: AppColors.accentBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: '카테고리',
                prefixIcon: Icon(Icons.category, color: AppColors.accentBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),

            // Time Picker
            TextFormField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: '수행 시간 (HH:MM)',
                hintText: '08:00',
                prefixIcon: Icon(Icons.access_time, color: AppColors.accentBlue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: _selectTime,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              readOnly: true,
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),

            // Duration Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '예상 소요 시간',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$_estimatedMinutes분',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _estimatedMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$_estimatedMinutes분',
                    activeColor: AppColors.accentBlue,
                    onChanged: (value) => setState(() => _estimatedMinutes = value.toInt()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Frequency Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '반복 주기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _frequencies.map((day) {
                      final isSelected = _frequency.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              // Remove conflicting selections
                              if (day == '매일') {
                                _frequency.clear();
                              } else if (_frequency.contains('매일')) {
                                _frequency.remove('매일');
                              }

                              if (day == '주중') {
                                _frequency.removeWhere((d) =>
                                    ['월', '화', '수', '목', '금'].contains(d));
                              } else if (day == '주말') {
                                _frequency.removeWhere((d) =>
                                    ['토', '일'].contains(d));
                              } else if (['월', '화', '수', '목', '금'].contains(day)) {
                                _frequency.remove('주중');
                              } else if (['토', '일'].contains(day)) {
                                _frequency.remove('주말');
                              }

                              _frequency.add(day);
                            } else {
                              _frequency.remove(day);
                            }
                          });
                        },
                        selectedColor: AppColors.accentBlue.withOpacity(0.3),
                        checkmarkColor: AppColors.accentBlue,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.accentBlue
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.routine == null ? '루틴 추가' : '수정 완료',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(_timeController.text),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_frequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반복 주기를 선택하세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<RoutineProvider>();

    try {
      if (widget.routine == null) {
        // Create new routine
        final newRoutine = Routine(
          id: '', // Will be set by Notion
          title: _nameController.text,
          frequency: _frequency,
          scheduledTime: _timeController.text,
          status: 'Active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          category: _category,
          estimatedMinutes: _estimatedMinutes,
        );

        final success = await provider.createRoutine(newRoutine);

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('루틴이 생성되었습니다')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: ${provider.error ?? "알 수 없는 오류"}')),
          );
        }
      } else {
        // Update existing routine
        final updatedRoutine = widget.routine!.copyWith(
          title: _nameController.text,
          frequency: _frequency,
          scheduledTime: _timeController.text,
          updatedAt: DateTime.now(),
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          category: _category,
          estimatedMinutes: _estimatedMinutes,
        );

        final success = await provider.updateRoutine(
          widget.routine!.id,
          updatedRoutine,
        );

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('루틴이 수정되었습니다')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수정 실패: ${provider.error ?? "알 수 없는 오류"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRoutine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: const Text('이 루틴을 삭제하시겠습니까?\n삭제된 루틴은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final provider = context.read<RoutineProvider>();
      final success = await provider.deleteRoutine(widget.routine!.id);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴이 삭제되었습니다')),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${provider.error ?? "알 수 없는 오류"}')),
        );
      }
    }
  }
}
