import 'package:flutter/material.dart';
import '../services/notion_auth_service.dart';
import '../models/notion_task.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final NotionAuthService _authService = NotionAuthService();
  
  List<NotionTask> _archivedItems = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String _selectedCategory = '전체';

  final List<String> _categories = [
    '전체',
    '완료된 할일',
    '보관된 메모',
    '아이디어',
    '읽을거리',
    '취미',
    '언젠가',
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadArchivedItems();
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
  }

  /// 아카이브된 항목들 로드
  Future<void> _loadArchivedItems() async {
    if (!_isAuthenticated) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> items = [];
      
      // 선택된 카테고리에 따라 다른 데이터베이스에서 로드
      switch (_selectedCategory) {
        case '완료된 할일':
          items = await _authService.apiService!.queryDatabase(
            '1169f5e4a81180a6a193e6747204dc8e',
            <String, dynamic>{
              'property': 'status',
              'select': <String, dynamic>{
                'equals': '완료',
              }
            },
          );
          break;
        case '보관된 메모':
          items = await _authService.apiService!.queryDatabase('1159f5e4a81180e3a9f2fdf6634730e6', null);
          break;
        case '아이디어':
        case '읽을거리':
        case '취미':
          items = await _authService.apiService!.queryDatabase('1159f5e4a81180e3a9f2fdf6634730e6', null);
          break;
        case '언젠가':
          items = await _authService.apiService!.queryDatabase(
            '1169f5e4a81180a6a193e6747204dc8e',
            <String, dynamic>{
              'property': 'clarification',
              'select': <String, dynamic>{
                'equals': '언젠가',
              }
            },
          );
          break;
        case '전체':
        default:
          // 모든 데이터베이스에서 데이터 가져오기
          final allItems = await Future.wait([
            _authService.apiService!.queryDatabase('1169f5e4a81180a6a193e6747204dc8e', null),
            _authService.apiService!.queryDatabase('1159f5e4a81180e3a9f2fdf6634730e6', null),
            _authService.apiService!.queryDatabase('1159f5e4a81180019f29cdd24d369230', null),
            _authService.apiService!.queryDatabase('1159f5e4a81180d092add53ae9df7f05', null),
          ]);
          items = allItems.expand((list) => list).toList();
          break;
      }
      
      final notionTasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      setState(() {
        _archivedItems = notionTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('아카이브 항목을 불러오는데 실패했습니다: $e');
    }
  }

  /// 항목 복원
  Future<void> _restoreItem(NotionTask item) async {
    try {
      // 항목을 TODO 데이터베이스로 이동
      await _authService.apiService!.createTodo(item.title, description: item.description);
      
      // 원본 항목 삭제
      await _authService.apiService!.deletePage(item.id);
      
      _loadArchivedItems(); // 목록 새로고침
      _showSuccessSnackBar('항목이 복원되었습니다.');
    } catch (e) {
      _showErrorSnackBar('복원에 실패했습니다: $e');
    }
  }

  /// 항목 완전 삭제
  Future<void> _deleteItem(NotionTask item) async {
    try {
      await _authService.apiService!.deletePage(item.id);
      _loadArchivedItems(); // 목록 새로고침
      _showSuccessSnackBar('항목이 삭제되었습니다.');
    } catch (e) {
      _showErrorSnackBar('삭제에 실패했습니다: $e');
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
        await _checkAuthentication();
        _loadArchivedItems();
        _showSuccessSnackBar('Notion에 성공적으로 연결되었습니다!');
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
      _archivedItems.clear();
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
        title: const Text('아카이브'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logoutFromNotion,
              tooltip: 'Notion 로그아웃',
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _showApiKeyDialog,
              tooltip: 'Notion API 키 입력',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isAuthenticated ? _loadArchivedItems : null,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isAuthenticated) {
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
              'Notion API 키를 입력하면\n아카이브를 볼 수 있습니다.',
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

    return Column(
      children: [
        // 카테고리 선택
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _loadArchivedItems();
                  },
                  selectedColor: Colors.blue.withOpacity(0.2),
                  checkmarkColor: Colors.blue,
                ),
              );
            },
          ),
        ),
        
        const Divider(),
        
        // 아카이브 항목 목록
        Expanded(
          child: _buildArchivedItemsList(),
        ),
      ],
    );
  }

  Widget _buildArchivedItemsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_archivedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$_selectedCategory 아카이브가 비어있습니다.',
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
      itemCount: _archivedItems.length,
      itemBuilder: (context, index) {
        final item = _archivedItems[index];
        return _buildArchivedItemCard(item);
      },
    );
  }

  Widget _buildArchivedItemCard(NotionTask item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(item.clarification),
          child: Icon(
            _getCategoryIcon(item.clarification),
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (item.clarification != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(
                    item.clarification!,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getCategoryColor(item.clarification),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '보관일: ${_formatDate(item.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreItem(item);
                break;
              case 'delete':
                _showDeleteConfirmDialog(item);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, size: 20),
                  SizedBox(width: 8),
                  Text('복원'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('완전 삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showItemDetails(item),
      ),
    );
  }

  /// 카테고리별 색상 반환
  Color _getCategoryColor(String? category) {
    switch (category) {
      case '완료':
        return Colors.green;
      case '언젠가':
        return Colors.orange;
      case '메모':
        return Colors.blue;
      case '아이디어':
        return Colors.purple;
      case '읽을거리':
        return Colors.indigo;
      case '취미':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 카테고리별 아이콘 반환
  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case '완료':
        return Icons.check_circle;
      case '언젠가':
        return Icons.schedule;
      case '메모':
        return Icons.note;
      case '아이디어':
        return Icons.lightbulb;
      case '읽을거리':
        return Icons.book;
      case '취미':
        return Icons.favorite;
      default:
        return Icons.archive;
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
                    const Text('분류: '),
                    Chip(
                      label: Text(item.clarification!),
                      backgroundColor: _getCategoryColor(item.clarification),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            Text('보관일: ${_formatDate(item.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreItem(item);
            },
            child: const Text('복원'),
          ),
        ],
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(NotionTask item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 삭제'),
        content: Text('"${item.title}"을(를) 완전히 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}