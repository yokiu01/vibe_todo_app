import 'package:flutter/material.dart';
import '../models/notion_task.dart';
import '../services/notion_auth_service.dart';
import '../utils/helpers.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _textController = TextEditingController();
  final NotionAuthService _authService = NotionAuthService();
  bool _isLoadingNotion = false;
  bool _isAdding = false;
  List<NotionTask> _notionTasks = [];
  bool _isNotionAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {}); // 텍스트 변화 감지하여 UI 업데이트
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotionAuth();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침
    if (_isNotionAuthenticated) {
      _loadNotionTasks();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Notion 인증 상태 확인
  Future<void> _checkNotionAuth() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isNotionAuthenticated = isAuth;
    });
    if (isAuth) {
      _loadNotionTasks();
    }
  }

  /// Notion에서 오늘 수집한 할일 로드
  Future<void> _loadNotionTasks() async {
    if (!_isNotionAuthenticated) return;

    setState(() {
      _isLoadingNotion = true;
    });

    try {
      print('수집탭: Notion 데이터 로드 시작');
      
      // 모든 할일 항목을 가져온 후 클라이언트에서 오늘 생성된 것만 필터링
      final allItems = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
        null // 필터 없이 모든 항목 가져오기
      );
      print('수집탭: 전체 ${allItems.length}개 항목 로드됨');

      // 오늘 생성된 항목들만 필터링
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final todayItems = allItems.where((item) {
        final createdTime = item['created_time'] as String?;
        if (createdTime == null) return false;
        
        final created = DateTime.tryParse(createdTime);
        if (created == null) return false;
        
        return created.isAfter(today.subtract(const Duration(seconds: 1))) && 
               created.isBefore(tomorrow);
      }).toList();
      
      print('수집탭: 오늘 생성된 ${todayItems.length}개 항목 필터링됨');

      // 생성일시 기준으로 최신순 정렬
      todayItems.sort((a, b) {
        final aCreated = DateTime.tryParse(a['created_time'] ?? '') ?? DateTime(1970);
        final bCreated = DateTime.tryParse(b['created_time'] ?? '') ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });

      final notionTasks = todayItems.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('수집탭: ${notionTasks.length}개 NotionTask 생성됨');

      if (mounted) {
        setState(() {
          _notionTasks = notionTasks;
          _isLoadingNotion = false;
        });
      }
    } catch (e) {
      print('수집탭 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotion = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notion 항목을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Notion 할일 데이터베이스에 항목 추가
  Future<void> _addToNotion() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isAdding = true;
    });

    try {
      await _authService.apiService!.createTodo(_textController.text.trim());
      _textController.clear();
      
      // 목록 새로고침
      _loadNotionTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('항목이 할일 데이터베이스에 추가되었습니다'),
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
        child: RefreshIndicator(
          onRefresh: _loadNotionTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildInputSection(),
                _buildRecentItems(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '📋 수집함',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_notionTasks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_isNotionAuthenticated)
                IconButton(
                  onPressed: _isLoadingNotion ? null : _loadNotionTasks,
                  icon: _isLoadingNotion
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                  tooltip: 'Notion 항목 새로고침',
                ),
            ],
          ),
        ],
      ),
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
                onSubmitted: (_) => _addToNotion(),
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
                  ? _addToNotion
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


  Widget _buildRecentItems() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // 화면 높이의 60%로 고정
      child: _isLoadingNotion
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '수집된 항목을 불러오는 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : _notionTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '수집함이 비어있습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isNotionAuthenticated
                            ? '오늘 수집된 항목이 없습니다'
                            : 'Notion에 연결하여 수집을 시작하세요',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '📋 오늘 수집한 내용',
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
                        itemCount: _notionTasks.length,
                        itemBuilder: (context, index) {
                          final task = _notionTasks[index];
                          return _buildNotionItem(task);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNotionItem(NotionTask task) {
    return GestureDetector(
      onTap: () => _showTaskDetailDialog(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0xFF2563EB), width: 3),
          ),
        ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.clarification != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '명료화: ${task.clarification}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatTime(task.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Helpers.getRelativeTime(task.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// 태스크 상세보기 및 편집 다이얼로그
  void _showTaskDetailDialog(NotionTask task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: _CollectedTaskEditView(
            task: task,
            authService: _authService,
            onUpdate: () {
              Navigator.of(context).pop();
              _loadNotionTasks(); // 새로고침
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

/// 수집된 태스크 편집 위젯
class _CollectedTaskEditView extends StatefulWidget {
  final NotionTask task;
  final NotionAuthService authService;
  final VoidCallback onUpdate;
  final VoidCallback onClose;

  const _CollectedTaskEditView({
    required this.task,
    required this.authService,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<_CollectedTaskEditView> createState() => _CollectedTaskEditViewState();
}

class _CollectedTaskEditViewState extends State<_CollectedTaskEditView> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _dueDate = widget.task.dueDate;
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final properties = <String, dynamic>{};

      if (_titleController.text != widget.task.title) {
        properties['Name'] = {
          'title': [
            {
              'text': {
                'content': _titleController.text,
              }
            }
          ]
        };
      }

      if (_descriptionController.text != (widget.task.description ?? '')) {
        properties['상세설명'] = {
          'rich_text': [
            {
              'text': {
                'content': _descriptionController.text,
              }
            }
          ]
        };
      }

      if (_dueDate != widget.task.dueDate) {
        if (_dueDate != null) {
          properties['날짜'] = {
            'date': {
              'start': _dueDate!.toIso8601String().split('T')[0],
            }
          };
        } else {
          properties['날짜'] = {
            'date': null,
          };
        }
      }

      if (_isCompleted != widget.task.isCompleted) {
        properties['완료'] = {
          'checkbox': _isCompleted,
        };
      }

      if (properties.isNotEmpty) {
        await widget.authService.apiService!.updatePage(widget.task.id, properties);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('성공적으로 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _isEditing = false;
      });

      widget.onUpdate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _dueDate = selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '수집 항목 편집',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // 내용
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 완료 체크박스
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? () {
                        setState(() {
                          _isCompleted = !_isCompleted;
                        });
                      } : null,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isCompleted
                              ? const Color(0xFF22C55E)
                              : Colors.transparent,
                          border: Border.all(
                            color: _isCompleted
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isCompleted
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 제목
                const Text(
                  '제목',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  enabled: _isEditing,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    filled: true,
                    fillColor: _isEditing ? Colors.white : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // 상세설명
                const Text(
                  '상세설명',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  enabled: _isEditing,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    filled: true,
                    fillColor: _isEditing ? Colors.white : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    hintText: '상세설명을 입력해주세요',
                  ),
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                // 날짜
                const Text(
                  '마감일',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isEditing ? _selectDate : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.white : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isEditing
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dueDate != null
                              ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                              : '날짜를 선택하세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: _dueDate != null
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        if (_dueDate != null && _isEditing)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _dueDate = null;
                              });
                            },
                            child: const Icon(
                              Icons.clear,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 하단 버튼
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              if (!_isEditing) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('편집'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _isEditing = false;
                        _titleController.text = widget.task.title;
                        _descriptionController.text = widget.task.description ?? '';
                        _dueDate = widget.task.dueDate;
                        _isCompleted = widget.task.isCompleted;
                      });
                    },
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveChanges,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(_isLoading ? '저장 중...' : '저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
