# Flutter 잠금화면 오버레이 화면 켜짐 감지 구현 가이드

## 문제 상황
현재 Flutter 앱에서 화면을 껐다 켤 때 잠금화면 오버레이가 표시되지 않는 문제가 있습니다. 이는 네이티브 Android에서 화면 켜짐 이벤트를 감지하는 구현이 누락되어 있기 때문입니다.

## 구현 개요

### 현재 상태
- Flutter 레벨에서는 `AppLifecycleState.resumed`만 감지 가능
- 앱이 백그라운드에서 포그라운드로 올 때만 작동
- 단순 화면 켜짐은 감지하지 못함

### 해결 방안
- Android BroadcastReceiver로 `ACTION_SCREEN_ON` 이벤트 수신
- MethodChannel을 통해 Flutter에 알림 전송
- 화면이 켜질 때마다 잠금화면 오버레이 표시

## 구현 단계

### 1단계: 패키지명 확인

먼저 앱의 실제 패키지명을 확인하세요:

```gradle
// android/app/build.gradle 파일에서 확인
android {
    defaultConfig {
        applicationId "com.example.your_actual_app_name"  // 이 값을 사용
    }
}
```

### 2단계: BroadcastReceiver 생성

**파일 생성**: `android/app/src/main/kotlin/com/example/yourapp/ScreenOnReceiver.kt`

```kotlin
package com.example.yourapp  // 실제 패키지명으로 변경

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

class ScreenOnReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                methodChannel?.invokeMethod("onScreenOn", null)
            }
        }
    }
}
```

### 3단계: MainActivity 수정

**파일 수정**: `android/app/src/main/kotlin/com/example/yourapp/MainActivity.kt`

```kotlin
package com.example.yourapp  // 실제 패키지명으로 변경

import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.yourapp/lock_screen"  // 실제 패키지명으로 변경
    private lateinit var screenOnReceiver: ScreenOnReceiver

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        ScreenOnReceiver.methodChannel = methodChannel
        
        // BroadcastReceiver 등록
        screenOnReceiver = ScreenOnReceiver()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(screenOnReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(screenOnReceiver)
        } catch (e: Exception) {
            // Receiver가 이미 등록 해제된 경우
        }
    }
}
```

### 4단계: AndroidManifest.xml 수정

**파일 수정**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 권한 추가 -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <application
        android:label="your_app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- BroadcastReceiver 등록 -->
        <receiver android:name=".ScreenOnReceiver" 
                  android:enabled="true" 
                  android:exported="false">
            <intent-filter android:priority="1000">
                <action android:name="android.intent.action.SCREEN_ON" />
            </intent-filter>
        </receiver>
        
        <meta-data
          android:name="flutterEmbedding"
          android:value="2" />
    </application>
</manifest>
```

### 5단계: Flutter LockScreenService 수정

**파일 수정**: `lib/services/lock_screen_service.dart`

```dart
import 'package:flutter/services.dart';

class LockScreenService {
  static const _channel = MethodChannel('com.example.yourapp/lock_screen');  // 실제 패키지명으로 변경
  static VoidCallback? _onScreenOn;

  static Future<void> initialize({VoidCallback? onScreenOn}) async {
    _onScreenOn = onScreenOn;
    
    // 네이티브에서 호출되는 메서드 핸들러 설정
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScreenOn':
          print('Native: Screen turned on!');
          _onScreenOn?.call();
          break;
      }
    });
  }
  
  // 기존 메서드들 유지...
  static Future<bool> isLockScreenEnabled() async {
    // 기존 구현 유지
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('lock_screen_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> setLockScreenEnabled(bool enabled) async {
    // 기존 구현 유지
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lock_screen_enabled', enabled);
    } catch (e) {
      print('Error setting lock screen enabled: $e');
    }
  }
  
  static Future<bool> hasOverlayPermission() async {
    // 기존 구현 유지 - 실제 구현 필요
    return true; // 임시값
  }
  
  static Future<void> requestOverlayPermission() async {
    // 기존 구현 유지 - 실제 구현 필요
  }
  
  static Future<bool> isLockScreenEditEnabled() async {
    // 기존 구현 유지
    return true; // 임시값
  }
}
```

## 빌드 및 테스트

### 빌드 단계
```bash
# 프로젝트 정리
flutter clean

# 패키지 재설치
flutter pub get

# 앱 빌드 및 실행
flutter run
```

### 테스트 방법
1. 앱을 실행합니다
2. 휴대폰 화면을 끕니다 (전원 버튼 누르기)
3. 화면을 다시 켭니다
4. 잠금화면 오버레이가 나타나는지 확인합니다

## 문제 해결

### 일반적인 문제들

#### 1. 패키지명 불일치
**증상**: 빌드 에러 또는 이벤트가 감지되지 않음
**해결**: 모든 파일에서 패키지명이 일치하는지 확인

#### 2. 권한 문제
**증상**: BroadcastReceiver가 작동하지 않음
**해결**: AndroidManifest.xml에 `WAKE_LOCK` 권한이 추가되었는지 확인

#### 3. MethodChannel 이름 불일치
**증상**: Flutter와 네이티브 간 통신 실패
**해결**: MethodChannel 이름이 양쪽에서 동일한지 확인

### 디버깅 방법

#### 로그 확인
```bash
# Android 로그 확인
flutter logs

# 또는 adb 로그 확인
adb logcat | grep -E "(Flutter|ScreenOnReceiver)"
```

#### 테스트 코드 추가
```dart
// main.dart의 _showLockScreenIfNeeded() 메서드에 추가
print('Lock screen check - enabled: $isEnabled, mounted: $mounted, showing: $_isShowingLockScreen');
```

## 추가 개선 사항

### 배터리 최적화 예외 처리
일부 Android 기기에서는 배터리 최적화로 인해 BroadcastReceiver가 제한될 수 있습니다.

### 화면 꺼짐 감지 추가
필요한 경우 `ACTION_SCREEN_OFF` 이벤트도 처리할 수 있습니다:

```kotlin
// ScreenOnReceiver.kt에 추가
override fun onReceive(context: Context, intent: Intent) {
    when (intent.action) {
        Intent.ACTION_SCREEN_ON -> {
            methodChannel?.invokeMethod("onScreenOn", null)
        }
        Intent.ACTION_SCREEN_OFF -> {
            methodChannel?.invokeMethod("onScreenOff", null)
        }
    }
}
```

```xml
<!-- AndroidManifest.xml의 intent-filter에 추가 -->
<action android:name="android.intent.action.SCREEN_OFF" />
```

## 최종 확인사항

- [ ] 패키지명이 모든 파일에서 일치하는가?
- [ ] BroadcastReceiver가 AndroidManifest.xml에 등록되었는가?
- [ ] WAKE_LOCK 권한이 추가되었는가?
- [ ] MethodChannel 이름이 일치하는가?
- [ ] 앱을 완전히 다시 빌드했는가?
- [ ] 실제 기기에서 테스트했는가?

이 가이드를 따라 구현하면 화면을 켤 때마다 잠금화면 오버레이가 표시됩니다.