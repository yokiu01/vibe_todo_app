package com.example.vibe_todo_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class LockScreenActivity : FlutterActivity() {

    override fun getInitialRoute(): String {
        return "/lockScreenStandalone"
    }
    private val LOCK_SCREEN_CHANNEL = "plan_do_lock_screen"
    private var lockScreenMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 잠금화면 위에 표시되도록 설정
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        Log.d("LockScreenActivity", "Lock screen activity created")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        lockScreenMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_SCREEN_CHANNEL)
        lockScreenMethodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "closeLockScreen" -> {
                    Log.d("LockScreenActivity", "Closing lock screen activity")
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Lock screen을 자동으로 표시
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            lockScreenMethodChannel?.invokeMethod("showLockScreen", null)
        }, 500)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("LockScreenActivity", "Lock screen activity destroyed")
    }

    companion object {
        fun start(context: Context) {
            val intent = Intent(context, LockScreenActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            context.startActivity(intent)
        }
    }
}