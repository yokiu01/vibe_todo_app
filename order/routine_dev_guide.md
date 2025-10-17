# 🔄 루틴 탭 개발 가이드

## 📋 프로젝트 개요

일정관리 앱에 **루틴(Routine) 기능**을 추가합니다. 루틴은 매일 반복되는 작업을 자동으로 생성하여 사용자가 습관을 형성하고 관리할 수 있도록 돕는 기능입니다.

---

## 🎯 개발 목표

1. **루틴 관리 화면**: 루틴 생성, 수정, 삭제, 활성화/비활성화
2. **자동 Task 생성**: 매일 앱 시작 시 조건에 맞는 루틴을 Tasks로 자동 생성
3. **Streak 추적**: 연속 수행 일수 계산 및 표시
4. **홈 화면 통합**: 오늘의 루틴을 Today 탭에 표시
5. **Notion 연동**: Routines 데이터베이스와 실시간 동기화

---

## 🗄️ Notion 데이터베이스 구조

### Routines Database
- **URL**: `https://www.notion.so/28d9f5e4a811806d9f2cdfa30eb470d3`
- **Data Source ID**: `28d9f5e4-a811-802f-8483-000b23580768`

#### 속성 (Properties)

| 속성명 | 타입 | 설명 | 필수 |
|--------|------|------|------|
| `이름` | Title | 루틴 이름 | ✅ |
| `루틴 활성화 상태` | Select | Active, Paused, Archived | ✅ |
| `Category` | Select | 🏃 운동, 📚 공부, 🧘 명상, 💼 업무, 🏠 생활 | ✅ |
| `루틴 수행 시간` | Text | HH:MM 형식 (예: 08:00) | ✅ |
| `반복 주기` | Multi-select | 매일, 주중, 주말, 월~일 | ✅ |
| `Duration` | Number | 예상 소요 시간(분) | ⚪ |
| `Priority` | Select | High, Medium, Low | ⚪ |
| `Streak` | Number | 연속 수행 일수 | ⚪ |
| `Last Generated Date` | Date | 마지막 Task 생성 날짜 | ⚪ |
| `생성일` | Created time | 루틴 생성 시점 (자동) | ⚪ |

#### SQLite 스키마
```sql
CREATE TABLE routines (
    url TEXT UNIQUE,
    "이름" TEXT,
    "루틴 활성화 상태" TEXT,        -- Active, Paused, Archived
    "Category" TEXT,               -- 🏃 운동, 📚 공부, etc.
    "루틴 수행 시간" TEXT,
    "Duration" FLOAT,
    "Streak" FLOAT,
    "Priority" TEXT,               -- High, Medium, Low
    "반복 주기" TEXT,               -- JSON array
    "date:Last Generated Date:start" TEXT,
    "date:Last Generated Date:is_datetime" INTEGER,
    "생성일" INTEGER NOT NULL
)
```

---

## 📁 파일 구조

```
lib/
├── models/
│   └── routine.dart                    # 신규: Routine 모델
├── providers/
│   └── routine_provider.dart           # 신규: Routine 상태 관리
├── screens/
│   ├── plan_screen.dart                # 수정: 루틴 관리 탭 추가
│   ├── home_screen.dart                # 수정: Today 탭에 루틴 표시
│   └── routine/
│       ├── routine_management_screen.dart  # 신규: 루틴 관리 화면
│       ├── routine_form_screen.dart        # 신규: 루틴 생성/수정 폼
│       └── routine_card.dart               # 신규: 루틴 카드 위젯
├── services/
│   └── notion_service.dart             # 수정: Routine CRUD 메서드 추가
└── main.dart                           # 수정: RoutineProvider 등록
```

---

## 🔧 1단계: 모델 생성 (routine.dart)

### Routine 모델

```dart
class Routine {
  final String id;
  final String url;
  final String name;
  final String status;           // Active, Paused, Archived
  final String? category;        // 🏃 운동, 📚 공부, etc.
  final String time;             // HH:MM
  final List<String> frequency;  // ["매일"], ["월", "수", "금"]
  final int? duration;           // 분 단위
  final String? priority;        // High, Medium, Low
  final int streak;
  final DateTime? lastGeneratedDate;
  final DateTime createdTime;

  Routine({
    required this.id,
    required this.url,
    required this.name,
    required this.status,
    this.category,
    required this.time,
    required this.frequency,
    this.duration,
    this.priority,
    this.streak = 0,
    this.lastGeneratedDate,
    required this.createdTime,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      url: json['url'],
      name: json['properties']['이름'] ?? '',
      status: json['properties']['루틴 활성화 상태'] ?? 'Paused',
      category: json['properties']['Category'],
      time: json['properties']['루틴 수행 시간'] ?? '00:00',
      frequency: _parseFrequency(json['properties']['반복 주기']),
      duration: json['properties']['Duration']?.toInt(),
      priority: json['properties']['Priority'],
      streak: (json['properties']['Streak'] ?? 0).toInt(),
      lastGeneratedDate: _parseDate(json['properties']['date:Last Generated Date:start']),
      createdTime: DateTime.parse(json['properties']['생성일']),
    );
  }

  Map<String, dynamic> toNotionProperties() {
    return {
      '이름': name,
      '루틴 활성화 상태': status,
      'Category': category,
      '루틴 수행 시간': time,
      '반복 주기': jsonEncode(frequency),
      'Duration': duration,
      'Priority': priority,
      'Streak': streak,
      if (lastGeneratedDate != null)
        'date:Last Generated Date:start': lastGeneratedDate!.toIso8601String().split('T')[0],
      if (lastGeneratedDate != null)
        'date:Last Generated Date:is_datetime': 0,
    };
  }

  static List<String> _parseFrequency(String? frequencyJson) {
    if (frequencyJson == null || frequencyJson.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(frequencyJson));
    } catch (e) {
      return [];
    }
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  Routine copyWith({
    String? name,
    String? status,
    String? category,
    String? time,
    List<String>? frequency,
    int? duration,
    String? priority,
    int? streak,
    DateTime? lastGeneratedDate,
  }) {
    return Routine(
      id: id,
      url: url,
      name: name ?? this.name,
      status: status ?? this.status,
      category: category ?? this.category,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      streak: streak ?? this.streak,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      createdTime: createdTime,
    );
  }
}
```

---

## 🔧 2단계: Provider 생성 (routine_provider.dart)

### RoutineProvider

```dart
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/notion_service.dart';

class RoutineProvider extends ChangeNotifier {
  final NotionService _notionService;
  
  // Constants
  static const String ROUTINES_DB_ID = '28d9f5e4a811806d9f2cdfa30eb470d3';
  static const String DATA_SOURCE_ID = '28d9f5e4-a811-802f-8483-000b23580768';
  
  // State
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;

  RoutineProvider(this._notionService);

  // Getters
  List<Routine> get routines => _routines;
  List<Routine> get activeRoutines => 
      _routines.where((r) => r.status == 'Active').toList();
  List<Routine> get pausedRoutines => 
      _routines.where((r) => r.status == 'Paused').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 초기화: 루틴 로드 + 오늘의 Task 생성
  Future<void> initialize() async {
    await loadRoutines();
    await generateTodayTasks();
  }

  /// 루틴 목록 로드
  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _notionService.queryDatabase(
        databaseId: DATA_SOURCE_ID,
        sorts: [{'property': '루틴 수행 시간', 'direction': 'ascending'}],
      );

      _routines = results.map((json) => Routine.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = '루틴을 불러오는 중 오류가 발생했습니다: $e';
      print('Error loading routines: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 오늘의 루틴 → Task 자동 생성
  Future<void> generateTodayTasks() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      for (final routine in activeRoutines) {
        if (await _shouldGenerateTask(routine, now, today)) {
          await _createTaskFromRoutine(routine, todayStr);
          await _updateLastGeneratedDate(routine.id, todayStr);
        }
      }
    } catch (e) {
      print('Error generating today tasks: $e');
    }
  }

  /// Task 생성 조건 확인
  Future<bool> _shouldGenerateTask(Routine routine, DateTime now, DateTime today) async {
    // 1. 요일 확인
    final dayOfWeek = _getDayOfWeek(now);
    if (!_isFrequencyMatch(routine.frequency, dayOfWeek)) {
      return false;
    }

    // 2. 시간 확인 (루틴 시간이 현재 시간보다 이전인지 - 선택적)
    // final routineTime = _parseTime(routine.time, today);
    // if (routineTime.isAfter(now)) return false;

    // 3. 중복 생성 방지: 오늘 이미 생성했는지 확인
    if (routine.lastGeneratedDate != null) {
      final lastGenDate = DateTime(
        routine.lastGeneratedDate!.year,
        routine.lastGeneratedDate!.month,
        routine.lastGeneratedDate!.day,
      );
      if (lastGenDate.isAtSameMomentAs(today)) {
        return false; // 오늘 이미 생성됨
      }
    }

    return true;
  }

  /// 요일 문자열 반환 (월, 화, 수, ...)
  String _getDayOfWeek(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  /// 반복 주기 매칭 확인
  bool _isFrequencyMatch(List<String> frequency, String dayOfWeek) {
    if (frequency.contains('매일')) return true;
    if (frequency.contains('주중') && ['월', '화', '수', '목', '금'].contains(dayOfWeek)) {
      return true;
    }
    if (frequency.contains('주말') && ['토', '일'].contains(dayOfWeek)) {
      return true;
    }
    return frequency.contains(dayOfWeek);
  }

  /// Task 생성
  Future<void> _createTaskFromRoutine(Routine routine, String todayStr) async {
    try {
      await _notionService.createPages(
        dataSourceId: 'YOUR_TASKS_DATA_SOURCE_ID', // Tasks DB의 Data Source ID
        pages: [
          {
            '이름': '🔄 ${routine.name}',  // 루틴 표시
            'Status': 'Not started',
            'Date': todayStr,
            'Category': routine.category,
            'Duration': routine.duration,
            'Priority': routine.priority,
            'Is Routine': true,  // Tasks DB에 Checkbox 필드 필요
            // 'Routine ID': routine.id,  // Tasks DB에 Relation 필드 필요
          }
        ],
      );
    } catch (e) {
      print('Error creating task from routine ${routine.name}: $e');
    }
  }

  /// 마지막 생성 날짜 업데이트
  Future<void> _updateLastGeneratedDate(String routineId, String date) async {
    try {
      await _notionService.updatePage(
        pageId: routineId,
        properties: {
          'date:Last Generated Date:start': date,
          'date:Last Generated Date:is_datetime': 0,
        },
      );
      // 로컬 상태도 업데이트
      final index = _routines.indexWhere((r) => r.id == routineId);
      if (index != -1) {
        _routines[index] = _routines[index].copyWith(
          lastGeneratedDate: DateTime.parse(date),
        );
      }
    } catch (e) {
      print('Error updating last generated date: $e');
    }
  }

  /// 루틴 생성
  Future<void> createRoutine(Map<String, dynamic> properties) async {
    try {
      await _notionService.createPages(
        dataSourceId: DATA_SOURCE_ID,
        pages: [properties],
      );
      await loadRoutines();
    } catch (e) {
      _error = '루틴 생성 실패: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 루틴 수정
  Future<void> updateRoutine(String pageId, Map<String, dynamic> properties) async {
    try {
      await _notionService.updatePage(pageId: pageId, properties: properties);
      await loadRoutines();
    } catch (e) {
      _error = '루틴 수정 실패: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 루틴 삭제 (Archived로 변경)
  Future<void> archiveRoutine(String pageId) async {
    await updateRoutine(pageId, {'루틴 활성화 상태': 'Archived'});
  }

  /// Streak 계산 및 업데이트
  Future<void> calculateStreaks() async {
    // TODO: Tasks DB 조회하여 각 루틴의 연속 수행 일수 계산
    // 최근 30일 완료 기록 분석 → 연속된 날짜 카운트
  }

  /// 루틴 완료 시 호출
  Future<void> onRoutineCompleted(String routineId) async {
    await calculateStreaks();
    notifyListeners();
  }
}
```

---

## 🔧 3단계: UI 화면 구현

### 3-1. PlanScreen 수정 (plan_screen.dart)

```dart
// TabBar에 루틴 탭 추가
TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'Task Management'),
    Tab(text: 'PDS Plan'),
    Tab(text: 'PDS Do/See'),
    Tab(text: '루틴 관리'),  // 신규 탭
  ],
)

// TabBarView에 화면 추가
TabBarView(
  controller: _tabController,
  children: [
    TaskManagementScreen(),
    PDSPlanScreen(),
    PDSDoSeeScreen(),
    RoutineManagementScreen(),  // 신규 화면
  ],
)
```

### 3-2. RoutineManagementScreen (routine_management_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import 'routine_form_screen.dart';
import 'routine_card.dart';

class RoutineManagementScreen extends StatefulWidget {
  @override
  _RoutineManagementScreenState createState() => _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends State<RoutineManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          final activeRoutines = provider.activeRoutines;
          final pausedRoutines = provider.pausedRoutines;

          return CustomScrollView(
            slivers: [
              // Header with stats
              SliverToBoxAdapter(
                child: _buildHeader(provider),
              ),

              // Active Routines
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '활성 루틴',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final routine = activeRoutines[index];
                    return RoutineCard(routine: routine);
                  },
                  childCount: activeRoutines.length,
                ),
              ),

              // Paused Routines (접을 수 있는 섹션)
              if (pausedRoutines.isNotEmpty)
                SliverToBoxAdapter(
                  child: ExpansionTile(
                    title: Text('일시정지된 루틴 (${pausedRoutines.length})'),
                    children: pausedRoutines
                        .map((routine) => RoutineCard(routine: routine, isPaused: true))
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoutineForm(context),
        icon: Icon(Icons.add),
        label: Text('루틴 추가'),
      ),
    );
  }

  Widget _buildHeader(RoutineProvider provider) {
    // 최고 Streak 계산
    final maxStreak = provider.routines.fold<int>(
      0,
      (max, r) => r.streak > max ? r.streak : max,
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 연속 $maxStreak일 달성 중!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '이번 주 완료율: 87%',  // TODO: 실제 계산 필요
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showRoutineForm(BuildContext context, {Routine? routine}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineFormScreen(routine: routine),
      ),
    );
  }
}
```

### 3-3. RoutineCard (routine_card.dart)

```dart
import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import 'package:provider/provider.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool isPaused;

  const RoutineCard({
    required this.routine,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildCategoryIcon(),
        title: Text(
          routine.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPaused ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            _buildFrequencyChips(),
            SizedBox(height: 4),
            Text(
              '${routine.time} • ${routine.duration ?? 0}분',
              style: TextStyle(fontSize: 12),
            ),
            if (routine.streak > 0)
              Text(
                '🔥 ${routine.streak}일 연속',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Switch(
          value: routine.status == 'Active',
          onChanged: (value) => _toggleRoutine(context, value),
        ),
        onTap: () => _editRoutine(context),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    final icon = routine.category ?? '📋';
    return CircleAvatar(
      child: Text(icon.split(' ')[0]),  // 이모지만 추출
    );
  }

  Widget _buildFrequencyChips() {
    return Wrap(
      spacing: 4,
      children: routine.frequency.map((day) {
        return Chip(
          label: Text(day, style: TextStyle(fontSize: 10)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  void _toggleRoutine(BuildContext context, bool isActive) {
    final provider = context.read<RoutineProvider>();
    provider.updateRoutine(
      routine.id,
      {'루틴 활성화 상태': isActive ? 'Active' : 'Paused'},
    );
  }

  void _editRoutine(BuildContext context) {
    // TODO: RoutineFormScreen으로 이동
  }
}
```

### 3-4. RoutineFormScreen (routine_form_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';

class RoutineFormScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineFormScreen({this.routine});

  @override
  _RoutineFormScreenState createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  
  String _category = '🏠 생활';
  String _priority = 'Medium';
  int _duration = 30;
  List<String> _frequency = ['매일'];

  final List<String> _categories = [
    '🏃 운동', '📚 공부', '🧘 명상', '💼 업무', '🏠 생활'
  ];
  
  final List<String> _frequencies = [
    '매일', '주중', '주말', '월', '화', '수', '목', '금', '토', '일'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name);
    _timeController = TextEditingController(text: widget.routine?.time ?? '08:00');
    
    if (widget.routine != null) {
      _category = widget.routine!.category ?? _category;
      _priority = widget.routine!.priority ?? _priority;
      _duration = widget.routine!.duration ?? _duration;
      _frequency = widget.routine!.frequency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine == null ? '루틴 추가' : '루틴 수정'),
        actions: [
          if (widget.routine != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteRoutine,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '루틴 이름'),
              validator: (value) => value?.isEmpty ?? true ? '이름을 입력하세요' : null,
            ),
            SizedBox(height: 16),
            
            // Category 선택
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(labelText: '카테고리'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            SizedBox(height: 16),

            // Time 선택
            TextFormField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: '수행 시간 (HH:MM)',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () => _selectTime(),
              readOnly: true,
            ),
            SizedBox(height: 16),

            // Duration
            Row(
              children: [
                Text('예상 소요 시간: '),
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$_duration분',
                    onChanged: (value) => setState(() => _duration = value.toInt()),
                  ),
                ),
                Text('$_duration분'),
              ],
            ),
            SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: InputDecoration(labelText: '우선순위'),
              items: ['High', 'Medium', 'Low'].map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            SizedBox(height: 16),

            // Frequency 선택
            Text('반복 주기', style: TextStyle(fontSize: 16)),
            Wrap(
              spacing: 8,
              children: _frequencies.map((day) {
                final isSelected = _frequency.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _frequency.add(day);
                      } else {
                        _frequency.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveRoutine,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('저장', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반복 주기를 선택하세요')),
      );
      return;
    }

    final provider = context.read<RoutineProvider>();
    final properties = {
      '이름': _nameController.text,
      'Category': _category,
      '루틴 수행 시간': _timeController.text,
      'Duration': _duration,
      'Priority': _priority,
      '반복 주기': jsonEncode(_frequency),
      '루틴 활성화 상태': 'Active',
      'Streak': 0,
    };

    try {
      if (widget.routine == null) {
        await provider.createRoutine(properties);
      } else {
        await provider.updateRoutine(widget.routine!.id, properties);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('루틴이 저장되었습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  void _deleteRoutine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('루틴 삭제'),
        content: Text('이 루틴을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<RoutineProvider>();
      await provider.archiveRoutine(widget.routine!.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('루틴이 삭제되었습니다')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
```

---

## 🔧 4단계: NotionService 확장 (notion_service.dart)

### Routine 관련 메서드 추가

```dart
class NotionService {
  // 기존 코드...

  /// Routines DB 조회
  Future<List<Map<String, dynamic>>> queryRoutines({
    Map<String, dynamic>? filter,
    List<Map<String, dynamic>>? sorts,
  }) async {
    return await queryDatabase(
      databaseId: RoutineProvider.DATA_SOURCE_ID,
      filter: filter,
      sorts: sorts,
    );
  }

  /// 루틴으로 Task 생성
  Future<void> createTaskFromRoutine({
    required String routineName,
    required String date,
    String? category,
    int? duration,
    String? priority,
  }) async {
    await createPages(
      dataSourceId: 'YOUR_TASKS_DATA_SOURCE_ID',  // Tasks DB ID
      pages: [
        {
          '이름': '🔄 $routineName',
          'Status': 'Not started',
          'date:Date:start': date,
          'date:Date:is_datetime': 0,
          'Category': category,
          'Duration': duration,
          'Priority': priority,
          'Is Routine': true,  // Checkbox 필드
        }
      ],
    );
  }

  /// 루틴 Streak 계산을 위한 완료된 Task 조회
  Future<List<Map<String, dynamic>>> getCompletedRoutineTasks({
    required String routineId,
    required DateTime startDate,
  }) async {
    return await queryDatabase(
      databaseId: 'YOUR_TASKS_DATA_SOURCE_ID',
      filter: {
        'and': [
          {'property': 'Routine ID', 'relation': {'contains': routineId}},
          {'property': 'Status', 'select': {'equals': 'Done'}},
          {
            'property': 'Date',
            'date': {'on_or_after': startDate.toIso8601String().split('T')[0]}
          },
        ]
      },
      sorts: [{'property': 'Date', 'direction': 'descending'}],
    );
  }
}
```

---

## 🔧 5단계: main.dart 수정

### RoutineProvider 등록

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/routine_provider.dart';
import 'services/notion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notionService = NotionService();
  final routineProvider = RoutineProvider(notionService);
  
  // 앱 시작 시 루틴 초기화 (Task 자동 생성)
  await routineProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemProvider(notionService)),
        ChangeNotifierProvider(create: (_) => DailyPlanProvider(notionService)),
        ChangeNotifierProvider(create: (_) => ReviewProvider(notionService)),
        ChangeNotifierProvider(create: (_) => PDSDiaryProvider(notionService)),
        ChangeNotifierProvider.value(value: routineProvider),  // 신규 추가
        ChangeNotifierProvider(create: (_) => AIProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## 🔧 6단계: HomeScreen 통합 (home_screen.dart)

### Today 탭에 루틴 섹션 추가

```dart
Widget _buildTodayPage() {
  return Consumer2<ItemProvider, RoutineProvider>(
    builder: (context, itemProvider, routineProvider, child) {
      final todayItems = itemProvider.getTodayItems();
      final todayRoutines = _getTodayRoutines(routineProvider);

      return CustomScrollView(
        slivers: [
          // Morning Briefing
          SliverToBoxAdapter(
            child: _buildMorningBriefing(todayRoutines.length),
          ),

          // Today's Routines 섹션
          if (todayRoutines.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.repeat, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '오늘의 루틴',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${_getCompletedCount(todayRoutines)}/${todayRoutines.length}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildRoutineProgress(todayRoutines),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final routine = todayRoutines[index];
                  return _buildRoutineItem(routine);
                },
                childCount: todayRoutines.length,
              ),
            ),
            SliverToBoxAdapter(child: Divider(height: 32)),
          ],

          // Other Tasks
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '기타 할 일',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = todayItems[index];
                return ItemCard(item: item);
              },
              childCount: todayItems.length,
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildMorningBriefing(int routineCount) {
  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.orange.shade300, Colors.orange.shade500],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '좋은 아침이에요! ☀️',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '오늘의 루틴 ${routineCount}개가 준비되었어요',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    ),
  );
}

Widget _buildRoutineProgress(List<Routine> routines) {
  final completed = _getCompletedCount(routines);
  final total = routines.length;
  final progress = total > 0 ? completed / total : 0.0;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% 완료',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  );
}

Widget _buildRoutineItem(Routine routine) {
  return Dismissible(
    key: Key(routine.id),
    background: Container(
      color: Colors.green,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 20),
      child: Icon(Icons.check, color: Colors.white),
    ),
    secondaryBackground: Container(
      color: Colors.orange,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20),
      child: Icon(Icons.skip_next, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd) {
        // 완료 처리
        await _completeRoutine(routine);
        return true;
      } else {
        // 건너뛰기
        await _skipRoutine(routine);
        return true;
      }
    },
    child: Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(routine.category?.split(' ')[0] ?? '📋'),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '루틴',
                style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
              ),
            ),
            SizedBox(width: 8),
            Expanded(child: Text(routine.name)),
          ],
        ),
        subtitle: Text('${routine.time} • ${routine.duration ?? 0}분'),
        trailing: routine.streak > 0
            ? Text('🔥 ${routine.streak}', style: TextStyle(color: Colors.orange))
            : null,
      ),
    ),
  );
}

List<Routine> _getTodayRoutines(RoutineProvider provider) {
  final now = DateTime.now();
  final dayOfWeek = _getDayOfWeek(now);
  
  return provider.activeRoutines.where((routine) {
    return _isFrequencyMatch(routine.frequency, dayOfWeek);
  }).toList();
}

String _getDayOfWeek(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return weekdays[date.weekday - 1];
}

bool _isFrequencyMatch(List<String> frequency, String dayOfWeek) {
  if (frequency.contains('매일')) return true;
  if (frequency.contains('주중') && ['월', '화', '수', '목', '금'].contains(dayOfWeek)) {
    return true;
  }
  if (frequency.contains('주말') && ['토', '일'].contains(dayOfWeek)) {
    return true;
  }
  return frequency.contains(dayOfWeek);
}

int _getCompletedCount(List<Routine> routines) {
  // TODO: Tasks DB에서 오늘 완료된 루틴 Task 개수 조회
  return 0;
}

Future<void> _completeRoutine(Routine routine) async {
  // TODO: Tasks DB에서 해당 루틴 Task를 'Done'으로 변경
  // TODO: Streak 업데이트
}

Future<void> _skipRoutine(Routine routine) async {
  // TODO: 오늘 루틴을 건너뛰기 처리 (선택적)
}
```

---

## 🗃️ 7단계: Tasks Database 수정 필요

### Tasks DB에 추가해야 할 필드

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `Is Routine` | Checkbox | 루틴에서 생성된 Task인지 표시 |
| `Routine ID` | Relation | Routines DB와 연결 (선택적) |

### Notion에서 수동으로 추가하거나 API로 추가:

```dart
// Tasks DB 업데이트 예시 (필요 시)
await notionService.updateDatabase(
  databaseId: 'YOUR_TASKS_DB_ID',
  properties: {
    'Is Routine': {
      'type': 'checkbox',
      'checkbox': {},
    },
    'Routine ID': {
      'type': 'relation',
      'relation': {
        'database_id': RoutineProvider.ROUTINES_DB_ID,
      },
    },
  },
);
```

---

## 🚀 구현 우선순위 및 체크리스트

### Phase 1: 기본 기능 (필수)
- [ ] `Routine` 모델 생성
- [ ] `RoutineProvider` 구현
  - [ ] `loadRoutines()` - 루틴 목록 로드
  - [ ] `createRoutine()` - 루틴 생성
  - [ ] `updateRoutine()` - 루틴 수정
  - [ ] `archiveRoutine()` - 루틴 삭제
- [ ] `NotionService`에 Routine 메서드 추가
- [ ] `main.dart`에 Provider 등록
- [ ] `PlanScreen`에 루틴 탭 추가
- [ ] `RoutineManagementScreen` 기본 UI
- [ ] `RoutineFormScreen` 생성/수정 폼
- [ ] `RoutineCard` 위젯

### Phase 2: 자동 Task 생성 (핵심)
- [ ] `generateTodayTasks()` 구현
  - [ ] 요일 매칭 로직
  - [ ] 중복 생성 방지 로직
  - [ ] Last Generated Date 업데이트
- [ ] Tasks DB에 `Is Routine`, `Routine ID` 필드 추가
- [ ] `createTaskFromRoutine()` 메서드
- [ ] 앱 시작 시 자동 실행 (`main.dart`)

### Phase 3: HomeScreen 통합
- [ ] Today 탭에 루틴 섹션 추가
- [ ] 루틴 진행률 표시
- [ ] 스와이프 제스처 (완료/건너뛰기)
- [ ] Morning Briefing 헤더

### Phase 4: Streak 기능 (고급)
- [ ] `calculateStreaks()` 구현
  - [ ] Tasks DB에서 완료 기록 조회
  - [ ] 연속 일수 계산 알고리즘
- [ ] `onRoutineCompleted()` 호출
- [ ] UI에 Streak 표시

### Phase 5: 추가 기능 (선택)
- [ ] 루틴 템플릿 시스템
- [ ] 시간대별 그룹핑 (아침/오후/저녁)
- [ ] 주간 리포트 생성
- [ ] 푸시 알림 (루틴 시간 10분 전)
- [ ] PDS PLAN 자동 연동 (시간 블록 생성)

---

## 🐛 주의사항 및 디버깅 팁

### 1. **날짜 처리**
```dart
// ❌ 잘못된 방법
final today = DateTime.now();  // 시간 포함

// ✅ 올바른 방법
final today = DateTime(now.year, now.month, now.day);  // 날짜만
```

### 2. **JSON 파싱**
```dart
// 반복 주기는 JSON 문자열로 저장됨
final frequency = jsonDecode(routine['반복 주기']);  // ["매일", "월"]
```

### 3. **Date 필드 업데이트**
```dart
// Notion Date 필드는 expanded property 사용
{
  'date:Last Generated Date:start': '2025-10-17',
  'date:Last Generated Date:is_datetime': 0,  // 0 = 날짜만, 1 = 날짜+시간
}
```

### 4. **Provider 초기화**
```dart
// ❌ initState에서 직접 호출
@override
void initState() {
  context.read<RoutineProvider>().loadRoutines();  // 에러 발생
}

// ✅ addPostFrameCallback 사용
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<RoutineProvider>().loadRoutines();
  });
}
```

### 5. **중복 생성 방지**
- `Last Generated Date`와 오늘 날짜를 **날짜만** 비교 (시간 제외)
- Tasks DB 조회로 이중 체크 권장

---

## 📚 참고 자료

### Notion API 문서
- Database Query: `https://developers.notion.com/reference/post-database-query`
- Create Pages: `https://developers.notion.com/reference/post-page`
- Update Page: `https://developers.notion.com/reference/patch-page`
- Date Property: `https://developers.notion.com/reference/property-value-object#date`

### Flutter 패키지
- `provider: ^6.0.0` - 상태 관리
- `intl: ^0.18.0` - 날짜 포맷팅
- `shared_preferences: ^2.0.0` - 로컬 캐시 (선택)

---

## 🎯 최종 체크리스트

개발 완료 전 확인사항:

- [ ] Routines DB에서 모든 필드 정상 조회
- [ ] 루틴 생성/수정/삭제 동작 확인
- [ ] 앱 재시작 시 오늘의 루틴이 Tasks로 자동 생성
- [ ] 중복 생성되지 않음 (같은 날 여러 번 실행 테스트)
- [ ] 요일별 반복 주기 정상 동작 (월, 화, 주중, 매일 등)
- [ ] HomeScreen Today 탭에 루틴 표시
- [ ] 루틴 완료 시 Streak 업데이트 (Phase 4)
- [ ] 에러 처리 및 로딩 상태 표시
- [ ] 사용자 피드백 (SnackBar, Dialog)

---

## 💡 개발 팁

1. **단계별 구현**: Phase 1 → 2 → 3 순서로 진행
2. **테스트 루틴 생성**: 샘플 데이터 5개는 이미 생성됨
3. **로그 활용**: `print()` 또는 `debugPrint()`로 디버깅
4. **에러 처리**: 모든 API 호출에 try-catch 적용
5. **UI 개선**: Phase 1 완료 후 디자인 개선 가능

---

## 📞 문제 해결

막히는 부분이 있다면:
1. 에러 메시지 전체 복사
2. 관련 코드 스니펫
3. 어떤 기능 구현 중인지 설명

이상입니다! 🚀 화이팅!