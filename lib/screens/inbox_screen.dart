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

  /// Notion에서 수집 탭용 할일 로드 (최근 추가된 항목들)
  Future<void> _loadNotionTasks() async {
    if (!_isNotionAuthenticated) return;
    
    setState(() {
      _isLoadingNotion = true;
    });

    try {
      // 최근 7일간 추가된 항목들을 가져오기
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final filter = <String, dynamic>{
        'and': <Map<String, dynamic>>[
          <String, dynamic>{
            'property': '완료',
            'checkbox': <String, dynamic>{
              'equals': false,
            }
          }
        ]
      };
      
      final items = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
        filter
      );
      
      // 생성일시 기준으로 최신순 정렬
      items.sort((a, b) {
        final aCreated = DateTime.tryParse(a['created_time'] ?? '') ?? DateTime(1970);
        final bCreated = DateTime.tryParse(b['created_time'] ?? '') ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });
      
      final notionTasks = items.map((item) => NotionTask.fromNotion(item)).toList();
      
      setState(() {
        _notionTasks = notionTasks;
        _isLoadingNotion = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingNotion = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notion 항목을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
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
                  onPressed: _loadNotionTasks,
                  icon: const Icon(
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
              child: CircularProgressIndicator(),
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
                            ? '수집된 항목이 없습니다'
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
                        '📋 최근 수집한 내용',
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
    return Container(
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
    );
  }

}
