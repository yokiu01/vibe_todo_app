import 'package:flutter/material.dart';
import '../services/notion_auth_service.dart';
import '../models/notion_task.dart';
import 'settings_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> with TickerProviderStateMixin {
  final NotionAuthService _authService = NotionAuthService();

  List<NotionTask> _archivedItems = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;
  late TabController _tabController;
  String _selectedCategory = '목표 나침반';

  final List<Tab> _tabs = [
    const Tab(text: '목표 나침반', icon: Icon(Icons.explore, size: 18)),
    const Tab(text: '노트 관리함', icon: Icon(Icons.folder, size: 18)),
    const Tab(text: '아이스박스', icon: Icon(Icons.ac_unit, size: 18)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _checkAuthentication();
    _loadArchivedItems();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _tabs[_tabController.index].text!;
      });
      
      // 탭에 따라 다른 데이터 로드
      switch (_selectedCategory) {
        case '목표 나침반':
          _loadGoalCompassData();
          break;
        case '노트 관리함':
          _loadNoteManagerData();
          break;
        case '아이스박스':
          _loadIceBoxData();
          break;
        default:
          _loadArchivedItems();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침
    if (_isAuthenticated) {
      _loadArchivedItems();
    }
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
  }

  /// 아카이브된 항목들 로드 (전체)
  Future<void> _loadArchivedItems() async {
    if (!_isAuthenticated) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('아카이브: 모든 데이터베이스에서 데이터 로드 시작');
      
      // 모든 데이터베이스에서 데이터 가져오기 (존재하는 데이터베이스만)
      final allItems = await Future.wait([
        _authService.apiService!.queryDatabase('1159f5e4a81180e591cbc596ae52f611', null), // TODO_DB_ID
        _authService.apiService!.queryDatabase('1159f5e4a81180e3a9f2fdf6634730e6', null), // MEMO_DB_ID
        _authService.apiService!.queryDatabase('1159f5e4a81180019f29cdd24d369230', null), // PROJECT_DB_ID
        _authService.apiService!.queryDatabase('1159f5e4a81180d092add53ae9df7f05', null), // GOAL_DB_ID
      ]);

      final items = allItems.expand((list) => list).toList();
      print('아카이브: 전체 ${items.length}개 항목 로드됨');
      
      final notionTasks = items.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('아카이브 NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('아카이브: ${notionTasks.length}개 NotionTask 생성됨');

      if (mounted) {
        setState(() {
          _archivedItems = notionTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('아카이브 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('아카이브 항목을 불러오는데 실패했습니다: $e');
      }
    }
  }

  /// 목표 나침반 데이터 로드
  Future<void> _loadGoalCompassData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('목표 나침반: 데이터 로드 시작');

      final List<List<Map<String, dynamic>>> allItems = [];

      // GOAL_DB_ID에서 데이터 로드 (에러 처리 포함)
      try {
        final goalItems = await _authService.apiService!.queryDatabase('1159f5e4a81180d092add53ae9df7f05', null);
        allItems.add(goalItems);
        print('목표 나침반: GOAL_DB에서 ${goalItems.length}개 항목 로드됨');
      } catch (e) {
        print('목표 나침반: GOAL_DB 로드 실패: $e');
        // 목표 데이터베이스 로드 실패해도 계속 진행
      }

      // PROJECT_DB_ID에서 데이터 로드 (에러 처리 포함)
      try {
        final projectItems = await _authService.apiService!.queryDatabase('1159f5e4a81180019f29cdd24d369230', null);
        allItems.add(projectItems);
        print('목표 나침반: PROJECT_DB에서 ${projectItems.length}개 항목 로드됨');
      } catch (e) {
        print('목표 나침반: PROJECT_DB 로드 실패: $e');
        // 프로젝트 데이터베이스 로드 실패해도 계속 진행
      }

      final items = allItems.expand((list) => list).toList();
      print('목표 나침반: 총 ${items.length}개 항목 로드됨');

      final notionTasks = items.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('목표 나침반 NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('목표 나침반: ${notionTasks.length}개 NotionTask 생성됨');

      if (mounted) {
        setState(() {
          _archivedItems = notionTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('목표 나침반 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('목표 나침반 데이터 로드 실패: $e');
      }
    }
  }

  /// 노트 관리함 데이터 로드
  Future<void> _loadNoteManagerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('노트 관리함: 데이터 로드 시작');

      final List<List<Map<String, dynamic>>> allItems = [];

      // MEMO_DB_ID에서 데이터 로드 (노트 데이터베이스)
      try {
        final memoItems = await _authService.apiService!.queryDatabase('1159f5e4a81180e3a9f2fdf6634730e6', null);
        allItems.add(memoItems);
        print('노트 관리함: MEMO_DB에서 ${memoItems.length}개 항목 로드됨');
      } catch (e) {
        print('노트 관리함: MEMO_DB 로드 실패: $e');
      }

      // 영역·자원 데이터베이스에서도 노트 관련 데이터 로드 (올바른 DB ID 사용)
      try {
        final areaResourceItems = await _authService.apiService!.queryDatabase('1159f5e4a81180d1ab17fa79bb0cf0f4', null);
        allItems.add(areaResourceItems);
        print('노트 관리함: 영역자원DB에서 ${areaResourceItems.length}개 항목 로드됨');
      } catch (e) {
        print('노트 관리함: 영역자원DB 로드 실패: $e');
        // 영역자원 데이터베이스가 접근 불가능한 경우에도 계속 진행
      }

      final items = allItems.expand((list) => list).toList();
      print('노트 관리함: 총 ${items.length}개 항목 로드됨');

      final notionTasks = items.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('노트 관리함 NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('노트 관리함: ${notionTasks.length}개 NotionTask 생성됨');

      if (mounted) {
        setState(() {
          _archivedItems = notionTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('노트 관리함 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('노트 관리함 데이터 로드 실패: $e');
      }
    }
  }

  /// 아이스박스 데이터 로드
  Future<void> _loadIceBoxData() async {
    try {
      print('아이스박스: 데이터 로드 시작');
      
      // 차가운 다음행동과 언젠가 항목들 로드
      final items = await _authService.apiService!.queryDatabase('1159f5e4a81180e591cbc596ae52f611', null); // TODO_DB_ID
      print('아이스박스: ${items.length}개 항목 로드됨');
      
      final notionTasks = items.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('아이스박스 NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('아이스박스: ${notionTasks.length}개 NotionTask 생성됨');

      if (mounted) {
        setState(() {
          _archivedItems = notionTasks;
        });
      }
    } catch (e) {
      print('아이스박스 로드 오류: $e');
      _showErrorSnackBar('아이스박스 데이터 로드 실패: $e');
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '📦 아카이브',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF64748B)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: '설정',
          ),
        ],
        bottom: _isAuthenticated ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
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
              tabs: _tabs,
            ),
          ),
        ) : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isAuthenticated) {
      return RefreshIndicator(
        onRefresh: _checkAuthentication,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height > 300
                ? MediaQuery.of(context).size.height - 200
                : 100,
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
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArchivedItems,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalCompassTab(),
          _buildNoteManagerTab(),
          _buildIceBoxTab(),
        ],
      ),
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

  // New tab builder methods
  Widget _buildGoalCompassTab() {
    return RefreshIndicator(
      onRefresh: () => _loadGoalCompassData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: '🎯 진행 중인 목표',
              subtitle: '현재 작업 중인 목표들',
              items: _archivedItems.where((item) =>
                (item.clarification?.contains('목표') == true ||
                 item.status?.contains('목표') == true ||
                 item.status == '목표') &&
                (item.status?.contains('진행') == true ||
                 item.status == '진행중' ||
                 item.clarification?.contains('진행') == true ||
                 !item.isCompleted)
              ).toList(),
              emptyMessage: '진행 중인 목표가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '💼 진행 중인 프로젝트',
              subtitle: '현재 작업 중인 프로젝트들',
              items: _archivedItems.where((item) =>
                (item.clarification?.contains('프로젝트') == true ||
                 item.status?.contains('프로젝트') == true ||
                 item.status == '프로젝트') &&
                (item.status?.contains('진행') == true ||
                 item.status == '진행중' ||
                 item.clarification?.contains('진행') == true ||
                 !item.isCompleted)
              ).toList(),
              emptyMessage: '진행 중인 프로젝트가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '✅ 완료된 목표',
              subtitle: '달성한 목표들',
              items: _archivedItems.where((item) =>
                (item.clarification?.contains('목표') == true ||
                 item.status?.contains('목표') == true ||
                 item.status == '목표') &&
                (item.status?.contains('완료') == true ||
                 item.status == '완료' ||
                 item.isCompleted)
              ).toList(),
              emptyMessage: '완료된 목표가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '📁 완료된 프로젝트',
              subtitle: '완료한 프로젝트들',
              items: _archivedItems.where((item) =>
                (item.clarification?.contains('프로젝트') == true ||
                 item.status?.contains('프로젝트') == true ||
                 item.status == '프로젝트') &&
                (item.status?.contains('완료') == true ||
                 item.status == '완료' ||
                 item.isCompleted)
              ).toList(),
              emptyMessage: '완료된 프로젝트가 없습니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteManagerTab() {
    return RefreshIndicator(
      onRefresh: () => _loadNoteManagerData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: '👀 나중에 보기',
              subtitle: '나중에 확인할 노트들',
              items: _archivedItems.where((item) =>
                item.clarification?.contains('나중에') == true ||
                item.status?.contains('나중에') == true ||
                item.clarification == '나중에 보기' ||
                item.clarification == '나중에'
              ).toList(),
              emptyMessage: '나중에 볼 노트가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '🔧 중간 작업물',
              subtitle: '진행 중인 작업 노트들',
              items: _archivedItems.where((item) =>
                item.clarification?.contains('중간') == true ||
                item.clarification?.contains('작업물') == true ||
                item.status?.contains('진행') == true ||
                item.clarification == '중간 작업물' ||
                item.clarification?.contains('진행') == true ||
                (item.status == '진행중' && !item.isCompleted)
              ).toList(),
              emptyMessage: '중간 작업물이 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '📚 영역·자원',
              subtitle: '관리 영역과 참고 자원들',
              items: _archivedItems.where((item) =>
                item.status == '영역' ||
                item.status == '자원' ||
                item.clarification?.contains('영역') == true ||
                item.clarification?.contains('자원') == true ||
                item.status?.contains('영역') == true ||
                item.status?.contains('자원') == true ||
                item.clarification == '영역' ||
                item.clarification == '자원' ||
                item.clarification?.contains('참고') == true ||
                item.clarification?.contains('노트') == true
              ).toList(),
              emptyMessage: '영역·자원이 없습니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIceBoxTab() {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

    return RefreshIndicator(
      onRefresh: () => _loadIceBoxData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: '🧊 차가운 다음행동',
              subtitle: '1주일 이상 된 다음행동들',
              items: _archivedItems.where((item) =>
                (item.clarification == '다음행동' ||
                 item.clarification?.contains('다음') == true ||
                 item.status?.contains('다음') == true) &&
                !item.isCompleted &&
                item.createdAt.isBefore(oneWeekAgo)
              ).toList(),
              emptyMessage: '차가운 다음행동이 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '⏰ 언젠가',
              subtitle: '나중에 할 일들',
              items: _archivedItems.where((item) =>
                (item.clarification == '언젠가' ||
                 item.clarification?.contains('언젠가') == true ||
                 item.status?.contains('언젠가') == true ||
                 item.status == '언젠가') &&
                !item.isCompleted
              ).toList(),
              emptyMessage: '언젠가 할 일이 없습니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<NotionTask> items,
    required String emptyMessage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: const Color(0xFFE5E7EB),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.description?.isNotEmpty == true
                      ? Text(
                          item.description!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.clarification),
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => _showItemDetails(item),
                );
              },
            ),
        ],
      ),
    );
  }
}