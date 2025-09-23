import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pds_plan.dart';
import '../services/database_service.dart';

class TimeNotificationService {
  static final TimeNotificationService _instance = TimeNotificationService._internal();
  factory TimeNotificationService() => _instance;
  TimeNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();
  
  Timer? _timeCheckTimer;
  bool _isInitialized = false;
  bool _isEnabled = false;
  
  static const String _enabledKey = 'time_notification_enabled';
  static const String _notificationChannelId = 'time_notifications';
  static const String _notificationChannelName = '시간 기반 알림';

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _requestNotificationPermission();
    await _initializeNotifications();
    await _loadSettings();
    await _startTimeMonitoring();
    
    _isInitialized = true;
  }

  /// 알림 권한 요청
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      print('시간 알림 권한이 거부되었습니다.');
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

    // 알림 채널 생성 (Android)
    const androidChannel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: '계획된 시간에 할일 알림을 받습니다.',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? false;
  }

  /// 설정 저장
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, _isEnabled);
  }

  /// 시간 모니터링 시작
  Future<void> _startTimeMonitoring() async {
    // 매 분마다 시간을 체크
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isEnabled) {
        _checkForScheduledTasks();
      }
    });
  }

  /// 알림 활성화/비활성화
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
    
    if (enabled) {
      // 즉시 다음 계획된 일정 확인
      _checkForScheduledTasks();
    } else {
      // 모든 예정된 알림 취소
      await _notifications.cancelAll();
    }
  }

  /// 알림 활성화 상태 확인
  bool get isEnabled => _isEnabled;

  /// 예정된 일정 확인
  Future<void> _checkForScheduledTasks() async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:00';
      
      // 오늘의 PDS 계획 가져오기
      final today = DateTime(now.year, now.month, now.day);
      final pdsPlan = await _getPDSPlanForDate(today);
      
      if (pdsPlan != null && pdsPlan.freeformPlans != null) {
        final planForCurrentTime = pdsPlan.freeformPlans![currentTime];
        
        if (planForCurrentTime != null && planForCurrentTime.isNotEmpty) {
          // 이미 이 시간에 알림을 보냈는지 확인
          final lastNotificationTime = await _getLastNotificationTime();
          if (lastNotificationTime != currentTime) {
            await _showTimeNotification(currentTime, planForCurrentTime);
            await _setLastNotificationTime(currentTime);
          }
        }
      }
    } catch (e) {
      print('시간 기반 알림 확인 오류: $e');
    }
  }

  /// 특정 날짜의 PDS 계획 가져오기
  Future<PDSPlan?> _getPDSPlanForDate(DateTime date) async {
    try {
      // 데이터베이스에서 PDS 계획 조회
      final plans = await _databaseService.getAllPDSPlans();
      final dateStr = date.toIso8601String().split('T')[0];
      
      for (final plan in plans) {
        final planDateStr = plan.date.toIso8601String().split('T')[0];
        if (planDateStr == dateStr) {
          return plan;
        }
      }
      return null;
    } catch (e) {
      print('PDS 계획 조회 오류: $e');
      return null;
    }
  }

  /// 시간 기반 알림 표시
  Future<void> _showTimeNotification(String time, String plan) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        channelDescription: '계획된 시간에 할일 알림을 받습니다.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          plan,
          contentTitle: '$time 계획된 일',
          summaryText: 'PDS 계획 알림',
        ),
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

      // 시간을 기반으로 고유한 ID 생성
      final notificationId = time.hashCode;

      await _notifications.show(
        notificationId,
        '$time 계획된 일',
        plan,
        notificationDetails,
        payload: jsonEncode({
          'type': 'time_notification',
          'time': time,
          'plan': plan,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('시간 알림 표시 오류: $e');
    }
  }

  /// 마지막 알림 시간 저장
  Future<void> _setLastNotificationTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_time_notification', time);
  }

  /// 마지막 알림 시간 가져오기
  Future<String?> _getLastNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_time_notification');
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        final type = data['type'] as String?;
        
        if (type == 'time_notification') {
          final time = data['time'] as String?;
          final plan = data['plan'] as String?;
          
          print('시간 알림 탭됨: $time - $plan');
          
          // TODO: 알림 탭 시 해당 시간의 계획 화면으로 이동
          // Navigator.of(context).pushNamed('/pds-plan', arguments: time);
        }
      }
    } catch (e) {
      print('알림 탭 처리 오류: $e');
    }
  }

  /// 수동으로 시간 알림 테스트
  Future<void> testTimeNotification(String time, String plan) async {
    try {
      await _showTimeNotification(time, plan);
    } catch (e) {
      print('테스트 알림 오류: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 서비스 정리
  void dispose() {
    _timeCheckTimer?.cancel();
  }
}
