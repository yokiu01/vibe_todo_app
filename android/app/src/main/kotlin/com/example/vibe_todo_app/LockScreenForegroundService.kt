package com.example.vibe_todo_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import android.app.AlarmManager
import android.os.SystemClock

class LockScreenForegroundService : Service() {
    private var screenOnReceiver: ScreenOnReceiver? = null
    private val CHANNEL_ID = "LockScreenServiceChannel"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        setupScreenReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("LockScreenForegroundService", "onStartCommand called, flags: $flags, startId: $startId")

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // 재등록 확인
        if (screenOnReceiver == null) {
            setupScreenReceiver()
        }

        Log.d("LockScreenForegroundService", "Service started with START_STICKY")
        return START_STICKY // 서비스가 종료되어도 자동 재시작
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Lock Screen Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Second Brain 잠금화면 서비스"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Second Brain")
            .setContentText("잠금화면 서비스 실행 중")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun setupScreenReceiver() {
        screenOnReceiver = ScreenOnReceiver()
        
        val intentFilter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_BOOT_COMPLETED)
            priority = 1000
        }

        try {
            registerReceiver(screenOnReceiver, intentFilter)
            Log.d("LockScreenForegroundService", "Screen receiver registered")
        } catch (e: Exception) {
            Log.e("LockScreenForegroundService", "Error registering screen receiver: $e")
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d("LockScreenForegroundService", "Task removed - Restarting service")

        // 서비스 재시작
        val restartServiceIntent = Intent(applicationContext, LockScreenForegroundService::class.java)
        val pendingIntent = PendingIntent.getService(
            applicationContext,
            1,
            restartServiceIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        alarmManager.set(
            android.app.AlarmManager.ELAPSED_REALTIME,
            android.os.SystemClock.elapsedRealtime() + 1000,
            pendingIntent
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("LockScreenForegroundService", "Service destroyed")

        try {
            screenOnReceiver?.let {
                unregisterReceiver(it)
                Log.d("LockScreenForegroundService", "Screen receiver unregistered")
            }
        } catch (e: Exception) {
            Log.e("LockScreenForegroundService", "Error unregistering screen receiver: $e")
        }

        // 서비스 재시작
        try {
            val restartServiceIntent = Intent(applicationContext, LockScreenForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(restartServiceIntent)
            } else {
                applicationContext.startService(restartServiceIntent)
            }
            Log.d("LockScreenForegroundService", "Service restart scheduled")
        } catch (e: Exception) {
            Log.e("LockScreenForegroundService", "Error restarting service: $e")
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        fun startService(context: Context) {
            val intent = Intent(context, LockScreenForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, LockScreenForegroundService::class.java)
            context.stopService(intent)
        }
    }
}













