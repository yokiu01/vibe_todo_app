import 'package:flutter/material.dart';
import '../services/notion_api_service.dart';
import '../services/lock_screen_service.dart';
import '../services/location_notification_service.dart';
import '../services/time_notification_service.dart';
import '../models/location.dart';
import 'location_list_screen.dart';
import 'location_demo_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotionApiService _notionService = NotionApiService();
  final LocationNotificationService _locationNotificationService = LocationNotificationService();
  final TimeNotificationService _timeNotificationService = TimeNotificationService();
  bool _lockScreenEnabled = false;
  bool _hasOverlayPermission = false;
  bool _isLoading = false;
  String? _currentApiKey;
  bool _timeNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeLocationNotificationService();
    _initializeTimeNotificationService();
  }

  Future<void> _initializeLocationNotificationService() async {
    try {
      await _locationNotificationService.initialize();
    } catch (e) {
      print('위치 알림 서비스 초기화 오류: $e');
    }
  }

  Future<void> _initializeTimeNotificationService() async {
    try {
      await _timeNotificationService.initialize();
      setState(() {
        _timeNotificationEnabled = _timeNotificationService.isEnabled;
      });
    } catch (e) {
      print('시간 알림 서비스 초기화 오류: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lockScreenEnabled = await LockScreenService.isLockScreenEnabled();
      final hasOverlayPermission = await LockScreenService.hasOverlayPermission();
      final apiKey = await _notionService.getApiKey();

      setState(() {
        _lockScreenEnabled = lockScreenEnabled;
        _hasOverlayPermission = hasOverlayPermission;
        _currentApiKey = apiKey;
      });
    } catch (e) {
      _showSnackBar('설정 로드 실패: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLockScreen(bool value) async {
    if (value && !_hasOverlayPermission) {
      // 권한이 없으면 권한 요청
      await _requestOverlayPermission();
      return;
    }

    try {
      await LockScreenService.setLockScreenEnabled(value);
      setState(() {
        _lockScreenEnabled = value;
      });
      _showSnackBar(
        value ? '잠금화면 오버레이가 활성화되었습니다.' : '잠금화면 오버레이가 비활성화되었습니다.',
      );
    } catch (e) {
      _showSnackBar('설정 변경 실패: $e', isError: true);
    }
  }

  Future<void> _requestOverlayPermission() async {
    final bool? shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '오버레이 권한 필요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),
        content: const Text(
          '잠금화면에 앱 내용을 표시하려면 "다른 앱 위에 그리기" 권한이 필요합니다.\n\n'
          '설정으로 이동하여 권한을 허용해주세요.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF3C2A21),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await LockScreenService.requestOverlayPermission();
      // 권한 요청 후 잠시 기다렸다가 다시 확인
      Future.delayed(const Duration(seconds: 1), () async {
        final hasPermission = await LockScreenService.hasOverlayPermission();
        setState(() {
          _hasOverlayPermission = hasPermission;
        });
        if (hasPermission) {
          _toggleLockScreen(true);
        }
      });
    }
  }

  Future<void> _testOverlay() async {
    try {
      print('Settings: Testing lock screen overlay');
      // 이제 Android 잠금화면 위에만 표시되므로 테스트 불가
      _showSnackBar('잠금화면은 화면을 껐다 켤 때 Android 잠금화면 위에 표시됩니다.');
    } catch (e) {
      print('Settings: Lock screen test failed: $e');
      _showSnackBar('잠금화면 테스트 실패: $e', isError: true);
    }
  }

  Future<void> _testScreenOnEvent() async {
    try {
      print('Settings: Testing screen on event manually');
      // 수동으로 screen on 이벤트 시뮬레이션
      await LockScreenService.showOverlayManually();
      _showSnackBar('Screen on 이벤트 테스트가 실행되었습니다.');
    } catch (e) {
      print('Settings: Screen on event test failed: $e');
      _showSnackBar('Screen on 이벤트 테스트 실패: $e', isError: true);
    }
  }

  Future<void> _showApiKeyDialog() async {
    final TextEditingController controller = TextEditingController();
    if (_currentApiKey != null) {
      controller.text = _currentApiKey!;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.key,
                color: Color(0xFF8B7355),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notion API 키 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notion API 키를 입력하세요:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C2A21),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDD4C0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDD4C0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B7355), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '• Notion 설정 > 연결 > API에서 토큰을 생성하세요.\n• "secret_"로 시작하는 키를 입력하세요.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B7355),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = controller.text.trim();
              if (apiKey.isNotEmpty) {
                try {
                  await _notionService.setApiKey(apiKey);
                  setState(() {
                    _currentApiKey = apiKey;
                  });
                  Navigator.of(context).pop();
                  _showSnackBar('API 키가 저장되었습니다.');
                } catch (e) {
                  _showSnackBar('API 키 저장 실패: $e', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '로그아웃',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),
        content: const Text(
          'Notion API 키를 삭제하고 로그아웃하시겠습니까?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF3C2A21),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notionService.clearApiKey();
        setState(() {
          _currentApiKey = null;
        });
        _showSnackBar('로그아웃되었습니다.');
      } catch (e) {
        _showSnackBar('로그아웃 실패: $e', isError: true);
      }
    }
  }

  Future<void> _toggleTimeNotification(bool value) async {
    try {
      await _timeNotificationService.setEnabled(value);
      setState(() {
        _timeNotificationEnabled = value;
      });
      _showSnackBar(
        value ? '시간 기반 알림이 활성화되었습니다.' : '시간 기반 알림이 비활성화되었습니다.',
      );
    } catch (e) {
      _showSnackBar('시간 알림 설정 변경 실패: $e', isError: true);
    }
  }

  Future<void> _testTimeNotification() async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:00';
      await _timeNotificationService.testTimeNotification(
        currentTime, 
        '테스트 계획: ${currentTime}에 할 일입니다.'
      );
      _showSnackBar('시간 기반 테스트 알림이 전송되었습니다.');
    } catch (e) {
      _showSnackBar('테스트 알림 전송 실패: $e', isError: true);
    }
  }

  Future<void> _testLocationNotification() async {
    try {
      // 테스트용 더미 위치 생성
      final testLocation = Location(
        id: 'test-location',
        name: '테스트 위치',
        wifiSSID: 'test-wifi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _locationNotificationService.testLocationNotification(testLocation);
      _showSnackBar('테스트 알림이 전송되었습니다.');
    } catch (e) {
      _showSnackBar('테스트 알림 전송 실패: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF8B7355),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text(
          '⚙️ 설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C2A21),
          ),
        ),
        backgroundColor: const Color(0xFFFDF6E3),
        foregroundColor: const Color(0xFF3C2A21),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: Color(0xFF8B7355),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '설정을 불러오는 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: '🔗 Notion 연동',
                    children: [
                      _buildSettingTile(
                        icon: Icons.key,
                        title: 'API 키 관리',
                        subtitle: _currentApiKey != null
                            ? 'API 키가 설정되어 있습니다'
                            : 'API 키를 설정해주세요',
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _showApiKeyDialog,
                        ),
                        onTap: _showApiKeyDialog,
                      ),
                      if (_currentApiKey != null) ...[
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.logout,
                          title: '로그아웃',
                          subtitle: 'API 키를 삭제하고 로그아웃',
                          iconColor: Colors.red,
                          onTap: _logout,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '🔒 잠금화면 설정',
                    children: [
                      _buildSettingTile(
                        icon: Icons.lock_open,
                        title: '잠금화면 오버레이',
                        subtitle: _hasOverlayPermission
                            ? '화면 켜짐 시 PDS Do-See 내용 표시'
                            : '오버레이 권한이 필요합니다',
                        trailing: Switch(
                          value: _lockScreenEnabled && _hasOverlayPermission,
                          onChanged: _toggleLockScreen,
                          activeColor: const Color(0xFF8B7355),
                          activeTrackColor: const Color(0xFFD4A574),
                          inactiveThumbColor: const Color(0xFF9C8B73),
                          inactiveTrackColor: const Color(0xFFDDD4C0),
                        ),
                        onTap: () => _toggleLockScreen(!_lockScreenEnabled),
                      ),
                      if (!_hasOverlayPermission) ...[
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.security,
                          title: '오버레이 권한 요청',
                          subtitle: '다른 앱 위에 그리기 권한 설정',
                          iconColor: Colors.orange,
                          onTap: _requestOverlayPermission,
                        ),
                      ],
                      if (_hasOverlayPermission && _lockScreenEnabled) ...[
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.play_arrow,
                          title: '오버레이 테스트',
                          subtitle: '잠금화면 오버레이 미리보기',
                          iconColor: Colors.green,
                          onTap: _testOverlay,
                        ),
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.screen_lock_portrait,
                          title: 'Screen On 이벤트 테스트',
                          subtitle: '화면 켜짐 이벤트 수동 시뮬레이션',
                          iconColor: Colors.blue,
                          onTap: _testScreenOnEvent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '⏰ 시간 기반 알림',
                    children: [
                      _buildSettingTile(
                        icon: Icons.schedule,
                        title: 'PDS 계획 알림',
                        subtitle: _timeNotificationEnabled
                            ? '계획된 시간에 알림을 받습니다'
                            : '계획된 시간에 알림을 받지 않습니다',
                        trailing: Switch(
                          value: _timeNotificationEnabled,
                          onChanged: _toggleTimeNotification,
                          activeColor: const Color(0xFF8B7355),
                          activeTrackColor: const Color(0xFFD4A574),
                          inactiveThumbColor: const Color(0xFF9C8B73),
                          inactiveTrackColor: const Color(0xFFDDD4C0),
                        ),
                        onTap: () => _toggleTimeNotification(!_timeNotificationEnabled),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        icon: Icons.notifications_active,
                        title: '시간 알림 테스트',
                        subtitle: '현재 시간으로 테스트 알림 전송',
                        iconColor: Colors.orange,
                        onTap: _testTimeNotification,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '📍 위치 기반 알림',
                    children: [
                      _buildSettingTile(
                        icon: Icons.location_on,
                        title: '위치 관리',
                        subtitle: 'WiFi 기반 위치 등록 및 관리',
                        onTap: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => const LocationListScreen(),
                            ),
                          );
                          if (result == true) {
                            _showSnackBar('위치 설정이 업데이트되었습니다.');
                          }
                        },
                      ),
                      const Divider(),
                      _buildSettingTile(
                        icon: Icons.notifications_active,
                        title: '알림 테스트',
                        subtitle: '위치 기반 알림 기능 테스트',
                        iconColor: Colors.orange,
                        onTap: _testLocationNotification,
                      ),
                      const Divider(),
                      _buildSettingTile(
                        icon: Icons.science,
                        title: '위치 데모',
                        subtitle: '위치 감지 및 알림 시스템 테스트',
                        iconColor: Colors.purple,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LocationDemoScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '🔧 앱 정보',
                    children: [
                      _buildSettingTile(
                        icon: Icons.info,
                        title: '버전 정보',
                        subtitle: 'Plan·Do v1.0.0',
                        onTap: () => _showAboutDialog(),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        icon: Icons.description,
                        title: '사용법 안내',
                        subtitle: 'PDS 방법론 및 앱 사용법',
                        onTap: () => _showHelpDialog(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD4C0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B7355).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B7355).withOpacity(0.1),
                  const Color(0xFFD4A574).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF8B7355),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C2A21),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDDD4C0).withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (iconColor ?? const Color(0xFF8B7355)).withOpacity(0.1),
                (iconColor ?? const Color(0xFF8B7355)).withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (iconColor ?? const Color(0xFF8B7355)).withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF8B7355),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3C2A21),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8B7355),
            height: 1.3,
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right,
          color: const Color(0xFF8B7355).withOpacity(0.7),
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF8B7355),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Second Brain 앱 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '버전: 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B7355),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Second Brain은 똑똑한 할일관리를 위한 생산성 앱입니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3C2A21),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '주요 기능:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C2A21),
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Notion과 연동하여 할일 관리'),
            const Text('• 시간 기반 알림으로 계획 실행'),
            const Text('• 위치 기반 스마트 알림'),
            const Text('• 잠금화면에서 계획 확인'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              '확인',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFF8B7355),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '사용법 안내',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(
                '1. Notion 연동',
                'API 키를 설정하여 Notion과 연동하고 할일, 프로젝트 등을 동기화합니다.',
                Icons.link,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '2. 계획 (Plan)',
                '시간별로 할 일을 계획하고 날짜 선택으로 다른 날 계획을 확인합니다.',
                Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '3. 실행 (Do-See)',
                '실제로 한 일을 기록하고 하루 회고를 작성합니다.',
                Icons.check_circle,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '4. 잠금화면 오버레이',
                '앱 재시작 시 오늘의 계획과 실행 내용을 표시합니다.',
                Icons.lock,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              '확인',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B7355).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDDD4C0).withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B7355),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C2A21),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B7355),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}