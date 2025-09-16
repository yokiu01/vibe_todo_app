import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../services/notion_auth_service.dart';
import '../models/notion_task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final NotionAuthService _authService = NotionAuthService();
  List<NotionTask> _notionTasks = [];
  List<NotionTask> _notionProjects = [];
  List<NotionTask> _pinnedNotes = [];
  List<NotionTask> _areaItems = [];
  List<NotionTask> _resourceItems = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  final List<Tab> _tabs = [
    const Tab(text: 'Today', icon: Icon(Icons.today, size: 18)),
    const Tab(text: 'Pin', icon: Icon(Icons.push_pin, size: 18)),
    const Tab(text: 'Project', icon: Icon(Icons.work, size: 18)),
    const Tab(text: 'Area', icon: Icon(Icons.location_city, size: 18)),
    const Tab(text: 'Resource', icon: Icon(Icons.library_books, size: 18)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
    if (isAuth) {
      _loadNotionData();
    }
  }

  Future<void> _loadNotionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 오늘 날짜 할일 가져오기 (TODO 데이터베이스에서 오늘 날짜인 항목들)
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0]; // YYYY-MM-DD 형식
      
      final todayTasksData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
        {
          "property": "날짜",
          "date": {
            "equals": todayStr
          }
        }
      );
      final todayTasks = todayTasksData.map((data) => NotionTask.fromNotion(data)).toList();

      // 고정된 노트 가져오기 (노트 데이터베이스에서 '고정됨' 체크박스가 활성화된 것들)
      final pinnedNotesData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e3a9f2fdf6634730e6', // MEMO_DB_ID
        {
          "property": "고정됨",
          "checkbox": {
            "equals": true
          }
        }
      );
      final pinnedNotes = pinnedNotesData.map((data) => NotionTask.fromNotion(data)).toList();

      // 진행중인 프로젝트 가져오기 (프로젝트 데이터베이스에서 상태가 '진행 중'이거나 '시작 안 함'인 것들)
      final projectsData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180019f29cdd24d369230', // PROJECT_DB_ID
        {
          "property": "상태",
          "status": {
            "is_not_empty": true
          }
        }
      );
      final activeProjects = projectsData.map((data) => NotionTask.fromNotion(data)).toList();

      // 영역·자원 데이터베이스에서 직접 데이터 가져오기
      final areaResourceData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180d1ab17fa79bb0cf0f4', // 영역·자원 데이터베이스 ID
        null
      );

      // 영역과 자원으로 분리
      final areas = areaResourceData.where((data) {
        final properties = data['properties'] as Map<String, dynamic>? ?? {};
        final typeProperty = properties['타입'] as Map<String, dynamic>? ?? {};
        final selectValue = typeProperty['select'] as Map<String, dynamic>? ?? {};
        final typeName = selectValue['name'] as String? ?? '';
        return typeName == '영역';
      }).map((data) => NotionTask.fromNotion(data)).toList();

      final resources = areaResourceData.where((data) {
        final properties = data['properties'] as Map<String, dynamic>? ?? {};
        final typeProperty = properties['타입'] as Map<String, dynamic>? ?? {};
        final selectValue = typeProperty['select'] as Map<String, dynamic>? ?? {};
        final typeName = selectValue['name'] as String? ?? '';
        return typeName == '자원';
      }).map((data) => NotionTask.fromNotion(data)).toList();

      setState(() {
        _notionTasks = todayTasks;
        _notionProjects = activeProjects;
        _pinnedNotes = pinnedNotes;
        _areaItems = areas;
        _resourceItems = resources;
      });
    } catch (e) {
      print('Failed to load Notion data: $e');
      // 에러가 발생해도 빈 리스트로 초기화하여 앱이 정상 작동하도록 함
      setState(() {
        _notionTasks = [];
        _notionProjects = [];
        _pinnedNotes = [];
        _areaItems = [];
        _resourceItems = [];
      });
      _showErrorSnackBar('일부 데이터를 불러오는데 실패했습니다. 새로고침을 시도해주세요.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildTabBarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏠 홈',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '오늘의 계획과 프로젝트 관리',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusCard('오늘 할일', '${_notionTasks.length}개', const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildStatusCard('프로젝트 DB', '${_notionProjects.length}개', const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildStatusCard('고정 메모', '${_pinnedNotes.length}개', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(8),
        ),
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
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        tabs: _tabs,
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTodayPage(),
        _buildPinPage(),
        _buildProjectPage(),
        _buildAreaPage(),
        _buildResourcePage(),
      ],
    );
  }

  Widget _buildTodayPage() {
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
                  const Text(
                    'Notion API 키를 설정하면\n오늘의 할일을 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '📅 오늘의 할일',
          subtitle: DateFormat('M월 d일 (E)', 'ko').format(DateTime.now()),
          tasks: _notionTasks,
          emptyMessage: '오늘 등록된 할일이 없습니다.',
        ),
      ),
    );
  }

  Widget _buildPinPage() {
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
                    Icons.push_pin_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notion 연동 후\n고정된 노트를 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_isAuthenticated) {
          await _loadNotionData();
        } else {
          await _checkAuthentication();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '📌 고정된 노트',
          subtitle: '중요한 내용을 고정해보세요',
          tasks: _pinnedNotes,
          emptyMessage: '고정된 노트가 없습니다.',
        ),
      ),
    );
  }

  Widget _buildProjectPage() {
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
                    Icons.work_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notion 연동 후\n프로젝트를 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '💼 프로젝트 데이터베이스',
          subtitle: '모든 프로젝트 관리',
          tasks: _notionProjects,
          emptyMessage: '등록된 프로젝트가 없습니다.',
        ),
      ),
    );
  }

  Widget _buildAreaPage() {
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
                    Icons.location_city,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notion 연동 후\n영역을 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '🏢 영역자원데이터베이스',
          subtitle: '영역 관리 목록',
          tasks: _areaItems,
          emptyMessage: '등록된 영역이 없습니다.',
        ),
      ),
    );
  }

  Widget _buildResourcePage() {
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
                    Icons.library_books,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notion 연동 후\n자원을 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '📚 영역자원데이터베이스',
          subtitle: '자원 및 참고 자료',
          tasks: _resourceItems,
          emptyMessage: '등록된 자원이 없습니다.',
        ),
      ),
    );
  }

  Widget _buildItemList({
    required String title,
    required String subtitle,
    required List<Item> items,
    required String emptyMessage,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const SizedBox(height: 16),
          items.isEmpty
              ? Container(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: const Color(0xFFE5E7EB),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHomeItemCard(item, items.indexOf(item)),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildHomeItemCard(Item item, int index) {
    final isCompleted = item.status == ItemStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(item.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getTypeText(item.type),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getTypeColor(item.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF1E293B),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          if (item.content != null && item.content!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.content!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (item.dueDate != null) ...[
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('M/d HH:mm').format(item.dueDate!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(item.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(item.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(ItemType type) {
    switch (type) {
      case ItemType.task:
        return const Color(0xFF3B82F6);
      case ItemType.project:
        return const Color(0xFF10B981);
      case ItemType.note:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getTypeText(ItemType type) {
    switch (type) {
      case ItemType.task:
        return '할일';
      case ItemType.project:
        return '프로젝트';
      case ItemType.note:
        return '메모';
      default:
        return '기타';
    }
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.completed:
        return const Color(0xFF22C55E);
      case ItemStatus.active:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.completed:
        return '완료';
      case ItemStatus.active:
        return '진행중';
      default:
        return '대기';
    }
  }

  Widget _buildNotionTaskList({
    required String title,
    required String subtitle,
    required List<NotionTask> tasks,
    required String emptyMessage,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}개',
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
          const SizedBox(height: 16),
          tasks.isEmpty
              ? Container(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: const Color(0xFFE5E7EB),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: tasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildNotionTaskCard(task, tasks.indexOf(task)),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildNotionTaskCard(NotionTask task, int index) {
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTap: () => _showTaskContentDialog(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNotionTaskTypeColor(task).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getNotionTaskTypeText(task),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getNotionTaskTypeColor(task),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF1E293B),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          if (task.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (task.dueDate != null) ...[
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('M/d HH:mm').format(task.dueDate!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const Spacer(),
              if (task.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getNotionStatusColor(task.status!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status!,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getNotionStatusColor(task.status!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Color _getNotionTaskTypeColor(NotionTask task) {
    // 상태나 명료화 값에 따라 색상 구분
    final status = task.status ?? task.clarification ?? '';
    
    if (status.contains('프로젝트') || status.contains('Project')) {
      return const Color(0xFF10B981);
    } else if (status.contains('할일') || status.contains('일정') || status.contains('다음행동')) {
      return const Color(0xFF3B82F6);
    } else if (status.contains('메모') || status.contains('노트')) {
      return const Color(0xFFF59E0B);
    } else if (status.contains('영역') || status.contains('Area')) {
      return const Color(0xFF8B5CF6);
    } else if (status.contains('자원') || status.contains('Resource')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF64748B);
    }
  }

  String _getNotionTaskTypeText(NotionTask task) {
    final status = task.status ?? task.clarification ?? '';
    
    if (status.contains('프로젝트') || status.contains('Project')) {
      return '프로젝트';
    } else if (status.contains('할일') || status.contains('일정') || status.contains('다음행동')) {
      return '할일';
    } else if (status.contains('메모') || status.contains('노트')) {
      return '메모';
    } else if (status.contains('영역') || status.contains('Area')) {
      return '영역';
    } else if (status.contains('자원') || status.contains('Resource')) {
      return '자원';
    } else {
      return status.isNotEmpty ? status : '일반';
    }
  }

  Color _getNotionStatusColor(String status) {
    if (status.contains('완료') || status.contains('Done')) {
      return const Color(0xFF22C55E);
    } else if (status.contains('진행') || status.contains('Progress')) {
      return const Color(0xFF3B82F6);
    } else {
      return const Color(0xFF64748B);
    }
  }

  /// 태스크 내용 보기 및 추가 다이얼로그
  void _showTaskContentDialog(NotionTask task) {
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
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
          child: _TaskContentView(
            task: task,
            authService: _authService,
            onUpdate: () {
              Navigator.of(context).pop();
              _loadNotionData(); // 새로고침
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
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
}

/// 태스크 내용 보기 및 추가 위젯
class _TaskContentView extends StatefulWidget {
  final NotionTask task;
  final NotionAuthService authService;
  final VoidCallback onUpdate;
  final VoidCallback onClose;

  const _TaskContentView({
    required this.task,
    required this.authService,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<_TaskContentView> createState() => _TaskContentViewState();
}

class _TaskContentViewState extends State<_TaskContentView> {
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
      if (_titleController.text != widget.task.title) {
        properties['이름'] = {
          'title': [
            {
              'text': {
                'content': _titleController.text,
              }
            }
          ]
        };
      }

      // Update description
      if (_descriptionController.text != (widget.task.description ?? '')) {
        properties['설명'] = {
          'rich_text': [
            {
              'text': {
                'content': _descriptionController.text,
              }
            }
          ]
        };
      }

      // Update date
      if (_selectedDate != widget.task.dueDate) {
        if (_selectedDate != null) {
          properties['날짜'] = {
            'date': {
              'start': _selectedDate!.toIso8601String().split('T')[0],
            }
          };
        } else {
          properties['날짜'] = {'date': null};
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
          properties['명료화'] = {'select': null};
        }
      }

      // Update status
      if (_selectedStatus != widget.task.status) {
        if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
          properties['상태'] = {
            'select': {
              'name': _selectedStatus!,
            }
          };
        } else {
          properties['상태'] = {'select': null};
        }
      }

      if (properties.isNotEmpty) {
        await widget.authService.apiService!.updatePage(widget.task.id, properties);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('변경사항이 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onUpdate(); // Trigger parent refresh
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _extractTextFromBlock(Map<String, dynamic> block) {
    final type = block['type'] as String?;
    if (type == null) return '';

    try {
      final blockData = block[type] as Map<String, dynamic>?;
      if (blockData == null) return '';

      final richText = blockData['rich_text'] as List<dynamic>?;
      if (richText == null) return '';

      return richText.map((text) {
        final textData = text as Map<String, dynamic>?;
        if (textData == null) return '';
        final plainText = textData['plain_text'] as String?;
        return plainText ?? '';
      }).join();
    } catch (e) {
      return '';
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
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
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
                    child: const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.task.status != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.task.status!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
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
                        color: Colors.white,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '페이지 내용을 로드하는 중...',
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
                        color: Colors.white,
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
                            // 기본 정보
                            if (widget.task.description?.isNotEmpty == true) ...[
                              _buildSectionHeader('📄 설명', '작업에 대한 상세 설명'),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  widget.task.description!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // 메타데이터 정보
                            Row(
                              children: [
                                Expanded(child: _buildSectionHeader('📊 정보', '작업 메타데이터')),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = !_isEditing;
                                    });
                                  },
                                  icon: Icon(
                                    _isEditing ? Icons.close : Icons.edit,
                                    color: _isEditing ? Colors.red : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('생성일', DateFormat('yyyy년 M월 d일 HH:mm', 'ko').format(widget.task.createdAt)),

                                  const SizedBox(height: 16),
                                  if (_isEditing) ...[
                                    // Editable date field
                                    const Text(
                                      '날짜',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectDate,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _selectedDate != null
                                                  ? DateFormat('yyyy년 M월 d일', 'ko').format(_selectedDate!)
                                                  : '날짜 선택',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _selectedDate != null ? const Color(0xFF1E293B) : Colors.grey[400],
                                              ),
                                            ),
                                            const Spacer(),
                                            if (_selectedDate != null)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedDate = null;
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.clear,
                                                  size: 20,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    // Editable clarification field
                                    const Text(
                                      '명료화',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedClarification,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(value: null, child: Text('선택 안함')),
                                        ...['다음행동', '프로젝트', '언젠가', '참고자료', '완료'].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ],
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedClarification = newValue;
                                        });
                                      },
                                    ),
                                  ] else ...[
                                    // Read-only display
                                    if (_selectedDate != null) ...[
                                      _buildInfoRow('날짜', DateFormat('yyyy년 M월 d일', 'ko').format(_selectedDate!)),
                                      const SizedBox(height: 12),
                                    ],
                                    if (_selectedClarification != null) ...[
                                      _buildInfoRow('명료화', _selectedClarification!),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 페이지 내용
                            if (_blocks.isNotEmpty) ...[
                              _buildSectionHeader('📝 페이지 내용', '${_blocks.length}개의 블록'),
                              const SizedBox(height: 12),
                              ..._blocks.asMap().entries.map((entry) {
                                final index = entry.key;
                                final block = entry.value;
                                final content = _extractTextFromBlock(block);
                                if (content.isEmpty) return const SizedBox.shrink();

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '블록 ${index + 1}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        content,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1E293B),
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 32),
                            ],

                            // 새 내용 추가
                            _buildSectionHeader('➕ 새 내용 추가', '페이지에 새로운 블록 추가'),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: _newContentController,
                                decoration: InputDecoration(
                                  hintText: '새로운 내용을 입력하세요...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                maxLines: 6,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAddingContent ? null : _saveTaskChanges,
                        icon: _isAddingContent
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(_isAddingContent ? '저장 중...' : '변경사항 저장'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAddingContent ? null : _addNewContent,
                        icon: _isAddingContent
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add, size: 20),
                        label: Text(_isAddingContent ? '추가 중...' : '내용 추가'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}