import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/wifi_info_service.dart';

class LocationRegistrationScreen extends StatefulWidget {
  final Location? locationToEdit;

  const LocationRegistrationScreen({Key? key, this.locationToEdit}) : super(key: key);

  @override
  State<LocationRegistrationScreen> createState() => _LocationRegistrationScreenState();
}

class _LocationRegistrationScreenState extends State<LocationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wifiSSIDController = TextEditingController();
  final _wifiBSSIDController = TextEditingController();
  final _locationService = LocationService();
  
  bool _isLoading = false;
  String? _currentWifiSSID;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
    
    if (widget.locationToEdit != null) {
      _nameController.text = widget.locationToEdit!.name;
      _wifiSSIDController.text = widget.locationToEdit!.wifiSSID;
      _wifiBSSIDController.text = widget.locationToEdit!.wifiBSSID ?? '';
    }
  }

  Future<void> _initializeLocationService() async {
    await _locationService.initialize();
    await _getCurrentWifiInfo();
  }

  Future<void> _getCurrentWifiInfo() async {
    try {
      // 실제 WiFi 정보 가져오기
      final wifiInfo = await WifiInfoService.getWifiInfo();
      if (wifiInfo != null && wifiInfo['isConnected'] == true) {
        final ssid = wifiInfo['ssid'] as String?;
        final bssid = wifiInfo['bssid'] as String?;
        
        if (ssid != null) {
          setState(() {
            _currentWifiSSID = ssid;
            if (widget.locationToEdit == null) {
              _wifiSSIDController.text = ssid;
              _wifiBSSIDController.text = bssid ?? '';
            }
          });
        }
      } else {
        // WiFi가 연결되지 않은 경우 SharedPreferences에서 저장된 정보 사용
        final prefs = await SharedPreferences.getInstance();
        final ssid = prefs.getString('current_wifi_ssid');
        final bssid = prefs.getString('current_wifi_bssid');
        
        if (ssid != null) {
          setState(() {
            _currentWifiSSID = ssid;
            if (widget.locationToEdit == null) {
              _wifiSSIDController.text = ssid;
              _wifiBSSIDController.text = bssid ?? '';
            }
          });
        }
      }
    } catch (e) {
      print('현재 WiFi 정보 가져오기 오류: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wifiSSIDController.dispose();
    _wifiBSSIDController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final location = Location(
        id: widget.locationToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        wifiSSID: _wifiSSIDController.text.trim(),
        wifiBSSID: _wifiBSSIDController.text.trim().isEmpty 
            ? null 
            : _wifiBSSIDController.text.trim(),
        createdAt: widget.locationToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.locationToEdit != null) {
        await _locationService.updateLocation(location);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치가 수정되었습니다.')),
        );
      } else {
        await _locationService.addLocation(location);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치가 등록되었습니다.')),
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _useCurrentWifi() async {
    if (_currentWifiSSID != null) {
      setState(() {
        _wifiSSIDController.text = _currentWifiSSID!;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 WiFi 정보를 가져올 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationToEdit != null ? '위치 수정' : '위치 등록'),
        actions: [
          if (widget.locationToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('위치 삭제'),
                    content: const Text('이 위치를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _locationService.deleteLocation(widget.locationToEdit!.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('위치가 삭제되었습니다.')),
                    );
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '위치 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '위치 이름',
                          hintText: '예: 집에서, 사무실, 창원에서',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '위치 이름을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _wifiSSIDController,
                              decoration: const InputDecoration(
                                labelText: 'WiFi SSID',
                                hintText: 'WiFi 네트워크 이름',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'WiFi SSID를 입력해주세요.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _currentWifiSSID != null ? _useCurrentWifi : null,
                            child: const Text('현재 WiFi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _wifiBSSIDController,
                        decoration: const InputDecoration(
                          labelText: 'WiFi BSSID (선택사항)',
                          hintText: 'WiFi MAC 주소',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '알림 설정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '이 위치에 진입하면 다음 조건을 만족하는 할일들이 알림으로 표시됩니다:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 완료되지 않은 할일\n'
                        '• 명료화가 "다음행동"인 할일\n'
                        '• "다음 행동 상황"에 이 위치가 포함된 할일',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.locationToEdit != null ? '수정하기' : '등록하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
