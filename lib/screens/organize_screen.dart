import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';

class OrganizeScreen extends StatefulWidget {
  const OrganizeScreen({super.key});

  @override
  State<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends State<OrganizeScreen> {
  String _currentView = 'areas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ItemProvider>().loadItems();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildViewSelector(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: _buildContent(),
                ),
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
      child:         const Text(
          '📦 아카이브',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildViewButton('영역', 'areas', Icons.business),
          _buildViewButton('자원', 'resources', Icons.library_books),
          _buildViewButton('목표', 'goals', Icons.flag),
          _buildViewButton('프로젝트', 'projects', Icons.work),
          _buildViewButton('할일', 'tasks', Icons.assignment),
          _buildViewButton('노트', 'notes', Icons.note),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, String view, IconData icon) {
    final isActive = _currentView == view;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _currentView = view),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            foregroundColor: isActive ? Colors.white : const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentView) {
      case 'areas':
        return _buildAreasView();
      case 'resources':
        return _buildResourcesView();
      case 'goals':
        return _buildGoalsView();
      case 'projects':
        return _buildProjectsView();
      case 'tasks':
        return _buildTasksView();
      case 'notes':
        return _buildNotesView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAreasView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: itemProvider.areaItems.isEmpty
                  ? const Center(
                      child: Text(
                        '영역이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: itemProvider.areaItems.length,
                      itemBuilder: (context, index) {
                        final area = itemProvider.areaItems[index];
                        return _buildHierarchyCard(
                          area,
                          '🏠',
                          _getAreaDescription(area, itemProvider.items),
                        );
                      },
                    ),
            ),
            _buildAddButton('영역 추가', ItemType.area),
          ],
        );
      },
    );
  }

  Widget _buildResourcesView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: itemProvider.resourceItems.isEmpty
                  ? const Center(
                      child: Text(
                        '자원이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: itemProvider.resourceItems.length,
                      itemBuilder: (context, index) {
                        final resource = itemProvider.resourceItems[index];
                        return _buildHierarchyCard(
                          resource,
                          '📚',
                          _getResourceDescription(resource, itemProvider.items),
                        );
                      },
                    ),
            ),
            _buildAddButton('자원 추가', ItemType.resource),
          ],
        );
      },
    );
  }

  Widget _buildStatsView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = itemProvider.getItemStats();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatCard('이번 주 완료', '${stats['completedThisWeek']}', Icons.check_circle),
              _buildStatCard('평균 완료율', '${stats['completionRate']}%', Icons.trending_up),
              _buildStatCard('진행 중 프로젝트', '${stats['activeProjects']}', Icons.work),
              _buildStatCard('전체 할일', '${stats['totalTasks']}', Icons.assignment),
              _buildStatCard('기한 지남', '${stats['overdueCount']}', Icons.warning),
              _buildStatCard('수집함', '${stats['inboxCount']}', Icons.inbox),
              const SizedBox(height: 24),
              _buildChartContainer(),
              const SizedBox(height: 24),
              _buildAchievementContainer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHierarchyCard(Item item, String icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '(0)', // TODO: 실제 자식 항목 수 계산
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 주간 완료 추이',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '차트 영역',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 최근 성취',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• 건강 루틴 7일 연속 달성',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const Text(
            '• 프로젝트 3개 완료',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const Text(
            '• 주간 점검 4주 연속 실시',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getAreaDescription(Item area, List<Item> allItems) {
    // TODO: 실제 자식 항목 수 계산
    final projectCount = 0; // allItems.where((item) => item.parentId == area.id && item.type == ItemType.project).length;
    final goalCount = 0; // allItems.where((item) => item.parentId == area.id && item.type == ItemType.goal).length;
    
    if (projectCount > 0 || goalCount > 0) {
      return '${projectCount}개 프로젝트, ${goalCount}개 목표';
    }
    return '항목 없음';
  }

  String _getResourceDescription(Item resource, List<Item> allItems) {
    // TODO: 실제 자식 항목 수 계산
    final noteCount = 0; // allItems.where((item) => item.parentId == resource.id && item.type == ItemType.note).length;
    
    if (noteCount > 0) {
      return '${noteCount}개 노트';
    }
    return '항목 없음';
  }

  Widget _buildGoalsView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final goals = itemProvider.items.where((item) => item.type == ItemType.goal).toList();

        return Column(
          children: [
            Expanded(
              child: goals.isEmpty
                  ? const Center(
                      child: Text(
                        '목표가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        return _buildItemCard(goal, '🎯');
                      },
                    ),
            ),
            _buildAddButton('목표 추가', ItemType.goal),
          ],
        );
      },
    );
  }

  Widget _buildProjectsView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = itemProvider.items.where((item) => item.type == ItemType.project).toList();

        return Column(
          children: [
            Expanded(
              child: projects.isEmpty
                  ? const Center(
                      child: Text(
                        '프로젝트가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _buildItemCard(project, '📋');
                      },
                    ),
            ),
            _buildAddButton('프로젝트 추가', ItemType.project),
          ],
        );
      },
    );
  }

  Widget _buildTasksView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = itemProvider.items.where((item) => item.type == ItemType.task).toList();

        return Column(
          children: [
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        '할일이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildItemCard(task, '✅');
                      },
                    ),
            ),
            _buildAddButton('할일 추가', ItemType.task),
          ],
        );
      },
    );
  }

  Widget _buildNotesView() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final notes = itemProvider.items.where((item) => item.type == ItemType.note).toList();

        return Column(
          children: [
            Expanded(
              child: notes.isEmpty
                  ? const Center(
                      child: Text(
                        '노트가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _buildItemCard(note, '📝');
                      },
                    ),
            ),
            _buildAddButton('노트 추가', ItemType.note),
          ],
        );
      },
    );
  }

  Widget _buildItemCard(Item item, String icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(item.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(item.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (item.content != null) ...[
            const SizedBox(height: 8),
            Text(
              item.content!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '우선순위: ${item.priority}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${item.createdAt.month}/${item.createdAt.day}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.completed:
        return const Color(0xFF059669);
      case ItemStatus.active:
        return const Color(0xFF2563EB);
      case ItemStatus.waiting:
        return const Color(0xFFF59E0B);
      case ItemStatus.someday:
        return const Color(0xFF6B7280);
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
      case ItemStatus.waiting:
        return '대기중';
      case ItemStatus.someday:
        return '언젠가';
      case ItemStatus.inbox:
        return '수집함';
      case ItemStatus.clarified:
        return '명료화됨';
      case ItemStatus.archived:
        return '보관됨';
    }
  }

  Widget _buildAddButton(String label, ItemType type) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddItemDialog(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(ItemType type) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getTypeLabel(type)} 추가'),
        content: Column(
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
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '내용 (선택사항)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addItem(type, titleController.text, contentController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(ItemType type) {
    switch (type) {
      case ItemType.area:
        return '영역';
      case ItemType.resource:
        return '자원';
      case ItemType.goal:
        return '목표';
      case ItemType.project:
        return '프로젝트';
      case ItemType.task:
        return '할일';
      case ItemType.note:
        return '노트';
    }
  }

  void _addItem(ItemType type, String title, String content) async {
    final itemProvider = context.read<ItemProvider>();
    
    try {
      await itemProvider.addItem(
        title: title,
        content: content.isNotEmpty ? content : null,
        type: type,
        status: ItemStatus.active,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getTypeLabel(type)}이 추가되었습니다.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }
}
