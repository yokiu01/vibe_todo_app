import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/location_notification_service.dart';
import '../services/wifi_info_service.dart';

class LocationDemoScreen extends StatefulWidget {
  const LocationDemoScreen({Key? key}) : super(key: key);

  @override
  State<LocationDemoScreen> createState() => _LocationDemoScreenState();
}

class _LocationDemoScreenState extends State<LocationDemoScreen> {
  final _locationService = LocationService();
  final _locationNotificationService = LocationNotificationService();
  
  List<Location> _locations = [];
  Location? _currentLocation;
  Map<String, dynamic>? _currentWifiInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _locationService.initialize();
    _locationService.onLocationChanged = (location) {
      setState(() {
        _currentLocation = location;
      });
    };
    
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = _locationService.savedLocations;
      final currentLocation = _locationService.currentLocation;
      final wifiInfo = await WifiInfoService.getWifiInfo();
      
      setState(() {
        _locations = locations;
        _currentLocation = currentLocation;
        _currentWifiInfo = wifiInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('데이터 로드 실패: $e', isError: true);
    }
  }

  Future<void> _refreshWifiInfo() async {
    try {
      final wifiInfo = await WifiInfoService.getWifiInfo();
      setState(() {
        _currentWifiInfo = wifiInfo;
      });
      
      if (wifiInfo != null && wifiInfo['isConnected'] == true) {
        final ssid = wifiInfo['ssid'] as String?;
        if (ssid != null) {
          // WiFi 정보를 SharedPreferences에 저장
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_wifi_ssid', ssid);
          await prefs.setString('current_wifi_bssid', wifiInfo['bssid'] as String? ?? '');
          
          // 위치 서비스에 현재 WiFi 정보 설정
          await _locationService.setCurrentWifiSSID(ssid, bssid: wifiInfo['bssid'] as String?);
        }
      }
      
      _showSnackBar('WiFi 정보가 업데이트되었습니다.');
    } catch (e) {
      _showSnackBar('WiFi 정보 업데이트 실패: $e', isError: true);
    }
  }

  Future<void> _testLocationNotification(Location location) async {
    try {
      await _locationNotificationService.testLocationNotification(location);
      _showSnackBar('${location.name} 위치에 대한 테스트 알림이 전송되었습니다.');
    } catch (e) {
      _showSnackBar('테스트 알림 전송 실패: $e', isError: true);
    }
  }

  Future<void> _simulateLocationChange(Location location) async {
    try {
      await _locationService.setCurrentWifiSSID(location.wifiSSID, bssid: location.wifiBSSID);
      _showSnackBar('${location.name} 위치로 시뮬레이션되었습니다.');
    } catch (e) {
      _showSnackBar('위치 시뮬레이션 실패: $e', isError: true);
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
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 기반 알림 데모'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentWifiCard(),
                  const SizedBox(height: 16),
                  _buildCurrentLocationCard(),
                  const SizedBox(height: 16),
                  _buildLocationsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentWifiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '현재 WiFi 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshWifiInfo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentWifiInfo != null) ...[
              Text('SSID: ${_currentWifiInfo!['ssid'] ?? 'N/A'}'),
              Text('BSSID: ${_currentWifiInfo!['bssid'] ?? 'N/A'}'),
              Text('연결 상태: ${_currentWifiInfo!['isConnected'] == true ? '연결됨' : '연결 안됨'}'),
              if (_currentWifiInfo!['rssi'] != null)
                Text('신호 강도: ${_currentWifiInfo!['rssi']} dBm'),
            ] else
              const Text('WiFi 정보를 가져올 수 없습니다.'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return Card(
      color: _currentLocation != null ? Colors.green[50] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentLocation != null ? Icons.location_on : Icons.location_off,
                  color: _currentLocation != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '현재 위치',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentLocation != null) ...[
              Text(
                _currentLocation!.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('WiFi: ${_currentLocation!.wifiSSID}'),
              if (_currentLocation!.wifiBSSID != null)
                Text('BSSID: ${_currentLocation!.wifiBSSID}'),
            ] else
              const Text('현재 위치가 감지되지 않았습니다.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '등록된 위치들',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_locations.isEmpty)
              const Text('등록된 위치가 없습니다.')
            else
              ..._locations.map((location) => _buildLocationTile(location)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(Location location) {
    final isCurrentLocation = _currentLocation?.id == location.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentLocation ? Colors.green[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentLocation ? Colors.green : Colors.blue,
          child: Icon(
            isCurrentLocation ? Icons.location_on : Icons.location_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          location.name,
          style: TextStyle(
            fontWeight: isCurrentLocation ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WiFi: ${location.wifiSSID}'),
            if (location.wifiBSSID != null)
              Text('BSSID: ${location.wifiBSSID}'),
            if (isCurrentLocation)
              const Text(
                '현재 위치',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _simulateLocationChange(location),
              tooltip: '위치 시뮬레이션',
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => _testLocationNotification(location),
              tooltip: '알림 테스트',
            ),
          ],
        ),
      ),
    );
  }
}
