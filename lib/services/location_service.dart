import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/location.dart';
import 'wifi_info_service.dart';

class LocationService {
  static const String _locationsKey = 'saved_locations';
  static const String _currentLocationKey = 'current_location';
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  String? _currentWifiSSID;
  Location? _currentLocation;
  
  // 현재 위치 변경 콜백
  Function(Location?)? onLocationChanged;
  
  /// 위치 서비스 초기화
  Future<void> initialize() async {
    await _requestPermissions();
    await _loadSavedLocations();
    await _startWifiMonitoring();
  }
  
  /// 권한 요청
  Future<void> _requestPermissions() async {
    // Android에서 위치 권한 요청
    if (Platform.isAndroid) {
      await Permission.location.request();
    }
    
    // WiFi 상태 확인 권한
    await Permission.nearbyWifiDevices.request();
  }
  
  /// 저장된 위치들 로드
  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList(_locationsKey) ?? [];
    
    _savedLocations = locationsJson
        .map((json) => Location.fromMap(jsonDecode(json)))
        .toList();
  }
  
  /// 위치들 저장
  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = _savedLocations
        .map((location) => jsonEncode(location.toMap()))
        .toList();
    
    await prefs.setStringList(_locationsKey, locationsJson);
  }
  
  List<Location> _savedLocations = [];
  
  /// 저장된 위치들 가져오기
  List<Location> get savedLocations => List.unmodifiable(_savedLocations);
  
  /// 현재 위치 가져오기
  Location? get currentLocation => _currentLocation;
  
  /// WiFi 모니터링 시작
  Future<void> _startWifiMonitoring() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        if (result == ConnectivityResult.wifi) {
          await _checkWifiConnection();
        } else {
          _currentWifiSSID = null;
          _updateCurrentLocation(null);
        }
      },
    );
    
    // 초기 연결 상태 확인
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.wifi) {
      await _checkWifiConnection();
    }
  }
  
  /// WiFi 연결 상태 확인
  Future<void> _checkWifiConnection() async {
    try {
      if (Platform.isAndroid) {
        // Android에서 WiFi 정보 가져오기
        final wifiInfo = await _getAndroidWifiInfo();
        if (wifiInfo != null) {
          _currentWifiSSID = wifiInfo['ssid'];
          await _updateLocationFromWifi(_currentWifiSSID!);
        }
      } else if (Platform.isIOS) {
        // iOS에서 WiFi 정보 가져오기
        final wifiInfo = await _getIOSWifiInfo();
        if (wifiInfo != null) {
          _currentWifiSSID = wifiInfo['ssid'];
          await _updateLocationFromWifi(_currentWifiSSID!);
        }
      }
    } catch (e) {
      print('WiFi 정보 확인 오류: $e');
    }
  }
  
  /// Android WiFi 정보 가져오기
  Future<Map<String, String>?> _getAndroidWifiInfo() async {
    try {
      final wifiInfo = await WifiInfoService.getWifiInfo();
      if (wifiInfo != null && wifiInfo['isConnected'] == true) {
        return {
          'ssid': wifiInfo['ssid'] as String? ?? '',
          'bssid': wifiInfo['bssid'] as String? ?? '',
        };
      }
    } catch (e) {
      print('Android WiFi 정보 가져오기 오류: $e');
    }
    return null;
  }
  
  /// iOS WiFi 정보 가져오기
  Future<Map<String, String>?> _getIOSWifiInfo() async {
    try {
      // iOS에서는 현재 WiFi 정보를 직접 가져올 수 없으므로
      // SharedPreferences에서 저장된 정보를 사용
      final prefs = await SharedPreferences.getInstance();
      final ssid = prefs.getString('current_wifi_ssid');
      final bssid = prefs.getString('current_wifi_bssid');
      
      if (ssid != null) {
        return {'ssid': ssid, 'bssid': bssid ?? ''};
      }
    } catch (e) {
      print('iOS WiFi 정보 가져오기 오류: $e');
    }
    return null;
  }
  
  /// WiFi SSID로 위치 업데이트
  Future<void> _updateLocationFromWifi(String ssid) async {
    final location = _savedLocations.firstWhere(
      (loc) => loc.wifiSSID == ssid,
      orElse: () => Location(
        id: '',
        name: '',
        wifiSSID: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (location.id.isNotEmpty) {
      await _updateCurrentLocation(location);
    } else {
      await _updateCurrentLocation(null);
    }
  }
  
  /// 현재 위치 업데이트
  Future<void> _updateCurrentLocation(Location? location) async {
    if (_currentLocation != location) {
      _currentLocation = location;
      
      // 현재 위치 저장
      final prefs = await SharedPreferences.getInstance();
      if (location != null) {
        await prefs.setString(_currentLocationKey, jsonEncode(location.toMap()));
      } else {
        await prefs.remove(_currentLocationKey);
      }
      
      // 콜백 호출
      onLocationChanged?.call(location);
    }
  }
  
  /// 위치 추가
  Future<void> addLocation(Location location) async {
    _savedLocations.add(location);
    await _saveLocations();
  }
  
  /// 위치 수정
  Future<void> updateLocation(Location location) async {
    final index = _savedLocations.indexWhere((loc) => loc.id == location.id);
    if (index != -1) {
      _savedLocations[index] = location;
      await _saveLocations();
    }
  }
  
  /// 위치 삭제
  Future<void> deleteLocation(String locationId) async {
    _savedLocations.removeWhere((loc) => loc.id == locationId);
    await _saveLocations();
    
    // 현재 위치가 삭제된 위치라면 null로 설정
    if (_currentLocation?.id == locationId) {
      await _updateCurrentLocation(null);
    }
  }
  
  /// 위치 ID로 위치 찾기
  Location? getLocationById(String id) {
    try {
      return _savedLocations.firstWhere((loc) => loc.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// WiFi SSID로 위치 찾기
  Location? getLocationByWifiSSID(String ssid) {
    try {
      return _savedLocations.firstWhere((loc) => loc.wifiSSID == ssid);
    } catch (e) {
      return null;
    }
  }
  
  /// 현재 WiFi SSID 설정 (테스트용)
  Future<void> setCurrentWifiSSID(String ssid, {String? bssid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_wifi_ssid', ssid);
    if (bssid != null) {
      await prefs.setString('current_wifi_bssid', bssid);
    }
    
    _currentWifiSSID = ssid;
    await _updateLocationFromWifi(ssid);
  }
  
  /// 서비스 정리
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
