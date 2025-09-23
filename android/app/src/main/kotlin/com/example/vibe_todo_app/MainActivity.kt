package com.example.vibe_todo_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import android.app.ActivityManager
import com.example.second_brain.WifiInfoPlugin

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "plan_do_widget"
    private lateinit var screenOnReceiver: ScreenOnReceiver

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // WiFi 정보 플러그인 등록
        flutterEngine.plugins.add(WifiInfoPlugin())

        // 기존 위젯 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    updateWidget()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 락 스크린 모드 채널 (MainActivity용)
        val lockScreenChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lock_screen_mode")
        lockScreenChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isLockScreenMode" -> {
                    result.success(false) // MainActivity는 일반 모드
                }
                "getCurrentRoute" -> {
                    result.success("/main") // MainActivity의 라우트
                }
                "isScreenLocked" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                    result.success(keyguardManager.isKeyguardLocked)
                }
                else -> result.notImplemented()
            }
        }

        // 잠금화면 채널 제거 - 락 스크린은 독립적으로 처리
        // lockScreenMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_SCREEN_CHANNEL)
        
        // ScreenOnReceiver에 MethodChannel 전달하지 않음
        // ScreenOnReceiver.methodChannel = lockScreenMethodChannel
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "=== MainActivity onCreate started ===")

        // finish 플래그가 있으면 MainActivity 종료
        if (intent.getBooleanExtra("finish", false)) {
            Log.d("MainActivity", "Finish flag received - finishing MainActivity")
            finish()
            return
        }

        // 잠금화면이 활성화되어 있고, 현재 잠금화면 위에서 실행되는지 확인
        if (isLockScreenEnabled() && isScreenLocked()) {
            Log.d("MainActivity", "Screen is locked and lock screen is enabled - redirecting to LockScreenActivity")
            redirectToLockScreen()
            return
        } else if (isLockScreenEnabled()) {
            Log.d("MainActivity", "Lock screen is enabled but screen is unlocked - running normal app")
        } else {
            Log.d("MainActivity", "Lock screen is disabled - running normal app")
        }

        // LockScreenActivity와 동시 실행 허용 - MainActivity 종료하지 않음
        Log.d("MainActivity", "MainActivity running alongside LockScreenActivity (if present)")

        // Register ScreenOnReceiver dynamically for SCREEN_ON/OFF events
        setupLockScreenReceiver()
        Log.d("MainActivity", "MainActivity setup completed")
    }

    private fun isLockScreenActivityRunning(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningTasks = am.getRunningTasks(10)

        for (task in runningTasks) {
            if (task.topActivity?.className == "com.example.vibe_todo_app.LockScreenActivity") {
                Log.d("MainActivity", "LockScreenActivity found in running tasks")
                return true
            }
        }
        Log.d("MainActivity", "LockScreenActivity not found in running tasks")
        return false
    }

    override fun onResume() {
        super.onResume()
        Log.d("MainActivity", "App resumed")
    }
    

    override fun onPause() {
        super.onPause()
        Log.d("MainActivity", "App paused")
        // Foreground Service 비활성화 - 락 스크린과 충돌 방지
        // startForegroundService()
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister ScreenOnReceiver
        try {
            unregisterReceiver(screenOnReceiver)
            Log.d("MainActivity", "ScreenOnReceiver unregistered")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error unregistering ScreenOnReceiver: $e")
        }
        Log.d("MainActivity", "MainActivity destroyed")
    }


    private fun updateWidget() {
        // 위젯 업데이트 로직은 PlanDoWidgetProvider에서 처리
        // 여기서는 단순히 위젯 업데이트를 트리거
    }

    private fun isLockScreenEnabled(): Boolean {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.lock_screen_enabled", false)
            Log.d("MainActivity", "Lock screen enabled: $isEnabled")
            return isEnabled
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking lock screen setting: $e")
            return false
        }
    }

    private fun isScreenLocked(): Boolean {
        try {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            val isLocked = keyguardManager.isKeyguardLocked
            Log.d("MainActivity", "Screen locked: $isLocked")
            return isLocked
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking screen lock status: $e")
            return false
        }
    }

    private fun redirectToLockScreen() {
        try {
            val lockIntent = Intent(this, LockScreenActivity::class.java)
            lockIntent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            startActivity(lockIntent)
            Log.d("MainActivity", "Redirected to LockScreenActivity")
            
            // MainActivity 종료
            finish()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error redirecting to LockScreenActivity: $e")
            e.printStackTrace()
        }
    }

    private fun setupLockScreenReceiver() {
        try {
            screenOnReceiver = ScreenOnReceiver()
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                // SCREEN_OFF는 제거 - 필요하지 않음
            }
            registerReceiver(screenOnReceiver, filter)
            Log.d("MainActivity", "ScreenOnReceiver registered successfully")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error registering ScreenOnReceiver: $e")
            e.printStackTrace()
        }
    }
}
