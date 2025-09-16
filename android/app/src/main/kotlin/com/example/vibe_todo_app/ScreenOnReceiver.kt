package com.example.vibe_todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.ActivityManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager.RunningAppProcessInfo

class ScreenOnReceiver : BroadcastReceiver() {
    var methodChannel: MethodChannel? = null

    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("ScreenOnReceiver", "Received intent: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                Log.d("ScreenOnReceiver", "Screen turned ON")

                // 직접 LockScreenActivity 시작 (백그라운드에서도 작동)
                try {
                    LockScreenActivity.start(context)
                    Log.d("ScreenOnReceiver", "LockScreenActivity started")
                } catch (e: Exception) {
                    Log.e("ScreenOnReceiver", "Error starting LockScreenActivity: $e")
                }

                // 기존 MethodChannel 방식도 유지 (앱이 포그라운드일 때)
                val channel = methodChannel ?: Companion.methodChannel
                if (channel != null) {
                    Log.d("ScreenOnReceiver", "Calling Flutter method for screen on")
                    try {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            channel.invokeMethod("onScreenOn", null)
                            Log.d("ScreenOnReceiver", "Flutter method called successfully")
                        }
                    } catch (e: Exception) {
                        Log.e("ScreenOnReceiver", "Error calling Flutter method: $e")
                    }
                }
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d("ScreenOnReceiver", "User unlocked screen")

                val channel = methodChannel ?: Companion.methodChannel
                if (channel != null) {
                    Log.d("ScreenOnReceiver", "Calling Flutter method for user present")

                    try {
                        // Handler를 사용해서 메인 스레드에서 호출
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            channel.invokeMethod("onScreenOn", null)
                            Log.d("ScreenOnReceiver", "Flutter method called successfully for user present")
                        }
                    } catch (e: Exception) {
                        Log.e("ScreenOnReceiver", "Error calling Flutter method for user present: $e")
                    }
                } else {
                    Log.d("ScreenOnReceiver", "MethodChannel null for user present, skipping")
                }
            }
            Intent.ACTION_SCREEN_OFF -> {
                Log.d("ScreenOnReceiver", "Screen turned OFF")
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d("ScreenOnReceiver", "Boot completed")
            }
            else -> {
                Log.d("ScreenOnReceiver", "Unknown action: ${intent.action}")
            }
        }
    }
}
