import 'package:flutter/services.dart';

class LockScreenModeService {
  static const MethodChannel _channel = MethodChannel('lock_screen_mode');
  static bool? _isLockScreenMode;
  static bool _isInitialized = false;

  // 락 스크린 모드인지 확인 - 더 강력한 감지 로직
  static Future<bool> isLockScreenMode() async {
    // 이미 초기화되었고 캐시된 값이 있으면 반환
    if (_isInitialized && _isLockScreenMode != null) {
      return _isLockScreenMode!;
    }

    try {
      // Android에서 잠금화면 모드 확인
      final result = await _channel.invokeMethod('isLockScreenMode');
      _isLockScreenMode = result == true;
      _isInitialized = true;
      
      print('LockScreenModeService: isLockScreenMode = $_isLockScreenMode');
      return _isLockScreenMode!;
    } catch (e) {
      print('LockScreenModeService: Error checking lock screen mode: $e');
      
      // 에러 발생 시 현재 라우트로 판단
      try {
        final currentRoute = await _getCurrentRoute();
        final isLockScreenRoute = currentRoute == '/lockScreenStandalone';
        _isLockScreenMode = isLockScreenRoute;
        _isInitialized = true;
        
        print('LockScreenModeService: Fallback to route check: $currentRoute -> $_isLockScreenMode');
        return _isLockScreenMode!;
      } catch (routeError) {
        print('LockScreenModeService: Route check also failed: $routeError');
        _isLockScreenMode = false;
        _isInitialized = true;
        return false;
      }
    }
  }

  // 화면이 잠겨있는지 확인
  static Future<bool> isScreenLocked() async {
    try {
      final result = await _channel.invokeMethod('isScreenLocked');
      return result == true;
    } catch (e) {
      print('LockScreenModeService: Error checking screen lock status: $e');
      return false;
    }
  }

  // 현재 라우트 확인 (백업 방법)
  static Future<String?> _getCurrentRoute() async {
    try {
      final result = await _channel.invokeMethod('getCurrentRoute');
      return result as String?;
    } catch (e) {
      print('LockScreenModeService: Error getting current route: $e');
      return null;
    }
  }

  // 락 스크린 모드 강제 설정 (테스트용)
  static void setLockScreenMode(bool isLockScreen) {
    _isLockScreenMode = isLockScreen;
    _isInitialized = true;
    print('LockScreenModeService: Lock screen mode set to $isLockScreen');
  }

  // 캐시 초기화 (앱 재시작 시)
  static void reset() {
    _isLockScreenMode = null;
    _isInitialized = false;
    print('LockScreenModeService: Cache reset');
  }
}


