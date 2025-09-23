import 'package:flutter/material.dart';
import '../services/notion_auth_service.dart';
import '../models/notion_task.dart';

class ClarificationScreen extends StatefulWidget {
  const ClarificationScreen({Key? key}) : super(key: key);

  @override
  State<ClarificationScreen> createState() => _ClarificationScreenState();
}

class _ClarificationScreenState extends State<ClarificationScreen> {
  final NotionAuthService _authService = NotionAuthService();
  
  List<NotionTask> _todoItems = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadTodoItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침
    if (_isAuthenticated) {
      _loadTodoItems();
    }
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
  }

  /// 명료화 탭용 할일 로드 (4가지 조건)
  Future<void> _loadTodoItems() async {
    if (!_isAuthenticated) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _authService.getClarificationTasks();
      
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
        _todoItems = notionTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Notion API 호출 오류: $e');
      print('에러 타입: ${e.runtimeType}');
      _showErrorSnackBar('항목을 불러오는데 실패했습니다. 에러: $e');
    }
  }

  /// 실행 가능성 처리
  Future<void> _handleExecutable(NotionTask item, bool isExecutable) async {
    if (!_isAuthenticated) {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${item.title}" 분류 선택'),
        content: const Text('이 항목을 어떻게 분류하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToMemoWithCategory(item, '중간 작업물');
            },
            child: const Text('중간 작업물'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToMemoWithCategory(item, '나중에 보기');
            },
            child: const Text('나중에 보기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToMemoWithCategory(item, '레퍼런스');
            },
            child: const Text('레퍼런스'),
          ),
        ],
      ),
    );
  }

  /// 타입 선택 다이얼로그
  void _showTypeDialog(NotionTask item) {
    final classificationOptions = [
      {
        'title': '다음행동',
        'icon': Icons.play_arrow,
        'color': const Color(0xFF3B82F6),
        'action': () => _showNextActionDialog(item),
      },
      {
        'title': '위임',
        'icon': Icons.person,
        'color': const Color(0xFF10B981),
        'action': () => _classifyItem(item, '위임'),
      },
      {
        'title': '일정',
        'icon': Icons.schedule,
        'color': const Color(0xFFF59E0B),
        'action': () => _showDatePickerForSchedule(item),
      },
      {
        'title': '목표',
        'icon': Icons.flag,
        'color': const Color(0xFFEF4444),
        'action': () => _classifyItem(item, '목표'),
      },
      {
        'title': '프로젝트',
        'icon': Icons.folder,
        'color': const Color(0xFF8B5CF6),
        'action': () => _classifyItem(item, '프로젝트'),
      },
      {
        'title': '다시 알림',
        'icon': Icons.notifications,
        'color': const Color(0xFF06B6D4),
        'action': () => _showDatePickerForReminder(item),
      },
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Color(0xFF8B7355),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${item.title}" 분류',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '이 항목을 어떻게 분류하시겠습니까?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 2x3 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: classificationOptions.length,
                itemBuilder: (context, index) {
                  final option = classificationOptions[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      option['action']!();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (option['color'] as Color).withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (option['color'] as Color).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (option['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              option['icon'] as IconData,
                              color: option['color'] as Color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            option['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: option['color'] as Color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 메모 데이터베이스로 분류와 함께 이동
  Future<void> _moveToMemoWithCategory(NotionTask item, String category) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // TODO 데이터베이스에서 삭제
      await _authService.apiService!.deletePage(item.id);

      // 메모 데이터베이스에 추가
      final databaseId = '1159f5e4a81180e3a9f2fdf6634730e6'; // 메모 DB

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

      // 영역·자원 데이터베이스 선택 다이얼로그 표시
      _showAreaResourceDialog(item.title, createdPage['id'] as String);

      _loadTodoItems(); // 목록 새로고침
      _showSuccessSnackBar('"${item.title}"이(가) 메모 데이터베이스에 "$category"로 저장되었습니다.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('메모로 이동 중 오류가 발생했습니다: $e');
    }
  }

  /// 일정용 날짜 선택 다이얼로그
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

  /// 다시 알림용 날짜 선택 다이얼로그
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

  /// 날짜와 함께 항목 분류 (일정용)
  Future<void> _classifyItemWithDate(NotionTask item, String classification, DateTime date) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final updateProperties = <String, dynamic>{
        '명료화': {
          'select': {
            'name': classification,
          }
        },
        '날짜': {
          'date': {
            'start': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
          }
        }
      };

      await _authService.apiService!.updatePage(item.id, updateProperties);

      _loadTodoItems(); // 목록 새로고침
      _showSuccessSnackBar('"${item.title}"이(가) $classification으로 분류되었습니다. (날짜: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')})');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
    }
  }

  /// 항목 분류
  Future<void> _classifyItem(NotionTask item, String classification) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (classification == '목표' || classification == '프로젝트') {
        // 목표나 프로젝트인 경우 해당 데이터베이스로 이동
        await _moveToProjectOrGoal(item, classification);
      } else if (classification == '위임') {
        // 위임인 경우 추가 질문 없이 바로 처리
        final updateProperties = <String, dynamic>{
          '명료화': {
            'select': {
              'name': classification,
            }
          }
        };

        await _authService.apiService!.updatePage(item.id, updateProperties);
        _loadTodoItems(); // 목록 새로고침
        _showSuccessSnackBar('"${item.title}"이(가) $classification으로 분류되었습니다.');
      } else {
        // 다른 분류들
        final updateProperties = <String, dynamic>{
          '명료화': {
            'select': {
              'name': classification,
            }
          }
        };

        await _authService.apiService!.updatePage(item.id, updateProperties);
        _loadTodoItems(); // 목록 새로고침
        _showSuccessSnackBar('"${item.title}"이(가) $classification으로 분류되었습니다.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
    }
  }

  /// 목표나 프로젝트로 이동
  Future<void> _moveToProjectOrGoal(NotionTask item, String type) async {
    try {
      // 해당 데이터베이스에 새 페이지 생성
      String databaseId;
      if (type == '목표') {
        databaseId = '1159f5e4a81180d092add53ae9df7f05'; // 목표 데이터베이스
      } else {
        databaseId = '1159f5e4a81180019f29cdd24d369230'; // 프로젝트 데이터베이스
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

      // 할일 데이터베이스에서 삭제
      await _authService.apiService!.deletePage(item.id);

      // 영역·자원 데이터베이스 선택 다이얼로그 표시
      _showAreaResourceDialog(item.title, createdPage['id'] as String);

      _loadTodoItems(); // 목록 새로고침
      _showSuccessSnackBar('"${item.title}"이(가) $type 데이터베이스로 이동되었습니다.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('$type으로 이동 중 오류가 발생했습니다: $e');
    }
  }

  /// 영역·자원 데이터베이스 선택 다이얼로그
  Future<void> _showAreaResourceDialog(String title, String targetPageId) async {
    try {
      // 영역·자원 데이터베이스에서 항목들 가져오기
      final areaResourceItems = await _authService.apiService!.getAreaResourceItems();
      
      if (areaResourceItems.isEmpty) {
        // 영역·자원 데이터베이스가 비어있거나 없는 경우 기본 영역들 제공
        _showDefaultAreaResourceDialog(title, targetPageId);
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('"$title" 영역·자원 분류'),
          content: const Text('이 항목을 어떤 영역·자원으로 분류하시겠습니까?'),
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
      print('영역·자원 데이터베이스 접근 오류: $e');
      // 데이터베이스 접근에 실패한 경우 기본 영역들 제공
      _showDefaultAreaResourceDialog(title, targetPageId);
    }
  }

  /// 기본 영역·자원 선택 다이얼로그
  void _showDefaultAreaResourceDialog(String title, String targetPageId) {
    final defaultAreas = [
      {'name': '개인', 'icon': Icons.person},
      {'name': '업무', 'icon': Icons.work},
      {'name': '학습', 'icon': Icons.school},
      {'name': '건강', 'icon': Icons.favorite},
      {'name': '취미', 'icon': Icons.star},
      {'name': '가족', 'icon': Icons.family_restroom},
      {'name': '기타', 'icon': Icons.more_horiz},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Color(0xFF8B7355),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"$title" 영역 분류',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '이 항목을 어떤 영역으로 분류하시겠습니까?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 기본 영역들 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: defaultAreas.length,
                itemBuilder: (context, index) {
                  final area = defaultAreas[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _addDefaultAreaRelation(targetPageId, area['name'] as String);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B7355).withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B7355).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            area['icon'] as IconData,
                            color: const Color(0xFF8B7355),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            area['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B7355),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 다음 행동 상황 입력 다이얼로그
  Future<void> _showNextActionDialog(NotionTask item) async {
    try {
      // 기존 다음 행동 상황들을 가져오기
      final existingNextActions = await _getExistingNextActions();
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                // 내용
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이 항목의 다음 행동 상황을 입력하거나 선택하세요.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 기존 다음 행동 상황들
                        if (existingNextActions.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 20,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '기존 다음 행동 상황 (${existingNextActions.length}개)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 그리드 형태로 표시하여 더 많은 항목을 보여줌
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            action,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Color(0xFF64748B),
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
                        // 새로 입력하는 옵션
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.add,
                              color: Color(0xFF2563EB),
                            ),
                            title: const Text(
                              '새로 입력하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            subtitle: const Text(
                              '새로운 다음 행동 상황을 직접 입력하세요',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
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

  /// 기존 다음 행동 상황들 가져오기
  Future<List<String>> _getExistingNextActions() async {
    try {
      final nextActions = <String>{};
      
      // 1. 할일 데이터베이스에서 다음 행동 상황 가져오기
      try {
        final todoTasks = await _authService.apiService!.queryDatabase(
          '1159f5e4a81180e591cbc596ae52f611', // TODO_DB_ID
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
      
      // 2. 프로젝트 데이터베이스에서 다음 행동 상황 가져오기
      try {
        final projectTasks = await _authService.apiService!.queryDatabase(
          '1159f5e4a81180019f29cdd24d369230', // PROJECT_DB_ID
          null
        );
        
        for (final task in projectTasks) {
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
        print('프로젝트 데이터베이스에서 다음 행동 상황 가져오기 오류: $e');
      }
      
      // 3. 목표 데이터베이스에서 다음 행동 상황 가져오기
      try {
        final goalTasks = await _authService.apiService!.queryDatabase(
          '1159f5e4a81180d092add53ae9df7f05', // GOAL_DB_ID
          null
        );
        
        for (final task in goalTasks) {
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
        print('목표 데이터베이스에서 다음 행동 상황 가져오기 오류: $e');
      }
      
      // 4. 메모 데이터베이스에서 다음 행동 상황 가져오기
      try {
        final memoTasks = await _authService.apiService!.queryDatabase(
          '1159f5e4a81180e3a9f2fdf6634730e6', // MEMO_DB_ID
          null
        );
        
        for (final task in memoTasks) {
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
        print('메모 데이터베이스에서 다음 행동 상황 가져오기 오류: $e');
      }
      
      // 5. 기본적인 다음 행동 상황들 추가 (데이터가 없을 때 사용)
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
          '준비하기',
          '확인하기',
          '보고하기',
          '논의하기',
          '실행하기',
        ]);
      }
      
      return nextActions.toList()..sort();
    } catch (e) {
      print('기존 다음 행동 상황 가져오기 오류: $e');
      // 오류 발생 시 기본 목록 반환
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
        '준비하기',
        '확인하기',
        '보고하기',
        '논의하기',
        '실행하기',
      ];
    }
  }

  /// 커스텀 다음 행동 상황 입력 다이얼로그
  void _showCustomNextActionDialog(NotionTask item) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${item.title}" 다음 행동 상황'),
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

  /// 다음 행동 상황과 함께 항목 분류
  Future<void> _classifyItemWithNextAction(NotionTask item, String nextAction) async {
    try {
      setState(() {
        _isLoading = true;
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

      _loadTodoItems(); // 목록 새로고침
      _showSuccessSnackBar('"${item.title}"이(가) 다음행동으로 분류되었습니다. (다음 행동: $nextAction)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
    }
  }

  /// 영역·자원 관계 추가
  Future<void> _addAreaResourceRelation(String pageId, String areaResourceId, String areaResourceName) async {
    try {
      // 페이지에 영역·자원 관계 추가
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

  /// 기본 영역 관계 추가 (영역·자원 데이터베이스에 페이지 생성 후 관계 연결)
  Future<void> _addDefaultAreaRelation(String pageId, String areaName) async {
    try {
      // 1. 영역·자원 데이터베이스에 새 페이지 생성
      final areaResourcePageId = await _createAreaResourcePage(areaName);
      
      // 2. 노트 데이터베이스의 페이지에 영역·자원 관계 추가
      final updateProperties = <String, dynamic>{
        '영역 · 자원 데이터베이스': {
          'relation': [
            {
              'id': areaResourcePageId,
            }
          ]
        }
      };

      await _authService.apiService!.updatePage(pageId, updateProperties);
      _showSuccessSnackBar('영역 "$areaName"이(가) 추가되었습니다.');
    } catch (e) {
      print('기본 영역 추가 오류: $e');
      _showErrorSnackBar('영역 추가 중 오류가 발생했습니다: $e');
    }
  }

  /// 영역·자원 데이터베이스에 페이지 생성
  Future<String> _createAreaResourcePage(String areaName) async {
    try {
      final properties = <String, dynamic>{
        '이름': {
          'title': [
            {
              'text': {
                'content': areaName,
              }
            }
          ]
        },
        '분류': {
          'select': {
            'name': '영역',
          }
        },
      };

      final createdPage = await _authService.apiService!.createPage(
        '1159f5e4a81180e3a9f2fdf6634730e6', // MEMO_DB_ID (영역·자원 데이터베이스)
        properties
      );

      return createdPage['id'] as String;
    } catch (e) {
      print('영역·자원 페이지 생성 오류: $e');
      rethrow;
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
        _loadTodoItems();
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
      _todoItems.clear();
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
        title: const Text('명료화'),
        actions: [
          if (!_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _showApiKeyDialog,
              tooltip: 'Notion API 키 입력',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isAuthenticated ? _loadTodoItems : null,
            tooltip: '새로고침',
          ),
        ],
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
                    'Notion API 키를 입력하면\n명료화를 시작할 수 있습니다.',
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

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_todoItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTodoItems,
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
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '명료화할 항목이 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '완료되지 않은 모든 할일 항목들이 표시됩니다.\n각 항목을 분류하여 관리할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
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
      onRefresh: _loadTodoItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _todoItems.length,
        itemBuilder: (context, index) {
          final item = _todoItems[index];
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(NotionTask item) {
    // 기본 상태 표시
    String statusText = '명료화 필요';
    Color statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // 설명
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            // 상태 표시
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 질문
            const Text(
              '이것은 실행 가능한가요?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleExecutable(item, true),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      '예',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleExecutable(item, false),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      '아니요',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}