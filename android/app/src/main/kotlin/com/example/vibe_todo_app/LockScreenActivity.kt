package com.example.vibe_todo_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class LockScreenActivity : FlutterActivity() {

    override fun getInitialRoute(): String {
        return "/lockScreenStandalone"
    }
    private val LOCK_SCREEN_CHANNEL = "plan_do_lock_screen"
    private var lockScreenMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d("LockScreenActivity", "=== LockScreenActivity onCreate started ===")
        Log.d("LockScreenActivity", "Intent action: ${intent.action}")
        Log.d("LockScreenActivity", "Intent flags: ${intent.flags}")

        // 잠금화면 위에 표시되도록 설정
        setShowWhenLocked(true)
        setTurnScreenOn(true)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        // MainActivity와 동시 실행 허용 - 강제 종료하지 않음
        Log.d("LockScreenActivity", "LockScreenActivity running alongside MainActivity (if present)")

        Log.d("LockScreenActivity", "Window flags set for lock screen display")
        Log.d("LockScreenActivity", "Lock screen activity created successfully")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        lockScreenMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_SCREEN_CHANNEL)
        lockScreenMethodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "closeLockScreen" -> {
                    Log.d("LockScreenActivity", "Closing lock screen activity")
                    // 그냥 LockScreen만 종료 (Android 잠금화면으로 돌아감)
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 락 스크린 모드 플래그를 Flutter에 전달
        val lockScreenChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lock_screen_mode")
        lockScreenChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isLockScreenMode" -> {
                    result.success(true) // 락 스크린 모드임을 알림
                }
                "getCurrentRoute" -> {
                    result.success("/lockScreenStandalone") // 현재 라우트 전달
                }
                "isScreenLocked" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                    result.success(keyguardManager.isKeyguardLocked)
                }
                else -> result.notImplemented()
            }
        }

        // 락 스크린 전용 빠른 시작 - 불필요한 초기화 제거
        Log.d("LockScreenActivity", "Lock screen engine configured - fast mode")
    }

    override fun onResume() {
        super.onResume()
        Log.d("LockScreenActivity", "LockScreenActivity resumed")
    }

    override fun onPause() {
        super.onPause()
        Log.d("LockScreenActivity", "LockScreenActivity paused")
    }

    override fun onStop() {
        super.onStop()
        Log.d("LockScreenActivity", "LockScreenActivity stopped")
    }

    override fun onBackPressed() {
        Log.d("LockScreenActivity", "Back button pressed - closing lock screen")
        // 그냥 LockScreen만 종료 (Android 잠금화면으로 돌아감)
        finish()
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