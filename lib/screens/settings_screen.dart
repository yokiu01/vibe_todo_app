import 'package:flutter/material.dart';
import '../services/notion_api_service.dart';
import '../services/lock_screen_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotionApiService _notionService = NotionApiService();
  bool _lockScreenEnabled = false;
  bool _hasOverlayPermission = false;
  bool _isLoading = false;
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
        title: const Text('오버레이 권한 필요'),
        content: const Text(
          '잠금화면에 앱 내용을 표시하려면 "다른 앱 위에 그리기" 권한이 필요합니다.\n\n'
          '설정으로 이동하여 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
      await LockScreenService.showOverlayManually();
      _showSnackBar('오버레이 테스트가 실행되었습니다.');
    } catch (e) {
      _showSnackBar('오버레이 테스트 실패: $e', isError: true);
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
        title: const Text('Notion API 키 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notion API 키를 입력하세요:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Notion 설정 > 연결 > API에서 토큰을 생성하세요.\n• "secret_"로 시작하는 키를 입력하세요.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        title: const Text('로그아웃'),
        content: const Text('Notion API 키를 삭제하고 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          activeColor: const Color(0xFF2563EB),
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
                      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF2563EB)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF2563EB),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.chevron_right,
        color: Color(0xFF64748B),
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan·Do 앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0'),
            SizedBox(height: 8),
            Text('Plan-Do-See 방법론을 기반으로 한 생산성 앱입니다.'),
            SizedBox(height: 8),
            Text('• Plan: 일정 계획'),
            Text('• Do: 실행 기록'),
            Text('• See: 회고 및 반성'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용법 안내'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Notion 연동',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• API 키를 설정하여 Notion과 연동'),
              Text('• 할일, 프로젝트 등을 동기화'),
              SizedBox(height: 12),
              Text(
                '2. 계획 (Plan)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 시간별로 할 일을 계획'),
              Text('• 날짜 선택으로 다른 날 계획 확인'),
              SizedBox(height: 12),
              Text(
                '3. 실행 (Do-See)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 실제로 한 일을 기록'),
              Text('• 하루 회고 작성'),
              SizedBox(height: 12),
              Text(
                '4. 잠금화면 오버레이',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 앱 재시작 시 오늘의 계획과 실행 내용 표시'),
              Text('• 설정에서 활성화/비활성화 가능'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}