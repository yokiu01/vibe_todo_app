import 'package:flutter/material.dart';
import '../models/notion_task.dart';
import '../services/notion_auth_service.dart';
import '../utils/helpers.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/interactive_button.dart';
import '../widgets/loading_skeleton.dart';

class CollectionClarificationScreen extends StatefulWidget {
  const CollectionClarificationScreen({super.key});

  @override
  State<CollectionClarificationScreen> createState() => _CollectionClarificationScreenState();
}

class _CollectionClarificationScreenState extends State<CollectionClarificationScreen> {
  final TextEditingController _textController = TextEditingController();
  final NotionAuthService _authService = NotionAuthService();
  bool _isLoadingNotion = false;
  bool _isAdding = false;
  List<NotionTask> _notionTasks = [];
  List<NotionTask> _clarificationTasks = [];
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
      _loadData();
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
      _loadData();
    }
  }

  /// 데이터 로드 (수집함과 명료화 데이터 둘 다)
  Future<void> _loadData() async {
    if (!_isNotionAuthenticated) return;

    setState(() {
      _isLoadingNotion = true;
    });

    try {
      // 수집함 데이터 로드
      await _loadNotionTasks();

      // 명료화 데이터 로드
      await _loadClarificationTasks();

    } catch (e) {
      print('데이터 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotion = false;
        });
      }
    }
  }

  /// Notion에서 오늘 수집한 할일 로드
  Future<void> _loadNotionTasks() async {
    try {
      print('수집탭: Notion 데이터 로드 시작');

      // 모든 할일 항목을 가져온 후 클라이언트에서 오늘 생성된 것만 필터링
      final allItems = await _authService.apiService!.queryDatabase(
        '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
        null // 필터 없이 모든 항목 가져오기
      );
      print('수집탭: 전체 ${allItems.length}개 항목 로드됨');

      // 오늘 생성된 항목들만 필터링
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final todayItems = allItems.where((item) {
        final createdTime = item['created_time'] as String?;
        if (createdTime == null) return false;

        final created = DateTime.tryParse(createdTime);
        if (created == null) return false;

        return created.isAfter(today.subtract(const Duration(seconds: 1))) &&
               created.isBefore(tomorrow);
      }).toList();

      print('수집탭: 오늘 생성된 ${todayItems.length}개 항목 필터링됨');

      // 생성일시 기준으로 최신순 정렬
      todayItems.sort((a, b) {
        final aCreated = DateTime.tryParse(a['created_time'] ?? '') ?? DateTime(1970);
        final bCreated = DateTime.tryParse(b['created_time'] ?? '') ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });

      final notionTasks = todayItems.map((item) {
        try {
          return NotionTask.fromNotion(item);
        } catch (e) {
          print('NotionTask 변환 오류: $e');
          return null;
        }
      }).where((task) => task != null).cast<NotionTask>().toList();

      print('수집탭: ${notionTasks.length}개 NotionTask 생성됨');

      if (mounted) {
        setState(() {
          _notionTasks = notionTasks;
        });
      }
    } catch (e) {
      print('수집탭 로드 오류: $e');
      rethrow;
    }
  }

  /// 명료화 탭용 할일 로드
  Future<void> _loadClarificationTasks() async {
    try {
      final items = await _authService.getClarificationTasks();

      // 안전하게 NotionTask로 변환
      final clarificationTasks = <NotionTask>[];
      for (var item in items) {
        try {
          final task = NotionTask.fromNotion(item);
          clarificationTasks.add(task);
        } catch (e) {
          print('항목 변환 오류: $e');
          // 개별 항목 변환 실패는 무시하고 계속 진행
        }
      }

      if (mounted) {
        setState(() {
          _clarificationTasks = clarificationTasks;
        });
      }
    } catch (e) {
      print('명료화 데이터 로드 오류: $e');
      rethrow;
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
      _loadData();

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

  /// 실행 가능성 처리
  Future<void> _handleExecutable(NotionTask item, bool isExecutable) async {
    if (!_isNotionAuthenticated) {
      _showErrorSnackBar('Notion에 먼저 로그인해주세요.');
      return;
    }

    try {
      if (!isExecutable) {
        // 실행 불가능한 경우 - 저장소 선택 다이얼로그
        _showStorageDialog(item);
      } else {
        // 실행 가능한 경우 - 타입 선택 다이얼로그
        _showTypeDialog(item);
      }
    } catch (e) {
      _showErrorSnackBar('처리 중 오류가 발생했습니다: $e');
    }
  }

  /// 저장소 선택 다이얼로그
  void _showStorageDialog(NotionTask item) {
    final storageOptions = [
      _DialogOption(
        title: '중간 작업물',
        subtitle: '진행 중인 작업의 일부분',
        icon: Icons.construction_outlined,
        color: AppColors.warning,
        onTap: () {
          Navigator.of(context).pop();
          _moveToMemoWithCategory(item, '중간 작업물');
        },
      ),
      _DialogOption(
        title: '나중에 보기',
        subtitle: '추후에 다시 검토할 내용',
        icon: Icons.schedule_outlined,
        color: AppColors.accentBlue,
        onTap: () {
          Navigator.of(context).pop();
          _moveToMemoWithCategory(item, '나중에 보기');
        },
      ),
      _DialogOption(
        title: '레퍼런스',
        subtitle: '참고 자료 및 정보',
        icon: Icons.library_books_outlined,
        color: AppColors.accentGreen,
        onTap: () {
          Navigator.of(context).pop();
          _moveToMemoWithCategory(item, '레퍼런스');
        },
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentOrange,
                      AppColors.accentOrange.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
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
                        Icons.storage_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '저장소 선택',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '"${item.title.length > 20 ? '${item.title.substring(0, 20)}...' : item.title}"',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.accentOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '지금 당장 실행할 수 없는 아이디어를 저장해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Storage options in vertical list
                    Column(
                      children: storageOptions.map((option) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildStorageOptionCard(option),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 타입 선택 다이얼로그 (2x3 그리드)
  void _showTypeDialog(NotionTask item) {
    final options = [
      _DialogOption(
        title: '다음행동',
        subtitle: '바로 실행할 수 있는 작업',
        icon: Icons.play_arrow_rounded,
        color: AppColors.accentBlue,
        onTap: () {
          Navigator.of(context).pop();
          _showNextActionDialog(item);
        },
      ),
      _DialogOption(
        title: '위임',
        subtitle: '다른 사람에게 맡길 일',
        icon: Icons.people_outline,
        color: AppColors.accentOrange,
        onTap: () {
          Navigator.of(context).pop();
          _classifyItem(item, '위임');
        },
      ),
      _DialogOption(
        title: '일정',
        subtitle: '특정 날짜에 해야 할 일',
        icon: Icons.event_outlined,
        color: AppColors.accentGreen,
        onTap: () {
          Navigator.of(context).pop();
          _showDatePickerForSchedule(item);
        },
      ),
      _DialogOption(
        title: '목표',
        subtitle: '달성하고자 하는 목표',
        icon: Icons.flag_outlined,
        color: AppColors.primaryBrown,
        onTap: () {
          Navigator.of(context).pop();
          _classifyItem(item, '목표');
        },
      ),
      _DialogOption(
        title: '프로젝트',
        subtitle: '여러 단계로 이뤄진 작업',
        icon: Icons.work_outline,
        color: AppColors.accentBlue,
        onTap: () {
          Navigator.of(context).pop();
          _classifyItem(item, '프로젝트');
        },
      ),
      _DialogOption(
        title: '다시 알림',
        subtitle: '나중에 다시 생각해볼 일',
        icon: Icons.notifications_outlined,
        color: AppColors.warning,
        onTap: () {
          Navigator.of(context).pop();
          _showDatePickerForReminder(item);
        },
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentBlue,
                      AppColors.accentBlue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
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
                        Icons.category_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '분류 선택',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '"${item.title.length > 20 ? '${item.title.substring(0, 20)}...' : item.title}"',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        '이 항목을 어떻게 분류하시겠습니까?',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // 2x3 Grid
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            return _buildDialogOptionCard(option);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 다른 메서드들은 기존 clarification_screen.dart에서 가져옴
  Future<void> _moveToMemoWithCategory(NotionTask item, String category) async {
    try {
      setState(() {
        _isLoadingNotion = true;
      });

      await _authService.apiService!.deletePage(item.id);

      final databaseId = '1159f5e4a81180e3a9f2fdf6634730e6'; // MEMO_DB_ID (메모 데이터베이스)

      final properties = <String, dynamic>{
        '이름': {
          'title': [
            {
              'text': {
                'content': item.title,
              }
            }
          ]
        },
        '분류': {
          'select': {
            'name': category,
          }
        },
      };

      final createdPage = await _authService.apiService!.createPage(databaseId, properties);
      _showAreaResourceDialog(item.title, createdPage['id'] as String);

      _loadData();
      _showSuccessSnackBar('"${item.title}"이(가) 메모 데이터베이스에 "$category"로 저장되었습니다.');
    } catch (e) {
      setState(() {
        _isLoadingNotion = false;
      });
      _showErrorSnackBar('메모로 이동 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _showDatePickerForSchedule(NotionTask item) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (selectedDate != null) {
      await _classifyItemWithDate(item, '일정', selectedDate);
    }
  }

  Future<void> _showDatePickerForReminder(NotionTask item) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (selectedDate != null) {
      await _classifyItemWithDate(item, '다시 알림', selectedDate);
    }
  }

  Future<void> _classifyItemWithDate(NotionTask item, String classification, DateTime date) async {
    try {
      setState(() {
        _isLoadingNotion = true;
      });

      final updateProperties = <String, dynamic>{
        '명료화': {
          'select': {
            'name': classification,
          }
        },
        '날짜': {
          'date': {
            'start': date.toIso8601String().split('T')[0],
          }
        }
      };

      await _authService.apiService!.updatePage(item.id, updateProperties);

      _loadData();
      _showSuccessSnackBar('"${item.title}"이(가) $classification으로 분류되었습니다. (날짜: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')})');
    } catch (e) {
      setState(() {
        _isLoadingNotion = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _classifyItem(NotionTask item, String classification) async {
    try {
      setState(() {
        _isLoadingNotion = true;
      });

      if (classification == '목표' || classification == '프로젝트') {
        await _moveToProjectOrGoal(item, classification);
      } else if (classification == '위임') {
        final updateProperties = <String, dynamic>{
          '명료화': {
            'select': {
              'name': classification,
            }
          }
        };

        await _authService.apiService!.updatePage(item.id, updateProperties);
        _loadData();
        _showSuccessSnackBar('"${item.title}"이(가) $classification으로 분류되었습니다.');
      } else {
        final updateProperties = <String, dynamic>{
          '명료화': {
            'select': {
              'name': classification,
            }
          }
        };

        await _authService.apiService!.updatePage(item.id, updateProperties);
        _loadData();
        _showSuccessSnackBar('"${item.title}"이(가) $classification으로 분류되었습니다.');
      }
    } catch (e) {
      setState(() {
        _isLoadingNotion = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _moveToProjectOrGoal(NotionTask item, String type) async {
    try {
      String databaseId;
      if (type == '목표') {
        databaseId = '1159f5e4a81180d092add53ae9df7f05';
      } else {
        databaseId = '1159f5e4a81180019f29cdd24d369230';
      }

      final properties = <String, dynamic>{
        '이름': {
          'title': [
            {
              'text': {
                'content': item.title,
              }
            }
          ]
        },
      };

      if (item.description != null && item.description!.isNotEmpty) {
        properties['description'] = {
          'rich_text': [
            {
              'text': {
                'content': item.description!,
              }
            }
          ]
        };
      }

      final createdPage = await _authService.apiService!.createPage(databaseId, properties);
      await _authService.apiService!.deletePage(item.id);
      _showAreaResourceDialog(item.title, createdPage['id'] as String);

      _loadData();
      _showSuccessSnackBar('"${item.title}"이(가) $type 데이터베이스로 이동되었습니다.');
    } catch (e) {
      setState(() {
        _isLoadingNotion = false;
      });
      _showErrorSnackBar('$type으로 이동 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _showAreaResourceDialog(String title, String targetPageId) async {
    try {
      final areaResourceItems = await _authService.apiService!.getAreaResourceItems();

      if (areaResourceItems.isEmpty) {
        _showErrorSnackBar('영역·자원 데이터베이스에 항목이 없습니다.');
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('"$title" 영역·자원 분류', style: AppTextStyles.h2),
          content: Text('이 항목을 어떤 영역·자원으로 분류하시겠습니까?', style: AppTextStyles.body),
          actions: [
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...areaResourceItems.map((item) {
                      final properties = item['properties'] as Map<String, dynamic>?;
                      final nameProperty = properties?['이름'] as Map<String, dynamic>?;
                      final titleArray = nameProperty?['title'] as List?;
                      final itemTitle = titleArray?.isNotEmpty == true
                          ? titleArray![0]['text']['content'] as String?
                          : 'Unknown';

                      return ListTile(
                        title: Text(itemTitle ?? 'Unknown'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _addAreaResourceRelation(targetPageId, item['id'] as String, itemTitle ?? 'Unknown');
                        },
                      );
                    }).toList(),
                    ListTile(
                      title: const Text('건너뛰기'),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('영역·자원 목록을 가져오는데 실패했습니다: $e');
    }
  }

  Future<void> _showNextActionDialog(NotionTask item) async {
    try {
      final existingNextActions = await _getExistingNextActions();

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B7355),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${item.title}" 다음 행동 상황',
                          style: AppTextStyles.navTitle.copyWith(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이 항목의 다음 행동 상황을 입력하거나 선택하세요.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 20),
                        if (existingNextActions.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 20,
                                color: Color(0xFF8B7355),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '기존 다음 행동 상황 (${existingNextActions.length}개)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF3C2A21),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: existingNextActions.length,
                            itemBuilder: (context, index) {
                              final action = existingNextActions[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDF6E3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFDDD4C0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _classifyItemWithNextAction(item, action);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 44),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            action,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF3C2A21),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Color(0xFF9C8B73),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B7355).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF8B7355).withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.add,
                              color: Color(0xFF8B7355),
                            ),
                            title: const Text(
                              '새로 입력하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B7355),
                              ),
                            ),
                            subtitle: const Text(
                              '새로운 다음 행동 상황을 직접 입력하세요',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9C8B73),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showCustomNextActionDialog(item);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('다음 행동 상황 목록을 가져오는데 실패했습니다: $e');
    }
  }

  Future<List<String>> _getExistingNextActions() async {
    try {
      final nextActions = <String>{};

      try {
        final todoTasks = await _authService.apiService!.queryDatabase(
          '1159f5e4a81180e591cbc596ae52f611',
          null
        );

        for (final task in todoTasks) {
          final properties = task['properties'] as Map<String, dynamic>?;
          if (properties == null) continue;

          final nextActionProperty = properties['다음 행동 상황'] as Map<String, dynamic>?;
          final multiSelect = nextActionProperty?['multi_select'] as List?;

          if (multiSelect != null && multiSelect.isNotEmpty) {
            for (final item in multiSelect) {
              final name = item['name'] as String?;
              if (name != null && name.isNotEmpty) {
                nextActions.add(name);
              }
            }
          }
        }
      } catch (e) {
        print('할일 데이터베이스에서 다음 행동 상황 가져오기 오류: $e');
      }

      if (nextActions.isEmpty) {
        nextActions.addAll([
          '이메일 보내기',
          '전화하기',
          '문서 작성하기',
          '회의 일정 잡기',
          '검토하기',
          '분석하기',
          '계획 세우기',
          '조사하기',
          '연락하기',
          '정리하기',
        ]);
      }

      return nextActions.toList()..sort();
    } catch (e) {
      print('기존 다음 행동 상황 가져오기 오류: $e');
      return [
        '이메일 보내기',
        '전화하기',
        '문서 작성하기',
        '회의 일정 잡기',
        '검토하기',
        '분석하기',
        '계획 세우기',
        '조사하기',
        '연락하기',
        '정리하기',
      ];
    }
  }

  void _showCustomNextActionDialog(NotionTask item) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${item.title}" 다음 행동 상황', style: AppTextStyles.h2),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '다음 행동 상황을 입력하세요',
            hintText: '예: 이메일 보내기, 전화하기, 문서 작성하기',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _classifyItemWithNextAction(item, textController.text.trim());
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _classifyItemWithNextAction(NotionTask item, String nextAction) async {
    try {
      setState(() {
        _isLoadingNotion = true;
      });

      final updateProperties = <String, dynamic>{
        '명료화': {
          'select': {
            'name': '다음행동',
          }
        },
        '다음 행동 상황': {
          'multi_select': [
            {
              'name': nextAction,
            }
          ]
        }
      };

      await _authService.apiService!.updatePage(item.id, updateProperties);

      _loadData();
      _showSuccessSnackBar('"${item.title}"이(가) 다음행동으로 분류되었습니다. (다음 행동: $nextAction)');
    } catch (e) {
      setState(() {
        _isLoadingNotion = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _addAreaResourceRelation(String pageId, String areaResourceId, String areaResourceName) async {
    try {
      final updateProperties = <String, dynamic>{
        '영역 · 자원 데이터베이스': {
          'relation': [
            {
              'id': areaResourceId,
            }
          ]
        }
      };

      await _authService.apiService!.updatePage(pageId, updateProperties);
      _showSuccessSnackBar('영역·자원 "$areaResourceName"이(가) 추가되었습니다.');
    } catch (e) {
      _showErrorSnackBar('영역·자원 추가 중 오류가 발생했습니다: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildInputSection(),
                const SizedBox(height: 32),
                _buildClarificationSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentOrange.withOpacity(0.1),
                  AppColors.accentOrange.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb,
              color: AppColors.accentOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 수집·명료화',
                  style: AppTextStyles.h1,
                ),
                Text(
                  '아이디어 수집과 명료화 과정',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (_isNotionAuthenticated)
            Container(
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _isLoadingNotion ? null : _loadData,
                icon: _isLoadingNotion
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: AppColors.accentOrange,
                        size: 20,
                      ),
                tooltip: '데이터 새로고침',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '무엇이든 적어보세요...',
                  hintStyle: AppTextStyles.bodyWithColor(AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.accentOrange.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addToNotion(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: _textController.text.trim().isNotEmpty && !_isAdding
                  ? LinearGradient(
                      colors: [AppColors.accentOrange, AppColors.accentOrange.withOpacity(0.8)],
                    )
                  : null,
              color: _textController.text.trim().isEmpty || _isAdding
                  ? AppColors.gray300
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _textController.text.trim().isNotEmpty && !_isAdding
                  ? [
                      BoxShadow(
                        color: AppColors.accentOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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



  Widget _buildClarificationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: AppColors.accentOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '명료화',
                    style: AppTextStyles.h1,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentOrange, AppColors.accentOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_clarificationTasks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _clarificationTasks.isEmpty
              ? Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: AppColors.accentOrange.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '모든 항목이 명료화되었습니다! ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '새로운 아이디어를 수집해보세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _clarificationTasks.length,
                  itemBuilder: (context, index) {
                    final item = _clarificationTasks[index];
                    return _buildClarificationItem(item);
                  },
                ),
        ],
      ),
    );
  }

  Color _getPriorityColor(NotionTask item) {
    // Check if item has urgent keywords or due date
    final title = item.title.toLowerCase();
    final description = (item.description ?? '').toLowerCase();

    if (title.contains('긴급') || title.contains('급함') || description.contains('긴급') || description.contains('급함')) {
      return AppColors.priorityUrgent;
    } else if (title.contains('중요') || description.contains('중요')) {
      return AppColors.priorityImportant;
    } else {
      return AppColors.priorityNormal;
    }
  }

  Color _getStateColor(NotionTask item) {
    // Check for completion or planning state
    final title = item.title.toLowerCase();
    final description = (item.description ?? '').toLowerCase();

    if (title.contains('완료') || description.contains('완료')) {
      return AppColors.completed;
    } else if (title.contains('계획') || description.contains('계획')) {
      return AppColors.planning;
    } else if (title.contains('긴급') || description.contains('긴급')) {
      return AppColors.urgent;
    } else {
      return AppColors.normal;
    }
  }

  IconData _getStateIcon(Color stateColor) {
    if (stateColor == AppColors.completed) {
      return Icons.check_circle_outline;
    } else if (stateColor == AppColors.planning) {
      return Icons.schedule_outlined;
    } else if (stateColor == AppColors.urgent) {
      return Icons.priority_high;
    } else {
      return Icons.psychology;
    }
  }

  String _getStateText(Color stateColor) {
    if (stateColor == AppColors.completed) {
      return '완료됨';
    } else if (stateColor == AppColors.planning) {
      return '계획 중';
    } else if (stateColor == AppColors.urgent) {
      return '긴급 처리';
    } else {
      return '명료화 필요';
    }
  }

  Widget _buildClarificationItem(NotionTask item) {
    final priorityColor = _getPriorityColor(item);
    final stateColor = _getStateColor(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: stateColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Add subtle haptic feedback on tap
              // HapticFeedback.lightImpact();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: stateColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.h3,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: priorityColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    priorityColor == AppColors.priorityUrgent ? '긴급' :
                    priorityColor == AppColors.priorityImportant ? '중요' : '일반',
                    style: AppTextStyles.caption.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stateColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStateIcon(stateColor),
                    size: 14,
                    color: stateColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStateText(stateColor),
                    style: AppTextStyles.caption.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '이것은 실행 가능한가요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InteractiveButton(
                    text: '예',
                    onPressed: () => _handleExecutable(item, true),
                    style: InteractiveButtonStyle.success,
                    icon: Icons.check_circle_outline,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InteractiveButton(
                    text: '아니요',
                    onPressed: () => _handleExecutable(item, false),
                    style: InteractiveButtonStyle.secondary,
                    icon: Icons.lightbulb_outline,
                    height: 48,
                  ),
                ),
              ],
            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 다이얼로그 옵션 카드 (2x3 그리드용)
  Widget _buildDialogOptionCard(_DialogOption option) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: option.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: option.color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: option.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    option.icon,
                    color: option.color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    option.title,
                    style: AppTextStyles.buttonSmall.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    option.subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 저장소 옵션 카드 (세로형)
  Widget _buildStorageOptionCard(_DialogOption option) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: option.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: option.color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: option.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    option.icon,
                    color: option.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 다이얼로그 옵션 데이터 클래스
class _DialogOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _DialogOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}