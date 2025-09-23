package com.example.vibe_todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class ScreenOnReceiver : BroadcastReceiver() {
    var methodChannel: MethodChannel? = null

    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("ScreenOnReceiver", "Received intent: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_SCREEN_ON -> {
                Log.d("ScreenOnReceiver", "Screen turned ON - Checking lock screen preference")

                // 잠금화면 설정 확인 (SharedPreferences에서)
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val isLockScreenEnabled = prefs.getBoolean("flutter.lock_screen_enabled", false)

                Log.d("ScreenOnReceiver", "Lock screen enabled: $isLockScreenEnabled")

                if (isLockScreenEnabled) {
                    Log.d("ScreenOnReceiver", "Starting LockScreenActivity")
                    try {
                        val lockIntent = Intent(context, LockScreenActivity::class.java)
                        lockIntent.addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_NO_HISTORY
                        )
                        context.startActivity(lockIntent)
                        Log.d("ScreenOnReceiver", "LockScreenActivity started successfully")
                    } catch (e: Exception) {
                        Log.e("ScreenOnReceiver", "Error starting LockScreenActivity: $e")
                        e.printStackTrace()
                    }
                } else {
                    Log.d("ScreenOnReceiver", "Lock screen disabled - not starting LockScreenActivity")
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
