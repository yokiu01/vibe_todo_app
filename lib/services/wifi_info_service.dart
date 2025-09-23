import 'dart:async';
import 'package:flutter/services.dart';

class WifiInfoService {
  static const MethodChannel _channel = MethodChannel('wifi_info');

  /// WiFi 정보 가져오기
  static Future<Map<String, dynamic>?> getWifiInfo() async {
    try {
      final result = await _channel.invokeMethod('getWifiInfo');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } on PlatformException catch (e) {
      print('WiFi 정보 가져오기 오류: ${e.message}');
      return null;
    }
  }

  /// WiFi 연결 상태 확인
  static Future<bool> isWifiConnected() async {
    try {
      final result = await _channel.invokeMethod('isWifiConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      print('WiFi 연결 상태 확인 오류: ${e.message}');
      return false;
    }
  }

  /// 현재 WiFi SSID 가져오기
  static Future<String?> getCurrentWifiSSID() async {
    try {
      final wifiInfo = await getWifiInfo();
      if (wifiInfo != null && wifiInfo['isConnected'] == true) {
        return wifiInfo['ssid'] as String?;
      }
      return null;
    } catch (e) {
      print('WiFi SSID 가져오기 오류: $e');
      return null;
    }
  }

  /// 현재 WiFi BSSID 가져오기
  static Future<String?> getCurrentWifiBSSID() async {
    try {
      final wifiInfo = await getWifiInfo();
      if (wifiInfo != null && wifiInfo['isConnected'] == true) {
        return wifiInfo['bssid'] as String?;
      }
      return null;
    } catch (e) {
      print('WiFi BSSID 가져오기 오류: $e');
      return null;
    }
  }
}






