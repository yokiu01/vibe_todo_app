import 'package:flutter/material.dart';
import '../services/notion_auth_service.dart';
import '../models/notion_task.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final TextEditingController _todoController = TextEditingController();
  final NotionAuthService _authService = NotionAuthService();
  
  List<NotionTask> _recentItems = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadRecentItems();
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
  }

  /// 최근 수집한 항목들 로드
  Future<void> _loadRecentItems() async {
    if (!_isAuthenticated) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _authService.getInboxTasks();
      
      // 안전하게 NotionTask로 변환
      final notionTasks = <NotionTask>[];
      for (var item in items) {
        try {
          final task = NotionTask.fromNotion(item);
          notionTasks.add(task);
        } catch (e) {
          print('항목 변환 오류: $e');
          // 개별 항목 변환 실패는 무시하고 계속 진행
        }
      }
      
      setState(() {
        _recentItems = notionTasks.take(10).toList(); // 최근 10개만 표시
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Notion API 호출 오류: $e');
      _showErrorSnackBar('최근 항목을 불러오는데 실패했습니다. Notion 데이터베이스 설정을 확인해주세요.');
    }
  }

  /// 할일 추가
  Future<void> _addTodo() async {
    if (_todoController.text.trim().isEmpty) {
      _showErrorSnackBar('할일을 입력해주세요.');
      return;
    }

    if (!_isAuthenticated) {
      _showErrorSnackBar('Notion에 먼저 로그인해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.apiService!.createTodo(_todoController.text.trim());
      
      _todoController.clear();
      _loadRecentItems(); // 목록 새로고침
      
      _showSuccessSnackBar('할일이 추가되었습니다.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('할일 추가에 실패했습니다: $e');
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
      _isLoading = true;
    });

    try {
      await _authService.setApiKey(apiKey);
      
      // API 연결 테스트
      final isConnected = await _authService.apiService!.testConnection();
      
      if (isConnected) {
        // 데이터베이스 접근 권한 검증
        final validationResults = await _authService.validateDatabaseAccess();
        _showValidationResults(validationResults);
        
        await _checkAuthentication();
        _loadRecentItems();
      } else {
        await _authService.clearApiKey();
        _showErrorSnackBar('API 키가 유효하지 않습니다. 다시 확인해주세요.');
      }
    } catch (e) {
      _showErrorSnackBar('API 키 설정에 실패했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 데이터베이스 접근 권한 검증 결과 표시
  void _showValidationResults(Map<String, bool> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터베이스 접근 권한 검증'),
        content: SingleChildScrollView(
          child: Text(
            _authService.getValidationReport(results),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          if (results.values.any((access) => !access))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDatabaseSharingGuide();
              },
              child: const Text('공유 가이드 보기'),
            ),
        ],
      ),
    );
  }

  /// 데이터베이스 공유 가이드 표시
  void _showDatabaseSharingGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터베이스 공유 가이드'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '접근 불가능한 데이터베이스에 통합을 공유해야 합니다:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. 할일 데이터베이스:'),
              const Text('   https://www.notion.so/1159f5e4a81180e591cbc596ae52f611\n'),
              const Text('2. 명료화 데이터베이스:'),
              const Text('   https://www.notion.so/1169f5e4a81180a6a193e6747204dc8e\n'),
              const Text('3. 메모 데이터베이스:'),
              const Text('   https://www.notion.so/1159f5e4a81180e3a9f2fdf6634730e6\n'),
              const Text('4. 프로젝트 데이터베이스:'),
              const Text('   https://www.notion.so/1159f5e4a81180019f29cdd24d369230\n'),
              const Text('5. 목표 데이터베이스:'),
              const Text('   https://www.notion.so/1159f5e4a81180d092add53ae9df7f05\n'),
              const Text(
                '\n각 데이터베이스 페이지에서:\n'
                '1. "Share" 버튼 클릭\n'
                '2. "Add people, emails, groups, or integrations" 클릭\n'
                '3. 생성한 통합 이름 검색 후 "Invite" 클릭',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _validateAndRefresh();
            },
            child: const Text('다시 검증'),
          ),
        ],
      ),
    );
  }

  /// 검증 및 새로고침
  Future<void> _validateAndRefresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final validationResults = await _authService.validateDatabaseAccess();
      _showValidationResults(validationResults);
      
      await _checkAuthentication();
      _loadRecentItems();
    } catch (e) {
      _showErrorSnackBar('검증 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
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
      _recentItems.clear();
    });
    _showSuccessSnackBar('Notion에서 로그아웃했습니다.');
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
        title: const Text('수집'),
        actions: [
          if (_isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.verified_user),
              onPressed: _validateAndRefresh,
              tooltip: '데이터베이스 접근 권한 검증',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logoutFromNotion,
              tooltip: 'Notion 로그아웃',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _showApiKeyDialog,
              tooltip: 'Notion API 키 입력',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 할일 입력 섹션
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _todoController,
                      decoration: const InputDecoration(
                        hintText: '할일을 입력하세요',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.add_task),
                      ),
                      maxLines: 3,
                      enabled: _isAuthenticated && !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isAuthenticated && !_isLoading ? _addTodo : null,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                      label: Text(_isLoading ? '추가 중...' : '추가'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 인증 상태 표시
            if (!_isAuthenticated)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notion API 키를 입력하면 할일을 저장할 수 있습니다.',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _showApiKeyDialog,
                        icon: const Icon(Icons.key),
                        label: const Text('API 키 입력'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 최근 수집한 항목들
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '최근 수집한 항목들',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _isAuthenticated ? _loadRecentItems : null,
                        tooltip: '새로고침',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildRecentItemsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 최근 항목 목록 위젯
  Widget _buildRecentItemsList() {
    if (!_isAuthenticated) {
      return const Center(
        child: Text(
          'Notion API 키를 입력하면 최근 항목을 볼 수 있습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recentItems.isEmpty) {
      return const Center(
        child: Text(
          '아직 수집한 항목이 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _recentItems.length,
      itemBuilder: (context, index) {
        final item = _recentItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(item.status),
              child: Icon(
                _getStatusIcon(item.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                if (item.clarification != null)
                  Chip(
                    label: Text(
                      item.clarification!,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: _getStatusColor(item.clarification),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            trailing: Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              // 항목 상세 보기 또는 편집
              _showItemDetails(item);
            },
          ),
        );
      },
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

  /// 항목 상세 정보 표시
  void _showItemDetails(NotionTask item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item.description!),
              ),
            if (item.clarification != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('명료화: '),
                    Chip(
                      label: Text(item.clarification!),
                      backgroundColor: _getStatusColor(item.clarification),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            if (item.status != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('상태: '),
                    Chip(
                      label: Text(item.status!),
                      backgroundColor: _getStatusColor(item.status),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            if (item.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('기한: ${_formatDate(item.dueDate!)}'),
              ),
            Text('생성일: ${_formatDate(item.createdAt)}'),
          ],
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
}