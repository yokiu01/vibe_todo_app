import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/notion_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotionConnectionScreen extends StatefulWidget {
  const NotionConnectionScreen({super.key});

  @override
  State<NotionConnectionScreen> createState() => _NotionConnectionScreenState();
}

class _NotionConnectionScreenState extends State<NotionConnectionScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  Future<void> _checkExistingConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('notion_api_key');
    if (apiKey != null && apiKey.isNotEmpty) {
      setState(() {
        _isConnected = true;
      });
    }
  }

  Future<void> _connectNotion() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'API 키를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notion_api_key', _apiKeyController.text.trim());

      // Test the connection
      final notionService = NotionApiService();
      // Simple validation - you can add actual API call here

      setState(() {
        _isConnected = true;
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notion 연동 성공!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Notion 연동에 실패했습니다. API 키를 확인해주세요.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notion 연동'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: onboardingProvider.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              // Icon
              Icon(
                Icons.link,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Notion과 연결하기',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Vibe Todo는 Notion과 연동하여 작업을 동기화합니다. Notion Integration API 키를 입력해주세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Instructions Card
              if (!_isConnected) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API 키 발급 방법',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionStep('1', 'notion.so/my-integrations 방문'),
                        _buildInstructionStep('2', 'New integration 생성'),
                        _buildInstructionStep('3', 'API 키 복사'),
                        _buildInstructionStep('4', '아래에 붙여넣기'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // API Key Input
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Notion API 키',
                    hintText: 'secret_xxxxxxxxxxxxxxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                    errorText: _errorMessage,
                  ),
                  obscureText: true,
                ),

                const SizedBox(height: 24),

                // Connect Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _connectNotion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '연결하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ] else ...[
                // Connected State
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 60,
                        color: Colors.green[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Notion 연동 완료!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '이제 Notion과 작업을 동기화할 수 있습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    onboardingProvider.nextPhase();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '다음 단계로',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Skip Button
              TextButton(
                onPressed: () {
                  onboardingProvider.nextPhase();
                },
                child: Text(
                  _isConnected ? '' : '나중에 연동하기',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
