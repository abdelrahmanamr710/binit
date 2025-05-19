package com.sams.binit.binit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.ktx.auth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class DatabaseListenerService : Service() {
    private val TAG = "DatabaseListenerService"
    private val database = Firebase.database
    private val handler = Handler(Looper.getMainLooper())
    private val lastLevels = ConcurrentHashMap<String, String>()
    private val executor = Executors.newSingleThreadScheduledExecutor()
    private var wakeLock: PowerManager.WakeLock? = null
    private val registeredBinListeners = HashMap<String, ValueEventListener>()
    
    // SharedPreferences keys for cached credentials
    private val SHARED_PREFS_NAME = "FlutterSharedPreferences"
    private val USER_ID_KEY = "flutter.cached_user_id"
    private val USER_TYPE_KEY = "flutter.cached_user_type"
    private val REGISTERED_BINS_KEY = "flutter.cached_registered_bins"
    private val CACHE_VALID_KEY = "flutter.cached_timestamp"
    private val THIRTY_DAYS_IN_MILLIS = 30 * 24 * 60 * 60 * 1000L

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate called")
        startForeground()
        acquireWakeLock()
        setupBinMonitoring()
        
        // Schedule a periodic restart of the service to ensure it stays alive
        executor.scheduleAtFixedRate({
            Log.d(TAG, "Periodic service refresh")
            refreshService()
        }, 15, 15, TimeUnit.MINUTES)
    }

    private fun refreshService() {
        // Re-setup monitoring to ensure database connections are fresh
        setupBinMonitoring()
        
        // Refresh the foreground notification to keep the service alive
        startForeground()
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Binit:DatabaseListenerWakeLock"
        ).apply {
            acquire(30*60*1000L) // 30 minutes
        }
    }

    private fun startForeground() {
        createNotificationChannels()

        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, "database_service_channel")
            .setContentTitle("Bin Level Monitor")
            .setContentText("Monitoring bin levels in background")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    }

    private fun createNotificationChannels() {
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
                enableLights(true)
                enableVibration(true)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(serviceChannel)
            notificationManager.createNotificationChannel(notificationChannel)
        }
    }

    private fun setupBinMonitoring() {
        // Clean up existing listeners first
        for ((_, listener) in registeredBinListeners) {
            try {
                database.reference.removeEventListener(listener)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing listener: ${e.message}")
            }
        }
        registeredBinListeners.clear()
        
        // Get current user
        val user = Firebase.auth.currentUser
        if (user == null) {
            Log.d(TAG, "No user logged in, checking cached credentials")
            
            // Try to use cached credentials
            if (isCacheValid()) {
                setupBinMonitoringWithCachedCredentials()
            } else {
                Log.d(TAG, "No valid cached credentials, will retry later")
                // Don't stop the service, just try again later
                executor.schedule({
                    setupBinMonitoring()
                }, 5, TimeUnit.MINUTES)
            }
            return
        }
        
        Log.d(TAG, "Setting up bin monitoring for user: ${user.uid}")
        
        // Monitor user-specific bins
        val userBinsRef = database.getReference("users/${user.uid}/registeredBins")
        userBinsRef.addListenerForSingleValueEvent(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                if (snapshot.exists()) {
                    Log.d(TAG, "Found ${snapshot.childrenCount} registered bins")
                    for (binSnapshot in snapshot.children) {
                        val binId = binSnapshot.key ?: continue
                        // Use the correct path format: /BIN/$binId/plastic/level
                        setupBinLevelListener(binId, "BIN/$binId", "plastic")
                        setupBinLevelListener(binId, "BIN/$binId", "metal")
                    }
                } else {
                    Log.d(TAG, "No registered bins found for user ${user.uid}")
                }
            }

            override fun onCancelled(error: DatabaseError) {
                Log.e(TAG, "Database error: ${error.message}")
            }
        })

        // Schedule periodic refresh of bin monitoring
        executor.scheduleAtFixedRate({
            Log.d(TAG, "Refreshing bin monitoring")
            // Remove all existing listeners
            for ((_, listener) in registeredBinListeners) {
                database.reference.removeEventListener(listener)
            }
            registeredBinListeners.clear()
            
            // Re-setup monitoring
            setupBinMonitoring()
        }, 30, 30, TimeUnit.MINUTES)
    }
    
    private fun setupBinMonitoringWithCachedCredentials() {
        try {
            val sharedPrefs = getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
            val userType = sharedPrefs.getString(USER_TYPE_KEY, null)
            
            // Only bin owners have registered bins
            if (userType != "binOwner") {
                Log.d(TAG, "Cached user is not a bin owner, skipping bin monitoring")
                return
            }
            
            // Get registered bins from shared preferences
            val registeredBinsJson = sharedPrefs.getString(REGISTERED_BINS_KEY, "[]")
            val registeredBinsArray = JSONObject(registeredBinsJson).getJSONArray("value")
            
            Log.d(TAG, "Setting up monitoring for ${registeredBinsArray.length()} cached bins")
            
            for (i in 0 until registeredBinsArray.length()) {
                val binId = registeredBinsArray.getString(i)
                setupBinLevelListener(binId, "BIN/$binId", "plastic")
                setupBinLevelListener(binId, "BIN/$binId", "metal")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up bin monitoring with cached credentials: ${e.message}")
        }
    }
    
    private fun isCacheValid(): Boolean {
        val sharedPrefs = getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
        val timestampStr = sharedPrefs.getString(CACHE_VALID_KEY, null) ?: return false
        
        try {
            val timestamp = timestampStr.toLong()
            val now = System.currentTimeMillis()
            
            // Cache is valid for 30 days
            return (now - timestamp) < THIRTY_DAYS_IN_MILLIS
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing cache timestamp: ${e.message}")
            return false
        }
    }

    private fun setupBinLevelListener(binId: String, binPath: String, material: String) {
        // Correct path format: /BIN/$binId/plastic/level or /BIN/$binId/metal/level
        val levelRef = database.getReference("$binPath/$material/level")
        Log.d(TAG, "Setting up listener for path: $binPath/$material/level")
        
        val listener = levelRef.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                val level = snapshot.value?.toString()
                val key = "$binId-$material"
                
                Log.d(TAG, "Received level update for $binId-$material: $level")
                
                if (level != null && level != lastLevels[key]) {
                    showBinLevelNotification(binId, material, level)
                    lastLevels[key] = level
                }
            }

            override fun onCancelled(error: DatabaseError) {
                Log.e(TAG, "Database error for $binId-$material: ${error.message}")
            }
        })
        
        // Store listener for later cleanup
        registeredBinListeners["$binId-$material"] = listener
    }

    private fun showBinLevelNotification(binId: String, material: String, level: String) {
        val sharedPrefs = getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
        
        // Create a unique notification ID
        val notificationId = "bin_${binId}_${material.toLowerCase()}_${level.replace("%", "")}"
        
        // Get the list of sent notifications
        val sentNotifications = sharedPrefs.getStringSet("flutter.sent_notifications", setOf()) ?: setOf()
        
        // Check if this notification was already sent
        if (sentNotifications.contains(notificationId)) {
            Log.d(TAG, "Notification already sent: $notificationId")
            return
        }
        
        // Check if we're within the cooldown period
        val lastNotificationTime = sharedPrefs.getLong("flutter.last_notification_time", 0)
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastNotificationTime < 5000) { // 5 seconds cooldown
            Log.d(TAG, "Notification skipped: Within cooldown period")
            return
        }
        
        // Create notification data
        val notificationData = mapOf(
            "type" to "bin_level_update",
            "binName" to "Bin $binId",
            "material" to material,
            "level" to level,
            "binId" to binId
        )
        
        // Send notification through Flutter's notification service
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_type", "bin_level_update")
            putExtra("notification_data", JSONObject(notificationData).toString())
        }
        startActivity(intent)
        
        // Mark this notification as sent
        val updatedSentNotifications = sentNotifications.toMutableSet()
        updatedSentNotifications.add(notificationId)
        if (updatedSentNotifications.size > 100) {
            // Keep only the last 100 notifications
            val toRemove = updatedSentNotifications.size - 100
            updatedSentNotifications.take(toRemove).forEach { updatedSentNotifications.remove(it) }
        }
        sharedPrefs.edit()
            .putStringSet("flutter.sent_notifications", updatedSentNotifications)
            .putLong("flutter.last_notification_time", currentTime)
            .apply()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand called")
        // If service gets killed, restart it
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy called")
        
        // Clean up listeners
        for ((_, listener) in registeredBinListeners) {
            database.reference.removeEventListener(listener)
        }
        registeredBinListeners.clear()
        
        // Release wake lock
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        
        // Shut down executor
        executor.shutdownNow()
        
        // Restart the service if it was destroyed
        val restartIntent = Intent(applicationContext, DatabaseListenerService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartIntent)
        } else {
            applicationContext.startService(restartIntent)
        }
    }
}