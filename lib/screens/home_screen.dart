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
      // 오늘 날짜 할일 가져오기 (TODO 데이터베이스)
      final today = DateTime.now();
      final todayTasksData = await _authService.apiService!.getTasksByDate(today);
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

      // 진행중인 프로젝트 가져오기 (프로젝트 데이터베이스에서 상태가 '진행 중'인 것들)
      final projectsData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180019f29cdd24d369230', // PROJECT_DB_ID
        {
          "property": "상태",
          "status": {
            "equals": "진행 중"
          }
        }
      );
      final activeProjects = projectsData.map((data) => NotionTask.fromNotion(data)).toList();

      // 영역 데이터 가져오기 (영역·자원 데이터베이스에서 상태가 '영역'인 것들)
      final areaData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180d1ab17fa79bb0cf0f4', // AREA_RESOURCE_DB_ID
        {
          "property": "상태",
          "status": {
            "equals": "영역"
          }
        }
      );
      final areas = areaData.map((data) => NotionTask.fromNotion(data)).toList();

      // 자원 데이터 가져오기 (영역·자원 데이터베이스에서 상태가 '자원'인 것들)
      final resourceData = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180d1ab17fa79bb0cf0f4', // AREA_RESOURCE_DB_ID
        {
          "property": "상태",
          "status": {
            "equals": "자원"
          }
        }
      );
      final resources = resourceData.map((data) => NotionTask.fromNotion(data)).toList();

      setState(() {
        _notionTasks = todayTasks;
        _notionProjects = activeProjects;
        _pinnedNotes = pinnedNotes;
        _areaItems = areas;
        _resourceItems = resources;
      });
    } catch (e) {
      print('Failed to load Notion data: $e');
      _showErrorSnackBar('데이터를 불러오는데 실패했습니다: $e');
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
              _buildStatusCard('진행중 프로젝트', '${_notionProjects.length}개', const Color(0xFF10B981)),
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
            height: MediaQuery.of(context).size.height - 200,
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

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '💼 진행중 프로젝트',
          subtitle: '현재 작업중인 프로젝트들',
          tasks: _notionProjects,
          emptyMessage: '진행중인 프로젝트가 없습니다.',
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
            height: MediaQuery.of(context).size.height - 200,
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

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '🏢 영역',
          subtitle: '관리 영역 목록',
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
            height: MediaQuery.of(context).size.height - 200,
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

    return RefreshIndicator(
      onRefresh: _loadNotionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildNotionTaskList(
          title: '📚 자원',
          subtitle: '참고 자료 및 리소스',
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
    );
  }

  Color _getNotionTaskTypeColor(NotionTask task) {
    // DB별로 색상 구분
    if (task.clarification == '프로젝트') {
      return const Color(0xFF10B981);
    } else if (task.clarification == '할일') {
      return const Color(0xFF3B82F6);
    } else {
      return const Color(0xFFF59E0B);
    }
  }

  String _getNotionTaskTypeText(NotionTask task) {
    return task.clarification ?? '일반';
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