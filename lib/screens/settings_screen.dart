import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/theme_config.dart';
import '../services/lock_screen_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lockScreenEnabled = false;
  bool _lockScreenEditEnabled = false;
  Map<String, dynamic>? _databaseStatus;
  bool _isLoadingDatabaseStatus = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkDatabaseStatus();
  }

  Future<void> _loadSettings() async {
    final lockScreenEnabled = await LockScreenService.isLockScreenEnabled();
    final lockScreenEditEnabled = await LockScreenService.isLockScreenEditEnabled();
    setState(() {
      _lockScreenEnabled = lockScreenEnabled;
      _lockScreenEditEnabled = lockScreenEditEnabled;
    });
  }

  Future<void> _checkDatabaseStatus() async {
    setState(() {
      _isLoadingDatabaseStatus = true;
    });
    
    try {
      final status = await DatabaseService().getDatabaseStatus();
      setState(() {
        _databaseStatus = status;
        _isLoadingDatabaseStatus = false;
      });
    } catch (e) {
      setState(() {
        _databaseStatus = {
          'isConnected': false,
          'error': e.toString(),
        };
        _isLoadingDatabaseStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 테마 설정
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '테마 설정',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // 다크 모드 토글
                      SwitchListTile(
                        title: const Text('다크 모드'),
                        subtitle: const Text('어두운 테마로 전환'),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                      const Divider(),
                      // 테마 선택
                      Text(
                        '테마 색상',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...AppTheme.values.map((theme) {
                        final config = ThemeConfig.getTheme(theme);
                        return RadioListTile<AppTheme>(
                          title: Text(config.displayName),
                          subtitle: Text(config.description),
                          value: theme,
                          groupValue: themeProvider.currentTheme,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setTheme(value);
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 잠금화면 설정
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '잠금화면 설정',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('잠금화면에서 Plan & Do 보기'),
                        subtitle: const Text('잠금화면에서 오늘의 계획과 진행 중인 작업을 확인할 수 있습니다'),
                        value: _lockScreenEnabled,
                        onChanged: (value) async {
                          setState(() {
                            _lockScreenEnabled = value;
                          });
                          await LockScreenService.setLockScreenEnabled(value);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('잠금화면에서 Do 수정하기'),
                        subtitle: const Text('잠금화면에서 직접 작업 상태를 변경할 수 있습니다'),
                        value: _lockScreenEditEnabled,
                        onChanged: _lockScreenEnabled ? (value) async {
                          setState(() {
                            _lockScreenEditEnabled = value;
                          });
                          await LockScreenService.setLockScreenEditEnabled(value);
                        } : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 데이터베이스 상태
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '데이터베이스 상태',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: _isLoadingDatabaseStatus 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            onPressed: _isLoadingDatabaseStatus ? null : _checkDatabaseStatus,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_databaseStatus != null) ...[
                        _buildStatusItem(
                          '연결 상태',
                          _databaseStatus!['isConnected'] ? '정상' : '오류',
                          _databaseStatus!['isConnected'] ? Colors.green : Colors.red,
                        ),
                        if (_databaseStatus!['isConnected']) ...[
                          _buildStatusItem(
                            '테이블 존재',
                            _databaseStatus!['tablesExist'] ? '정상' : '오류',
                            _databaseStatus!['tablesExist'] ? Colors.green : Colors.red,
                          ),
                          _buildStatusItem(
                            '작업 수',
                            '${_databaseStatus!['taskCount']}개',
                            Colors.blue,
                          ),
                          _buildStatusItem(
                            '설정 수',
                            '${_databaseStatus!['settingCount']}개',
                            Colors.blue,
                          ),
                        ],
                        if (_databaseStatus!['error'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '오류: ${_databaseStatus!['error']}',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ] else ...[
                        const Text('데이터베이스 상태를 확인하는 중...'),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _checkDatabaseStatus,
                              icon: const Icon(Icons.refresh),
                              label: const Text('새로고침'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('데이터베이스 초기화'),
                                    content: const Text('모든 데이터가 삭제됩니다. 계속하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  await DatabaseService().resetDatabase();
                                  _checkDatabaseStatus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('데이터베이스가 초기화되었습니다')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('초기화'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 앱 정보
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '앱 정보',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('버전'),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('개발자'),
                        subtitle: const Text('Plan·Do Team'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
