import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/notion_api_service.dart';

class LocationNotificationService {
  static final LocationNotificationService _instance = LocationNotificationService._internal();
  factory LocationNotificationService() => _instance;
  LocationNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final LocationService _locationService = LocationService();
  final NotionApiService _notionService = NotionApiService();
  
  StreamSubscription<Location?>? _locationSubscription;
  bool _isInitialized = false;
  Location? _lastNotifiedLocation;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _requestNotificationPermission();
    await _initializeNotifications();
    await _startLocationMonitoring();
    
    _isInitialized = true;
  }

  /// 알림 권한 요청
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      print('알림 권한이 거부되었습니다.');
    }
  }

  /// 알림 초기화
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 위치 모니터링 시작
  Future<void> _startLocationMonitoring() async {
    await _locationService.initialize();
    
    _locationService.onLocationChanged = (location) async {
      await _handleLocationChange(location);
    };
  }

  /// 위치 변경 처리
  Future<void> _handleLocationChange(Location? location) async {
    if (location == null) {
      _lastNotifiedLocation = null;
      return;
    }

    // 같은 위치에 대한 중복 알림 방지
    if (_lastNotifiedLocation?.id == location.id) {
      return;
    }

    try {
      // 노션에서 해당 위치의 할일들 조회
      final tasks = await _getTasksForLocation(location);
      
      if (tasks.isNotEmpty) {
        await _showLocationNotification(location, tasks);
        _lastNotifiedLocation = location;
      }
    } catch (e) {
      print('위치 알림 처리 오류: $e');
    }
  }

  /// 특정 위치의 할일들 조회
  Future<List<Map<String, dynamic>>> _getTasksForLocation(Location location) async {
    try {
      // 노션 API 인증 확인
      final isAuthenticated = await _notionService.isAuthenticated();
      if (!isAuthenticated) {
        print('노션 API 인증이 필요합니다.');
        return [];
      }

      // 노션 API의 위치 기반 할일 조회 메서드 사용
      return await _notionService.getTasksForLocation(location.name);
    } catch (e) {
      print('할일 조회 오류: $e');
      return [];
    }
  }

  /// 위치 알림 표시
  Future<void> _showLocationNotification(Location location, List<Map<String, dynamic>> tasks) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'location_notifications',
        '위치 기반 알림',
        channelDescription: '특정 위치에서 할일 알림을 받습니다.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 할일 제목들 추출
      final taskTitles = tasks.map((task) {
        final properties = task['properties'] as Map<String, dynamic>?;
        final nameProperty = properties?['이름'] as Map<String, dynamic>?;
        final titleArray = nameProperty?['title'] as List<dynamic>?;
        return titleArray?.isNotEmpty == true
            ? (titleArray!.first['text']?['content'] as String? ?? '제목 없음')
            : '제목 없음';
      }).toList();

      // 알림 제목과 내용 구성
      final title = '${location.name}에서 할일이 있습니다';
      final body = taskTitles.length == 1
          ? taskTitles.first
          : '${taskTitles.length}개의 할일이 있습니다';

      // 상세 내용이 있는 경우 추가 정보 표시
      String? bigText;
      if (taskTitles.length > 1) {
        bigText = taskTitles.join('\n• ');
        bigText = '• $bigText';
      }

      await _notifications.show(
        location.id.hashCode,
        title,
        body,
        notificationDetails,
        payload: jsonEncode({
          'locationId': location.id,
          'locationName': location.name,
          'taskCount': tasks.length,
        }),
      );

      // 상세 내용이 있는 경우 BigText 스타일 알림도 표시
      if (bigText != null) {
        final bigTextAndroidDetails = AndroidNotificationDetails(
          'location_notifications',
          '위치 기반 알림',
          channelDescription: '특정 위치에서 할일 알림을 받습니다.',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          styleInformation: BigTextStyleInformation(
            bigText,
            contentTitle: title,
            summaryText: '${taskTitles.length}개의 할일',
          ),
        );

        final bigTextNotificationDetails = NotificationDetails(
          android: bigTextAndroidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          location.id.hashCode + 1000, // 다른 ID 사용
          title,
          body,
          bigTextNotificationDetails,
          payload: jsonEncode({
            'locationId': location.id,
            'locationName': location.name,
            'taskCount': tasks.length,
            'tasks': taskTitles,
          }),
        );
      }
    } catch (e) {
      print('알림 표시 오류: $e');
    }
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        final locationId = data['locationId'] as String?;
        final locationName = data['locationName'] as String?;
        
        print('알림 탭됨: $locationName (ID: $locationId)');
        
        // TODO: 알림 탭 시 해당 위치의 할일 목록 화면으로 이동
        // Navigator.of(context).pushNamed('/location-tasks', arguments: locationId);
      }
    } catch (e) {
      print('알림 탭 처리 오류: $e');
    }
  }

  /// 수동으로 위치 알림 테스트
  Future<void> testLocationNotification(Location location) async {
    try {
      final tasks = await _getTasksForLocation(location);
      if (tasks.isNotEmpty) {
        await _showLocationNotification(location, tasks);
      } else {
        // 테스트용 더미 데이터로 알림 표시
        final dummyTasks = [
          {'properties': {'이름': {'title': [{'text': {'content': '테스트 할일 1'}}]}}},
          {'properties': {'이름': {'title': [{'text': {'content': '테스트 할일 2'}}]}}},
        ];
        await _showLocationNotification(location, dummyTasks);
      }
    } catch (e) {
      print('테스트 알림 오류: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 특정 위치의 알림 취소
  Future<void> cancelLocationNotifications(String locationId) async {
    await _notifications.cancel(locationId.hashCode);
    await _notifications.cancel(locationId.hashCode + 1000);
  }

  /// 서비스 정리
  void dispose() {
    _locationSubscription?.cancel();
  }
}
