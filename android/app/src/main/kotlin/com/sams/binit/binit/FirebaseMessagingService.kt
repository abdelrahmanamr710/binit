package com.sams.binit.binit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject

class BinitFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "BinitFCMService"
    private val SHARED_PREFS_NAME = "FlutterSharedPreferences"
    private val USER_TYPE_KEY = "flutter.cached_user_type"
    private val CACHE_VALID_KEY = "flutter.cached_timestamp"
    private val REGISTERED_BINS_KEY = "flutter.cached_registered_bins"
    private val THIRTY_DAYS_IN_MILLIS = 30 * 24 * 60 * 60 * 1000L

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "From: ${remoteMessage.from}")

        // Check if message contains a data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
            
            // Check if we should show this notification based on cached credentials
            if (shouldShowNotification(remoteMessage.data)) {
                handleDataMessage(remoteMessage.data)
            } else {
                Log.d(TAG, "Skipping notification based on cached user credentials")
            }
        }

        // Check if message contains a notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
            showNotification(it.title ?: "Bin-It", it.body ?: "You have a new notification")
        }
    }
    
    private fun shouldShowNotification(data: Map<String, String>): Boolean {
        // Check if cache is valid
        if (!isCacheValid()) {
            Log.d(TAG, "Cache is not valid, skipping notification")
            return false
        }
        
        // Get the message type
        val messageType = data["type"] ?: return true // Default to showing if type is unknown
        
        // Get cached user type
        val sharedPrefs = getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
        val userType = sharedPrefs.getString(USER_TYPE_KEY, null)
        
        // For bin level updates and offer accepted, only show to bin owners
        if ((messageType == "bin_level_update" || messageType == "offer_accepted") && userType != "binOwner") {
            Log.d(TAG, "Not showing $messageType notification: User is not a bin owner")
            return false
        }
        
        // For bin level updates, check if the bin is registered to the user
        if (messageType == "bin_level_update") {
            val binId = data["binId"] ?: return true // Show if no binId provided
            
            // Get registered bins from shared preferences
            val registeredBinsJson = sharedPrefs.getString(REGISTERED_BINS_KEY, "[]")
            try {
                val registeredBins = JSONObject(registeredBinsJson).getJSONArray("value")
                var isBinRegistered = false
                
                // Check if the bin is in the registered bins list
                for (i in 0 until registeredBins.length()) {
                    if (registeredBins.getString(i) == binId) {
                        isBinRegistered = true
                        break
                    }
                }
                
                if (!isBinRegistered) {
                    Log.d(TAG, "Not showing bin level update: Bin $binId is not registered to the user")
                    return false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing registered bins: ${e.message}")
                // Default to showing the notification if there's an error
                return true
            }
        }
        
        return true
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

    private fun handleDataMessage(data: Map<String, String>) {
        val messageType = data["type"] ?: "unknown"
        
        // Create notification data
        val notificationData = data.toMutableMap()
        
        // Send notification through Flutter's notification service
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_type", messageType)
            putExtra("notification_data", JSONObject(notificationData).toString())
        }
        startActivity(intent)
    }

    private fun showNotification(title: String, messageBody: String) {
        // Create notification data
        val notificationData = mapOf(
            "type" to "generic",
            "title" to title,
            "body" to messageBody
        )
        
        // Send notification through Flutter's notification service
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_type", "generic")
            putExtra("notification_data", JSONObject(notificationData).toString())
        }
        startActivity(intent)
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")
        // Send token to your server
        // This will be handled by the Flutter app when it starts
    }
} 