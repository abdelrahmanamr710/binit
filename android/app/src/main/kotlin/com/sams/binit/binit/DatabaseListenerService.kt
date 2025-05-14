package com.sams.binit.binit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

class DatabaseListenerService : Service() {
    private val database = FirebaseDatabase.getInstance()
    private val handler = Handler(Looper.getMainLooper())
    private var lastLevel: String? = null

    private val databaseChecker = object : Runnable {
        override fun run() {
            checkDatabaseValue()
            handler.postDelayed(this, 1000) // Run every second
        }
    }

    override fun onCreate() {
        super.onCreate()
        startForeground()
        handler.post(databaseChecker)
    }

    private fun startForeground() {
        createNotificationChannel()

        val notification = NotificationCompat.Builder(this, "database_service_channel")
            .setContentTitle("Bin Level Monitor")
            .setContentText("Monitoring bin levels...")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                "database_service_channel",
                "Database Service Channel",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for database monitoring service"
            }

            val notificationChannel = NotificationChannel(
                "high_importance_channel",
                "Bin Level Updates",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for bin level update notifications"
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(serviceChannel)
            notificationManager.createNotificationChannel(notificationChannel)
        }
    }

    private fun checkDatabaseValue() {
        database.getReference("BIN/plastic/level").get().addOnSuccessListener { snapshot ->
            val level = snapshot.value?.toString()
            if (level != null && level != lastLevel) {
                showBinLevelNotification(level)
                lastLevel = level
            }
        }.addOnFailureListener { exception ->
            // Handle error
            println("Error reading database: ${exception.message}")
        }
    }

    private fun showBinLevelNotification(level: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, "high_importance_channel")
            .setContentTitle("Bin Level Update")
            .setContentText("Plastic bin is now $level full.")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(databaseChecker)
    }
}