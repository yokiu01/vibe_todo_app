import 'package:flutter/material.dart';
import '../services/notion_auth_service.dart';
import '../models/notion_task.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({Key? key}) : super(key: key);

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with SingleTickerProviderStateMixin {
  final NotionAuthService _authService = NotionAuthService();
  
  late TabController _tabController;
  bool _isAuthenticated = false;
  
  // 각 탭별 데이터
  List<NotionTask> _overdueTasks = [];
  List<NotionTask> _inProgressTasks = [];
  List<NotionTask> _nextActionTasks = [];
  List<NotionTask> _delegatedTasks = [];
  
  // 로딩 상태
  Map<String, bool> _loadingStates = {
    'overdue': false,
    'inProgress': false,
    'nextAction': false,
    'delegated': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuthentication();
    _loadAllTasks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침
    if (_isAuthenticated) {
      _loadAllTasks();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
  }

  /// 모든 탭의 데이터 로드
  Future<void> _loadAllTasks() async {
    if (!_isAuthenticated) return;
    
    await Future.wait([
      _loadOverdueTasks(),
      _loadInProgressTasks(),
      _loadNextActionTasks(),
      _loadDelegatedTasks(),
    ]);
  }

  /// 기한 지난 할일 로드
  Future<void> _loadOverdueTasks() async {
    setState(() {
      _loadingStates['overdue'] = true;
    });

    try {
      print('기한 지난 할일 로드 시작');
      
      // 모든 할일을 가져온 후 클라이언트에서 필터링
      final allItems = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
        null
      );
      print('전체 할일: ${allItems.length}개 로드됨');
      
      // 기한 지난 할일 필터링
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final overdueItems = allItems.where((item) {
        // 완료되지 않은 항목만
        final properties = item['properties'] as Map<String, dynamic>?;
        if (properties == null) return false;
        
        final completed = properties['완료'] as Map<String, dynamic>?;
        final isCompleted = completed?['checkbox'] as bool? ?? false;
        if (isCompleted) return false;
        
        // 날짜가 있고 오늘 이전인 항목
        final date = properties['날짜'] as Map<String, dynamic>?;
        if (date == null) return false;
        
        final dateValue = date['date'] as Map<String, dynamic>?;
        if (dateValue == null) return false;
        
        final startDate = dateValue['start'] as String?;
        if (startDate == null) return false;
        
        try {
          final itemDate = DateTime.parse(startDate);
          final itemDateOnly = DateTime(itemDate.year, itemDate.month, itemDate.day);
          return itemDateOnly.isBefore(today);
        } catch (e) {
          return false;
        }
      }).toList();
      
      print('기한 지난 할일: ${overdueItems.length}개 필터링됨');
      
      final tasks = overdueItems.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('기한 지난 할일 NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();
      
      print('기한 지난 할일: ${tasks.length}개 NotionTask 생성됨');
      
      if (mounted) {
        setState(() {
          _overdueTasks = tasks;
          _loadingStates['overdue'] = false;
        });
      }
    } catch (e) {
      print('기한 지난 할일 로드 오류: $e');
      if (mounted) {
        setState(() {
          _loadingStates['overdue'] = false;
        });
        _showErrorSnackBar('기한 지난 할일을 불러오는데 실패했습니다: $e');
      }
    }
  }

  /// 진행 중인 할일 로드
  Future<void> _loadInProgressTasks() async {
    setState(() {
      _loadingStates['inProgress'] = true;
    });

    try {
      print('진행 중인 할일 로드 시작');
      
      // 모든 할일을 가져온 후 클라이언트에서 필터링
      final allItems = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
        null
      );
      print('전체 할일: ${allItems.length}개 로드됨');
      
      // 진행 중인 할일 필터링 (완료되지 않은 모든 할일)
      final inProgressItems = allItems.where((item) {
        final properties = item['properties'] as Map<String, dynamic>?;
        if (properties == null) return false;
        
        final completed = properties['완료'] as Map<String, dynamic>?;
        final isCompleted = completed?['checkbox'] as bool? ?? false;
        return !isCompleted;
      }).toList();
      
      print('진행 중인 할일: ${inProgressItems.length}개 필터링됨');
      
      final tasks = inProgressItems.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('진행 중인 할일 NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();
      
      print('진행 중인 할일: ${tasks.length}개 NotionTask 생성됨');
      
      if (mounted) {
        setState(() {
          _inProgressTasks = tasks;
          _loadingStates['inProgress'] = false;
        });
      }
    } catch (e) {
      print('진행 중인 할일 로드 오류: $e');
      if (mounted) {
        setState(() {
          _loadingStates['inProgress'] = false;
        });
        _showErrorSnackBar('진행 중인 할일을 불러오는데 실패했습니다: $e');
      }
    }
  }

  /// 다음 행동 할일 로드
  Future<void> _loadNextActionTasks() async {
    setState(() {
      _loadingStates['nextAction'] = true;
    });

    try {
      final items = await _authService.apiService!.getNextActionTasks();
      final tasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      setState(() {
        _nextActionTasks = tasks;
        _loadingStates['nextAction'] = false;
      });
    } catch (e) {
      setState(() {
        _loadingStates['nextAction'] = false;
      });
      _showErrorSnackBar('다음 행동 할일을 불러오는데 실패했습니다: $e');
    }
  }

  /// 위임된 할일 로드
  Future<void> _loadDelegatedTasks() async {
    setState(() {
      _loadingStates['delegated'] = true;
    });

    try {
      final items = await _authService.apiService!.getDelegatedTasks();
      final tasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      setState(() {
        _delegatedTasks = tasks;
        _loadingStates['delegated'] = false;
      });
    } catch (e) {
      setState(() {
        _loadingStates['delegated'] = false;
      });
      _showErrorSnackBar('위임된 할일을 불러오는데 실패했습니다: $e');
    }
  }

  /// API 키 입력 다이얼로그
  void _showApiKeyDialog() {
    final apiKeyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notion API 키 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notion 개발자 포털에서 생성한 "Internal Integration Token"을 입력해주세요.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API 키',
                border: OutlineInputBorder(),
                hintText: 'secret_...',
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (apiKeyController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _setApiKey(apiKeyController.text);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('저장'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => _showSetupGuide(),
            child: const Text('설정 가이드'),
          ),
        ],
      ),
    );
  }

  /// API 키 설정
  Future<void> _setApiKey(String apiKey) async {
    setState(() {
      _loadingStates['overdue'] = true;
    });

    try {
      await _authService.setApiKey(apiKey);
      
      // API 연결 테스트
      final isConnected = await _authService.apiService!.testConnection();
      
      if (isConnected) {
        await _checkAuthentication();
        _loadAllTasks();
        _showSuccessSnackBar('Notion에 성공적으로 연결되었습니다!');
      } else {
        await _authService.clearApiKey();
        _showErrorSnackBar('API 키가 유효하지 않습니다. 다시 확인해주세요.');
      }
    } catch (e) {
      _showErrorSnackBar('API 키 설정에 실패했습니다: $e');
    } finally {
      setState(() {
        _loadingStates['overdue'] = false;
      });
    }
  }

  /// 설정 가이드 표시
  void _showSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notion API 설정 가이드'),
        content: SingleChildScrollView(
          child: Text(
            _authService.getSetupGuide(),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// Notion 로그아웃
  Future<void> _logoutFromNotion() async {
    await _authService.clearApiKey();
    setState(() {
      _isAuthenticated = false;
      _overdueTasks.clear();
      _inProgressTasks.clear();
      _nextActionTasks.clear();
      _delegatedTasks.clear();
    });
    _showSuccessSnackBar('Notion에서 로그아웃했습니다.');
  }

  /// 할일 상세보기 및 편집 다이얼로그 표시
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
          child: _TaskDetailView(
            task: task,
            onUpdate: (updatedTask) {
              Navigator.of(context).pop();
              _loadAllTasks(); // 새로고침
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  /// 할일 업데이트
  Future<void> _updateTask(NotionTask task, Map<String, dynamic> updates) async {
    try {
      final properties = <String, dynamic>{};
      
      if (updates['title'] != null) {
        properties['title'] = {
          'title': [
            {
              'text': {
                'content': updates['title'],
              }
            }
          ]
        };
      }
      
      if (updates['description'] != null) {
        properties['description'] = {
          'rich_text': [
            {
              'text': {
                'content': updates['description'],
              }
            }
          ]
        };
      }
      
      if (updates['completed'] != null) {
        properties['completed'] = {
          'checkbox': updates['completed'],
        };
      }

      await _authService.apiService!.updatePage(task.id, properties);
      _loadAllTasks(); // 모든 탭 새로고침
      _showSuccessSnackBar('할일이 업데이트되었습니다.');
    } catch (e) {
      _showErrorSnackBar('할일 업데이트에 실패했습니다: $e');
    }
  }

  /// 성공 메시지 표시
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Tab bar section
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: '📅 기한지남'),
                Tab(text: '🔄 진행중'),
                Tab(text: '⏭️ 다음행동'),
                Tab(text: '👥 위임'),
              ],
            ),
          ),
          // Content section
          Expanded(
            child: _isAuthenticated
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverdueTab(),
                      _buildInProgressTab(),
                      _buildNextActionTab(),
                      _buildDelegatedTab(),
                    ],
                  )
                : _buildLoginPrompt(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return RefreshIndicator(
      onRefresh: _checkAuthentication,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height > 400
              ? MediaQuery.of(context).size.height - 400
              : 200,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notion API 키를 입력하면\n할일 관리를 시작할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showApiKeyDialog,
                  icon: const Icon(Icons.key),
                  label: const Text('API 키 입력'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Notion API 키를 입력하면\n할일을 관리할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showApiKeyDialog,
            icon: const Icon(Icons.key),
            label: const Text('API 키 입력'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueTab() {
    return RefreshIndicator(
      onRefresh: _loadAllTasks,
      child: _buildTaskList(
        _overdueTasks,
        _loadingStates['overdue']!,
        '기한이 지난 할일이 없습니다.',
        Icons.warning,
        Colors.red,
      ),
    );
  }

  Widget _buildInProgressTab() {
    return RefreshIndicator(
      onRefresh: _loadAllTasks,
      child: _buildTaskList(
        _inProgressTasks,
        _loadingStates['inProgress']!,
        '진행 중인 할일이 없습니다.',
        Icons.play_arrow,
        Colors.blue,
      ),
    );
  }

  Widget _buildNextActionTab() {
    return RefreshIndicator(
      onRefresh: _loadAllTasks,
      child: _buildTaskList(
        _nextActionTasks,
        _loadingStates['nextAction']!,
        '다음 행동 할일이 없습니다.',
        Icons.arrow_forward,
        Colors.purple,
      ),
    );
  }

  Widget _buildDelegatedTab() {
    return RefreshIndicator(
      onRefresh: _loadAllTasks,
      child: _buildTaskList(
        _delegatedTasks,
        _loadingStates['delegated']!,
        '위임된 할일이 없습니다.',
        Icons.person,
        Colors.teal,
      ),
    );
  }

  Widget _buildTaskList(
    List<NotionTask> tasks,
    bool isLoading,
    String emptyMessage,
    IconData emptyIcon,
    Color emptyColor,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: emptyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(NotionTask task) {
    final isOverdue = task.dueDate != null &&
                     task.dueDate!.isBefore(DateTime.now()) &&
                     !task.isCompleted;

    return GestureDetector(
      onTap: () => _showTaskDetailDialog(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? const Color(0xFFEF4444)
                : task.isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE2E8F0),
            width: task.isCompleted || isOverdue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status ?? '미지정',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
                const Spacer(),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '지연',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: task.isCompleted ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: task.isCompleted ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: task.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (task.dueDate != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isOverdue
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOverdue
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const Spacer(),
                if (task.clarification != null && task.clarification!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.clarification!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 상태에 따른 색상 반환
  Color _getStatusColor(String? status) {
    switch (status) {
      case '진행중':
        return Colors.blue;
      case '완료':
        return Colors.green;
      case '대기':
        return Colors.orange;
      case '다음행동':
        return Colors.purple;
      case '위임':
        return Colors.teal;
      case '일정':
        return Colors.indigo;
      case '목표':
        return Colors.red;
      case '프로젝트':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  /// 상태에 따른 아이콘 반환
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case '진행중':
        return Icons.play_arrow;
      case '완료':
        return Icons.check;
      case '대기':
        return Icons.pause;
      case '다음행동':
        return Icons.arrow_forward;
      case '위임':
        return Icons.person;
      case '일정':
        return Icons.schedule;
      case '목표':
        return Icons.flag;
      case '프로젝트':
        return Icons.folder;
      default:
        return Icons.task;
    }
  }

  /// 날짜 선택 다이얼로그
  Future<void> _showDatePickerDialog(NotionTask task) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (selectedDate != null) {
      await _updateTaskDate(task, selectedDate);
    }
  }

  /// 할일 날짜 업데이트
  Future<void> _updateTaskDate(NotionTask task, DateTime date) async {
    try {
      final properties = <String, dynamic>{
        '날짜': {
          'date': {
            'start': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
          }
        }
      };

      await _authService.apiService!.updatePage(task.id, properties);
      _loadAllTasks(); // 모든 탭 새로고침
      _showSuccessSnackBar('날짜가 추가되었습니다.');
    } catch (e) {
      _showErrorSnackBar('날짜 추가에 실패했습니다: $e');
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '${difference}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 할일 상세보기 위젯
class _TaskDetailView extends StatefulWidget {
  final NotionTask task;
  final Function(NotionTask) onUpdate;
  final VoidCallback onClose;

  const _TaskDetailView({
    required this.task,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  final NotionAuthService _authService = NotionAuthService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isCompleted = false;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
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

      if (_isCompleted != widget.task.isCompleted) {
        properties['완료'] = {
          'checkbox': _isCompleted,
        };
      }

      if (properties.isNotEmpty) {
        await _authService.apiService!.updatePage(widget.task.id, properties);
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

      widget.onUpdate(widget.task);
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case '진행중':
        return Colors.blue;
      case '완료':
        return Colors.green;
      case '대기':
        return Colors.orange;
      case '다음행동':
        return Colors.purple;
      case '위임':
        return Colors.teal;
      default:
        return Colors.grey;
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
                Icons.description,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '할일 상세보기',
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
                // 상태 및 완료 체크박스
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.task.status ?? '미지정',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(widget.task.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Checkbox(
                          value: _isCompleted,
                          onChanged: _isEditing ? (value) {
                            setState(() {
                              _isCompleted = value ?? false;
                            });
                          } : null,
                          activeColor: const Color(0xFF22C55E),
                        ),
                        Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isCompleted
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                  maxLines: 6,
                ),

                const SizedBox(height: 20),

                // 추가 정보
                if (widget.task.dueDate != null) ...[
                  const Text(
                    '마감일',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.task.dueDate!.year}-${widget.task.dueDate!.month.toString().padLeft(2, '0')}-${widget.task.dueDate!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (widget.task.clarification != null && widget.task.clarification!.isNotEmpty) ...[
                  const Text(
                    '명료화',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.task.clarification!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 버튼들
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
                    label: const Text('수정'),
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