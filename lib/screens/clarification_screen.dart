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
        title: Text('"${item.title}" 저장소 선택'),
        content: const Text('이 항목을 어디에 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToStorage(item, '메모');
            },
            child: const Text('메모'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToStorage(item, '아이디어');
            },
            child: const Text('아이디어'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToStorage(item, '읽을거리');
            },
            child: const Text('읽을거리'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToStorage(item, '취미');
            },
            child: const Text('취미'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToStorage(item, '언젠가');
            },
            child: const Text('언젠가'),
          ),
        ],
      ),
    );
  }

  /// 타입 선택 다이얼로그
  void _showTypeDialog(NotionTask item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${item.title}" 분류'),
        content: const Text('이 항목을 어떻게 분류하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _classifyItem(item, '다음행동');
            },
            child: const Text('다음행동'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _classifyItem(item, '위임');
            },
            child: const Text('위임'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDatePickerForSchedule(item);
            },
            child: const Text('일정'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _classifyItem(item, '목표');
            },
            child: const Text('목표'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _classifyItem(item, '프로젝트');
            },
            child: const Text('프로젝트'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDatePickerForReminder(item);
            },
            child: const Text('다시 알림'),
          ),
        ],
      ),
    );
  }

  /// 저장소로 이동
  Future<void> _moveToStorage(NotionTask item, String storageType) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // TODO 데이터베이스에서 삭제
      await _authService.apiService!.deletePage(item.id);

      // 해당 저장소에 추가
      String databaseId;
      switch (storageType) {
        case '메모':
        case '아이디어':
        case '읽을거리':
        case '취미':
          databaseId = '1159f5e4a81180e3a9f2fdf6634730e6'; // 메모 DB 사용
          break;
        case '언젠가':
          // 언젠가는 TODO 데이터베이스에 명료화를 '언젠가'로 설정
          databaseId = '1159f5e4a81180e591cbc596ae52f611';
          break;
        default:
          databaseId = '1159f5e4a81180e3a9f2fdf6634730e6';
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

      if (storageType == '언젠가') {
        properties['명료화'] = {
          'select': {
            'name': '언젠가',
          }
        };
      }

      await _authService.apiService!.createPage(databaseId, properties);

      _loadTodoItems(); // 목록 새로고침
      _showSuccessSnackBar('"${item.title}"이(가) $storageType에 저장되었습니다.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('저장 중 오류가 발생했습니다: $e');
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

      // description 속성 제거하고 명료화만 업데이트
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('분류 중 오류가 발생했습니다: $e');
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
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_todoItems.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todoItems.length,
      itemBuilder: (context, index) {
        final item = _todoItems[index];
        return _buildItemCard(item);
      },
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