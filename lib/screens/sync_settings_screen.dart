import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/calendar_sync_service.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _isGoogleCalendarEnabled = false;
  bool _isNotionEnabled = false;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동기화 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 구글 캘린더 동기화
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '구글 캘린더',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text('구글 캘린더의 일정을 자동으로 가져옵니다'),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isGoogleCalendarEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isGoogleCalendarEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isGoogleCalendarEnabled) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncGoogleCalendar,
                      icon: _isSyncing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? '동기화 중...' : '지금 동기화'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 노션 동기화
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '노션',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text('노션 데이터베이스의 작업을 가져옵니다'),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isNotionEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isNotionEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isNotionEnabled) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncNotion,
                      icon: _isSyncing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? '동기화 중...' : '지금 동기화'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 동기화 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '동기화 정보',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 외부 서비스에서 가져온 일정은 자동으로 분류됩니다\n'
                    '• 동기화된 일정은 수정할 수 없습니다\n'
                    '• 최신 일정을 보려면 수동으로 동기화하세요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncGoogleCalendar() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 7));

      final tasks = await CalendarSyncService.syncGoogleCalendar(startDate, endDate);
      
      // 가져온 작업들을 데이터베이스에 저장
      for (final task in tasks) {
        await context.read<TaskProvider>().addTask(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tasks.length}개의 일정을 가져왔습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동기화 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _syncNotion() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final tasks = await CalendarSyncService.syncNotionDatabase();
      
      for (final task in tasks) {
        await context.read<TaskProvider>().addTask(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tasks.length}개의 작업을 가져왔습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동기화 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
}

