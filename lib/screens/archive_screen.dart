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

      // 첫 번째 항목의 구조 확인
      if (items.isNotEmpty) {
        print('🔍 목표 나침반 첫 번째 항목 구조:');
        print('  - 전체 데이터: ${items[0]}');
        print('  - properties: ${items[0]['properties']}');
        
        final properties = items[0]['properties'] as Map<String, dynamic>? ?? {};
        print('  - properties 키들: ${properties.keys.toList()}');
        
        if (properties.containsKey('상태')) {
          final statusProperty = properties['상태'] as Map<String, dynamic>? ?? {};
          print('  - 상태 속성: $statusProperty');
          print('  - 상태 속성 키들: ${statusProperty.keys.toList()}');
          
          if (statusProperty.containsKey('status')) {
            final statusValue = statusProperty['status'] as Map<String, dynamic>? ?? {};
            print('  - status 값: $statusValue');
            print('  - status 키들: ${statusValue.keys.toList()}');
            
            if (statusValue.containsKey('name')) {
              final statusName = statusValue['name'] as String? ?? '';
              print('  - 실제 상태명: "$statusName"');
            }
          }
        }
      }

      final notionTasks = items.map((item) {
        try {
          final task = NotionTask.fromNotion(item);
          print('목표 나침반 변환 성공: ${task.title} - 상태: ${task.status} - 명료화: ${task.clarification}');
          return task;
        } catch (e) {
          print('목표 나침반 NotionTask 변환 오류: $e');
          print('  - 문제가 된 데이터: $item');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('목표 나침반: ${notionTasks.length}개 NotionTask 생성됨');
      
      // 상태별 분류 확인
      final inProgressGoals = notionTasks.where((task) => task.status == '진행 중').toList();
      final completedGoals = notionTasks.where((task) => task.status == '완료').toList();
      print('📊 목표 나침반 분류:');
      print('  - 진행 중: ${inProgressGoals.length}개');
      print('  - 완료: ${completedGoals.length}개');

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

      // 첫 번째 항목의 구조 확인
      if (items.isNotEmpty) {
        print('🔍 노트 관리함 첫 번째 항목 구조:');
        print('  - 전체 데이터: ${items[0]}');
        print('  - properties: ${items[0]['properties']}');
        
        final properties = items[0]['properties'] as Map<String, dynamic>? ?? {};
        print('  - properties 키들: ${properties.keys.toList()}');
        
        if (properties.containsKey('분류')) {
          final categoryProperty = properties['분류'] as Map<String, dynamic>? ?? {};
          print('  - 분류 속성: $categoryProperty');
          print('  - 분류 속성 키들: ${categoryProperty.keys.toList()}');
          
          if (categoryProperty.containsKey('select')) {
            final selectValue = categoryProperty['select'] as Map<String, dynamic>? ?? {};
            print('  - select 값: $selectValue');
            print('  - select 키들: ${selectValue.keys.toList()}');
            
            if (selectValue.containsKey('name')) {
              final categoryName = selectValue['name'] as String? ?? '';
              print('  - 실제 분류명: "$categoryName"');
            }
          }
        }
      }

      final notionTasks = items.map((item) {
        try {
          final task = NotionTask.fromNotion(item);
          print('노트 관리함 변환 성공: ${task.title} - 상태: ${task.status} - 명료화: ${task.clarification}');
          return task;
        } catch (e) {
          print('노트 관리함 NotionTask 변환 오류: $e');
          print('  - 문제가 된 데이터: $item');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('노트 관리함: ${notionTasks.length}개 NotionTask 생성됨');
      
      // 분류별 분류 확인
      final laterView = notionTasks.where((task) => task.clarification == '나중에 보기').toList();
      final workInProgress = notionTasks.where((task) => task.clarification == '중간 작업물').toList();
      final areaResource = notionTasks.where((task) => task.status == '영역' || task.status == '자원').toList();
      print('📊 노트 관리함 분류:');
      print('  - 나중에 보기: ${laterView.length}개');
      print('  - 중간 작업물: ${workInProgress.length}개');
      print('  - 영역·자원: ${areaResource.length}개');

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
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text(
          '📦 아카이브',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C2A21),
          ),
        ),
        backgroundColor: const Color(0xFFFDF6E3),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF8B7355)),
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
            color: const Color(0xFFFDF6E3),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF8B7355),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              labelColor: const Color(0xFFFDF6E3),
              unselectedLabelColor: const Color(0xFF9C8B73),
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
            color: const Color(0xFFFDF6E3),
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
              case 'delete':
                _showDeleteConfirmDialog(item);
                break;
            }
          },
          itemBuilder: (context) => [
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
    // Area·Resource 데이터베이스의 페이지인 경우 관련 페이지들을 표시
    if (item.status == '영역' || item.status == '자원') {
      _showAreaResourceRelatedPages(item);
      return;
    }

    // Goal 또는 Project 데이터베이스의 페이지인 경우 관련 할일과 노트를 표시
    if (item.clarification == '목표' || item.clarification == '프로젝트') {
      _showGoalProjectRelatedPages(item);
      return;
    }

    // 일반적인 페이지 내용 표시
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => Dialog.fullscreen(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5F1E8),
                Color(0xFFDDD4C0),
              ],
            ),
          ),
          child: _ArchiveItemDetailView(
            task: item,
            authService: _authService,
            onUpdate: () {
              Navigator.of(context).pop();
              _loadArchivedItems(); // 새로고침
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  /// Area·Resource 페이지의 관련 데이터베이스 페이지들 표시
  void _showAreaResourceRelatedPages(NotionTask areaResourceTask) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => Dialog.fullscreen(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5F1E8),
                Color(0xFFDDD4C0),
              ],
            ),
          ),
          child: _AreaResourceRelatedPagesView(
            areaResourceTask: areaResourceTask,
            authService: _authService,
            onUpdate: () {
              Navigator.of(context).pop();
              _loadArchivedItems(); // 새로고침
            },
            onClose: () => Navigator.of(context).pop(),
            onTaskTap: _showItemDetails,
          ),
        ),
      ),
    );
  }

  /// Goal/Project 페이지의 관련 할일과 노트들 표시
  void _showGoalProjectRelatedPages(NotionTask goalProjectTask) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => Dialog.fullscreen(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5F1E8),
                Color(0xFFDDD4C0),
              ],
            ),
          ),
          child: _GoalProjectRelatedPagesView(
            goalProjectTask: goalProjectTask,
            authService: _authService,
            onUpdate: () {
              Navigator.of(context).pop();
              _loadArchivedItems(); // 새로고침
            },
            onClose: () => Navigator.of(context).pop(),
            onTaskTap: _showItemDetails,
          ),
        ),
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
                item.status == '진행 중'
              ).toList(),
              emptyMessage: '진행 중인 목표가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '💼 진행 중인 프로젝트',
              subtitle: '현재 작업 중인 프로젝트들',
              items: _archivedItems.where((item) =>
                item.status == '진행 중'
              ).toList(),
              emptyMessage: '진행 중인 프로젝트가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '✅ 완료된 목표',
              subtitle: '달성한 목표들',
              items: _archivedItems.where((item) =>
                item.status == '완료'
              ).toList(),
              emptyMessage: '완료된 목표가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '📁 완료된 프로젝트',
              subtitle: '완료한 프로젝트들',
              items: _archivedItems.where((item) =>
                item.status == '완료'
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
                item.clarification == '나중에 보기'
              ).toList(),
              emptyMessage: '나중에 볼 노트가 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '🔧 중간 작업물',
              subtitle: '진행 중인 작업 노트들',
              items: _archivedItems.where((item) =>
                item.clarification == '중간 작업물'
              ).toList(),
              emptyMessage: '중간 작업물이 없습니다.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '📚 영역·자원',
              subtitle: '관리 영역과 참고 자원들',
              items: _archivedItems.where((item) =>
                item.status == '영역' ||
                item.status == '자원'
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
                item.clarification == '다음행동' &&
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
                item.clarification == '언젠가' &&
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
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD4C0)),
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
                        color: Color(0xFF3C2A21),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B7355).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B7355),
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
                    color: Color(0xFF8B7355),
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
                      color: const Color(0xFFDDD4C0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B7355),
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

/// 아카이브 항목 상세보기 및 편집 위젯
class _ArchiveItemDetailView extends StatefulWidget {
  final NotionTask task;
  final NotionAuthService authService;
  final VoidCallback onUpdate;
  final VoidCallback onClose;

  const _ArchiveItemDetailView({
    required this.task,
    required this.authService,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<_ArchiveItemDetailView> createState() => _ArchiveItemDetailViewState();
}

class _ArchiveItemDetailViewState extends State<_ArchiveItemDetailView> {
  List<Map<String, dynamic>> _blocks = [];
  bool _isLoading = true;
  bool _isAddingContent = false;
  bool _isEditing = false;
  final TextEditingController _newContentController = TextEditingController();

  // Editing controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  String? _selectedClarification;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _initializeEditingFields();
    _loadPageContent();
  }

  void _initializeEditingFields() {
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _selectedDate = widget.task.dueDate;
    _selectedClarification = widget.task.clarification;
    _selectedStatus = widget.task.status;
  }

  @override
  void dispose() {
    _newContentController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPageContent() async {
    try {
      final blocks = await widget.authService.apiService!.getBlockChildren(widget.task.id);
      setState(() {
        _blocks = blocks;
        _isLoading = false;
      });
    } catch (e) {
      print('페이지 내용 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('페이지 내용 로드 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addNewContent() async {
    if (_newContentController.text.trim().isEmpty) return;

    setState(() {
      _isAddingContent = true;
    });

    try {
      final newBlock = widget.authService.apiService!.createParagraphBlock(_newContentController.text.trim());
      await widget.authService.apiService!.appendBlockChildren(widget.task.id, [newBlock]);

      _newContentController.clear();
      await _loadPageContent(); // 새로고침

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내용이 추가되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('내용 추가 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingContent = false;
      });
    }
  }

  Future<void> _saveTaskChanges() async {
    setState(() {
      _isAddingContent = true; // Reuse loading state
    });

    try {
      // Update page properties through Notion API
      final properties = <String, dynamic>{};
      
      // Update title
      if (_titleController.text.trim() != widget.task.title) {
        properties['이름'] = {
          'title': [
            {
              'text': {
                'content': _titleController.text.trim(),
              }
            }
          ]
        };
      }

      // Update description
      if (_descriptionController.text.trim() != (widget.task.description ?? '')) {
        properties['description'] = {
          'rich_text': [
            {
              'text': {
                'content': _descriptionController.text.trim(),
              }
            }
          ]
        };
      }

      // Update due date
      if (_selectedDate != widget.task.dueDate) {
        if (_selectedDate != null) {
          properties['날짜'] = {
            'date': {
              'start': _selectedDate!.toIso8601String().split('T')[0],
            }
          };
        } else {
          properties['날짜'] = {
            'date': null,
          };
        }
      }

      // Update clarification
      if (_selectedClarification != widget.task.clarification) {
        if (_selectedClarification != null && _selectedClarification!.isNotEmpty) {
          properties['명료화'] = {
            'select': {
              'name': _selectedClarification!,
            }
          };
        } else {
          properties['명료화'] = {
            'select': null,
          };
        }
      }

      // Update status
      if (_selectedStatus != widget.task.status) {
        if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
          properties['상태'] = {
            'status': {
              'name': _selectedStatus!,
            }
          };
        } else {
          properties['상태'] = {
            'status': null,
          };
        }
      }

      // Only update if there are changes
      if (properties.isNotEmpty) {
        await widget.authService.apiService!.updatePage(widget.task.id, properties);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('변경사항이 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onUpdate(); // Refresh parent
      }

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
        title: _isEditing 
          ? TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '제목을 입력하세요',
              ),
            )
          : Text(
              widget.task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
        actions: [
          if (_isEditing) ...[
            IconButton(
              onPressed: _saveTaskChanges,
              icon: const Icon(Icons.check, color: Colors.green),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initializeEditingFields(); // Reset to original values
                });
              },
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit, color: Colors.blue),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task properties
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing) ...[
                            // Description field
                            TextField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: '설명',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Due date field
                            Row(
                              children: [
                                const Text('기한: '),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _selectedDate = date;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _selectedDate != null
                                            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                            : '날짜 선택',
                                      ),
                                    ),
                                  ),
                                ),
                                if (_selectedDate != null)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Clarification dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedClarification,
                              decoration: const InputDecoration(
                                labelText: '명료화',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '다음행동', child: Text('다음행동')),
                                DropdownMenuItem(value: '언젠가', child: Text('언젠가')),
                                DropdownMenuItem(value: '나중에 보기', child: Text('나중에 보기')),
                                DropdownMenuItem(value: '중간 작업물', child: Text('중간 작업물')),
                                DropdownMenuItem(value: '레퍼런스', child: Text('레퍼런스')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedClarification = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Status dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: '상태',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '진행 중', child: Text('진행 중')),
                                DropdownMenuItem(value: '완료', child: Text('완료')),
                                DropdownMenuItem(value: '영역', child: Text('영역')),
                                DropdownMenuItem(value: '자원', child: Text('자원')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                            ),
                          ] else ...[
                            // Display mode
                            if (widget.task.description != null && widget.task.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  widget.task.description!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            if (widget.task.clarification != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Text('명료화: '),
                                    Chip(
                                      label: Text(widget.task.clarification!),
                                      backgroundColor: Colors.blue,
                                      labelStyle: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.task.status != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Text('상태: '),
                                    Chip(
                                      label: Text(widget.task.status!),
                                      backgroundColor: Colors.green,
                                      labelStyle: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.task.dueDate != null)
                              Text('기한: ${widget.task.dueDate!.year}-${widget.task.dueDate!.month.toString().padLeft(2, '0')}-${widget.task.dueDate!.day.toString().padLeft(2, '0')}'),
                            Text('생성일: ${widget.task.createdAt.year}-${widget.task.createdAt.month.toString().padLeft(2, '0')}-${widget.task.createdAt.day.toString().padLeft(2, '0')}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Page content
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '페이지 내용',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _addNewContent,
                                icon: const Icon(Icons.add),
                                tooltip: '내용 추가',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newContentController,
                            decoration: const InputDecoration(
                              hintText: '새로운 내용을 입력하세요...',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.send),
                            ),
                            onSubmitted: (_) => _addNewContent(),
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_blocks.isEmpty)
                            const Text(
                              '아직 내용이 없습니다. 위에서 내용을 추가해보세요.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...(_blocks.map((block) {
                              if (block['type'] == 'paragraph' && block['paragraph'] != null) {
                                final paragraph = block['paragraph'] as Map<String, dynamic>;
                                final richText = paragraph['rich_text'] as List<dynamic>? ?? [];
                                if (richText.isNotEmpty) {
                                  final text = richText.first['text']['content'] as String? ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(text),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            })),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Area·Resource 관련 페이지들 표시 위젯 (Archive용)
class _AreaResourceRelatedPagesView extends StatefulWidget {
  final NotionTask areaResourceTask;
  final NotionAuthService authService;
  final VoidCallback onUpdate;
  final VoidCallback onClose;
  final Function(NotionTask) onTaskTap;

  const _AreaResourceRelatedPagesView({
    required this.areaResourceTask,
    required this.authService,
    required this.onUpdate,
    required this.onClose,
    required this.onTaskTap,
  });

  @override
  State<_AreaResourceRelatedPagesView> createState() => _AreaResourceRelatedPagesViewState();
}

class _AreaResourceRelatedPagesViewState extends State<_AreaResourceRelatedPagesView> {
  bool _isLoading = true;
  List<NotionTask> _relatedGoals = [];
  List<NotionTask> _relatedProjects = [];
  List<NotionTask> _relatedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadRelatedPages();
  }

  Future<void> _loadRelatedPages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 관련된 목표, 프로젝트, 노트들을 병렬로 가져오기
      final results = await Future.wait([
        widget.authService.apiService!.getRelatedGoals(widget.areaResourceTask.id),
        widget.authService.apiService!.getRelatedProjects(widget.areaResourceTask.id),
        widget.authService.apiService!.getRelatedNotesByRelation(widget.areaResourceTask.id),
      ]);

      final goals = results[0].map((data) => NotionTask.fromNotion(data)).toList();
      final projects = results[1].map((data) => NotionTask.fromNotion(data)).toList();
      final notes = results[2].map((data) => NotionTask.fromNotion(data)).toList();

      setState(() {
        _relatedGoals = goals;
        _relatedProjects = projects;
        _relatedNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      print('관련 페이지 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('관련 페이지 로드 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B7355),
                    Color(0xFF6B5B47),
                  ],
                ),
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.areaResourceTask.status == '영역' ? Icons.location_city : Icons.library_books,
                      color: const Color(0xFFFDF6E3),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.areaResourceTask.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDF6E3),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '관련된 목표, 프로젝트, 노트들',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFDF6E3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFFFDF6E3),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 내용
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '관련 페이지를 로드하는 중...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF6E3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 관련 목표들
                            _buildRelatedSection(
                              title: '🎯 관련 목표',
                              items: _relatedGoals,
                              emptyMessage: '관련된 목표가 없습니다.',
                            ),
                            const SizedBox(height: 24),

                            // 관련 프로젝트들
                            _buildRelatedSection(
                              title: '💼 관련 프로젝트',
                              items: _relatedProjects,
                              emptyMessage: '관련된 프로젝트가 없습니다.',
                            ),
                            const SizedBox(height: 24),

                            // 관련 노트들
                            _buildRelatedSection(
                              title: '📝 관련 노트',
                              items: _relatedNotes,
                              emptyMessage: '관련된 노트가 없습니다.',
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSection({
    required String title,
    required List<NotionTask> items,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}개',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B7355),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD4C0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: const Color(0xFFDDD4C0),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B7355),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...items.map((item) => _buildRelatedItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildRelatedItemCard(NotionTask item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD4C0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: item.description?.isNotEmpty == true
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: const Color(0xFF8B7355),
        ),
        onTap: () => widget.onTaskTap(item),
      ),
    );
  }
}

/// Goal/Project 관련 페이지들 표시 위젯 (Archive용)
class _GoalProjectRelatedPagesView extends StatefulWidget {
  final NotionTask goalProjectTask;
  final NotionAuthService authService;
  final VoidCallback onUpdate;
  final VoidCallback onClose;
  final Function(NotionTask) onTaskTap;

  const _GoalProjectRelatedPagesView({
    required this.goalProjectTask,
    required this.authService,
    required this.onUpdate,
    required this.onClose,
    required this.onTaskTap,
  });

  @override
  State<_GoalProjectRelatedPagesView> createState() => _GoalProjectRelatedPagesViewState();
}

class _GoalProjectRelatedPagesViewState extends State<_GoalProjectRelatedPagesView> {
  bool _isLoading = true;
  List<NotionTask> _relatedTodos = [];
  List<NotionTask> _relatedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadRelatedPages();
  }

  Future<void> _loadRelatedPages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 관련된 할일과 노트들을 병렬로 가져오기
      final results = await Future.wait([
        widget.authService.apiService!.getRelatedTodos(widget.goalProjectTask.id),
        widget.authService.apiService!.getRelatedNotesForGoalProject(widget.goalProjectTask.id),
      ]);

      final todos = results[0].map((data) => NotionTask.fromNotion(data)).toList();
      final notes = results[1].map((data) => NotionTask.fromNotion(data)).toList();

      setState(() {
        _relatedTodos = todos;
        _relatedNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      print('관련 페이지 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('관련 페이지 로드 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoal = widget.goalProjectTask.clarification == '목표';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B7355),
                    Color(0xFF6B5B47),
                  ],
                ),
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isGoal ? Icons.flag : Icons.work,
                      color: const Color(0xFFFDF6E3),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.goalProjectTask.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDF6E3),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '관련된 할일과 노트들',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFDF6E3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFFFDF6E3),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 내용
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '관련 페이지를 로드하는 중...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF6E3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 관련 할일들
                            _buildRelatedSection(
                              title: '✅ 관련 할일',
                              items: _relatedTodos,
                              emptyMessage: '관련된 할일이 없습니다.',
                            ),
                            const SizedBox(height: 24),

                            // 관련 노트들
                            _buildRelatedSection(
                              title: '📝 관련 노트',
                              items: _relatedNotes,
                              emptyMessage: '관련된 노트가 없습니다.',
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSection({
    required String title,
    required List<NotionTask> items,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}개',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B7355),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD4C0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: const Color(0xFFDDD4C0),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B7355),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...items.map((item) => _buildRelatedItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildRelatedItemCard(NotionTask item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD4C0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: item.description?.isNotEmpty == true
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: const Color(0xFF8B7355),
        ),
        onTap: () => widget.onTaskTap(item),
      ),
    );
  }
}