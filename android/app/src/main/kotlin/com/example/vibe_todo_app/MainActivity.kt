package com.example.vibe_todo_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.app.KeyguardManager
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "plan_do_widget"
    private val LOCK_SCREEN_CHANNEL = "plan_do_lock_screen"
    private var lockScreenMethodChannel: MethodChannel? = null
    private var screenOnReceiver: ScreenOnReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

        // 잠금화면 채널
        lockScreenMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_SCREEN_CHANNEL)
        
        // ScreenOnReceiver에 MethodChannel 전달
        ScreenOnReceiver.methodChannel = lockScreenMethodChannel
        
        lockScreenMethodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateLockScreenWidget" -> {
                    result.success(null)
                }
                "updateTaskStatus" -> {
                    val taskId = call.argument<String>("taskId")
                    val status = call.argument<String>("status")
                    result.success(null)
                }
                "completeTask" -> {
                    val taskId = call.argument<String>("taskId")
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    val hasPermission = Settings.canDrawOverlays(this)
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "showLockScreenOverlay" -> {
                    showLockScreenOverlay()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupLockScreenReceiver()
    }

    override fun onResume() {
        super.onResume()
        Log.d("MainActivity", "App resumed")
    }

    override fun onDestroy() {
        super.onDestroy()
        // Context-registered receiver 해제
        try {
            screenOnReceiver?.let {
                unregisterReceiver(it)
                Log.d("MainActivity", "Screen receiver unregistered")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error unregistering screen receiver: $e")
        }
    }

    private fun setupLockScreenReceiver() {
        // Android 10+ 백그라운드 제한 해결을 위해 Context-registered receiver 사용
        screenOnReceiver = ScreenOnReceiver()
        screenOnReceiver?.methodChannel = lockScreenMethodChannel

        val intentFilter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_SCREEN_OFF)
            priority = 1000
        }

        try {
            registerReceiver(screenOnReceiver, intentFilter)
            Log.d("MainActivity", "Context-registered screen receiver setup completed")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error registering screen receiver: $e")
        }
    }

    private fun requestOverlayPermission() {
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun showLockScreenOverlay() {
        if (Settings.canDrawOverlays(this)) {
            // 잠금화면 위에 표시되도록 설정
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
            lockScreenMethodChannel?.invokeMethod("onScreenOn", null)
        } else {
            Log.w("MainActivity", "Overlay permission not granted")
        }
    }

    private fun updateWidget() {
        // 위젯 업데이트 로직은 PlanDoWidgetProvider에서 처리
        // 여기서는 단순히 위젯 업데이트를 트리거
    }
}
