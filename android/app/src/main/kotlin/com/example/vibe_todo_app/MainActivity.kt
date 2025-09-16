package com.example.vibe_todo_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import android.app.KeyguardManager
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "plan_do_widget"
    private val LOCK_SCREEN_CHANNEL = "plan_do_lock_screen"
    private var lockScreenReceiver: BroadcastReceiver? = null
    private var lockScreenMethodChannel: MethodChannel? = null

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

    override fun onDestroy() {
        super.onDestroy()
        lockScreenReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e("MainActivity", "Error unregistering receiver", e)
            }
        }
    }

    private fun setupLockScreenReceiver() {
        lockScreenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        Log.d("MainActivity", "Screen turned ON")

                        // 화면이 잠금 상태인지 확인
                        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                        val isLocked = keyguardManager.isKeyguardLocked

                        if (isLocked && Settings.canDrawOverlays(context)) {
                            // 잠금화면 위에 오버레이 표시
                            lockScreenMethodChannel?.invokeMethod("onScreenOn", null)
                        }
                    }
                    Intent.ACTION_USER_PRESENT -> {
                        Log.d("MainActivity", "User unlocked screen")
                        // 사용자가 잠금해제 했을 때 Flutter에 알림
                        lockScreenMethodChannel?.invokeMethod("onUserPresent", null)
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(lockScreenReceiver, filter)
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
