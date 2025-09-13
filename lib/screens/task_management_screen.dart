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
      final items = await _authService.apiService!.getOverdueTasks();
      final tasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      setState(() {
        _overdueTasks = tasks;
        _loadingStates['overdue'] = false;
      });
    } catch (e) {
      setState(() {
        _loadingStates['overdue'] = false;
      });
      _showErrorSnackBar('기한 지난 할일을 불러오는데 실패했습니다: $e');
    }
  }

  /// 진행 중인 할일 로드
  Future<void> _loadInProgressTasks() async {
    setState(() {
      _loadingStates['inProgress'] = true;
    });

    try {
      final items = await _authService.apiService!.getInProgressTasks();
      final tasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      setState(() {
        _inProgressTasks = tasks;
        _loadingStates['inProgress'] = false;
      });
    } catch (e) {
      setState(() {
        _loadingStates['inProgress'] = false;
      });
      _showErrorSnackBar('진행 중인 할일을 불러오는데 실패했습니다: $e');
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

  /// 할일 편집 다이얼로그 표시
  void _showTaskEditDialog(NotionTask task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description ?? '');
    final dueDate = task.dueDate;
    final clarification = task.clarification;
    final status = task.status;
    final isCompleted = task.isCompleted;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('할일 편집'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '상세내용',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('완료'),
                  value: isCompleted,
                  onChanged: (value) {
                    setDialogState(() {
                      // 상태 업데이트
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateTask(task, {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'completed': isCompleted,
                });
                Navigator.of(context).pop();
              },
              child: const Text('저장'),
            ),
          ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('할일관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기한지남'),
            Tab(text: '진행중'),
            Tab(text: '다음행동'),
            Tab(text: '위임'),
          ],
        ),
      ),
      body: _isAuthenticated
          ? RefreshIndicator(
              onRefresh: _loadAllTasks,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverdueTab(),
                  _buildInProgressTab(),
                  _buildNextActionTab(),
                  _buildDelegatedTab(),
                ],
              ),
            )
          : _buildLoginPrompt(),
    );
  }

  Widget _buildLoginPrompt() {
    return RefreshIndicator(
      onRefresh: _checkAuthentication,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(task.status),
          child: Icon(
            _getStatusIcon(task.status),
        color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (task.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
            Text(
                      _formatDate(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
              ),
            ),
          ],
                ),
              ),
          ],
        ),
        trailing: task.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.radio_button_unchecked),
        onTap: () => _showDatePickerDialog(task),
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