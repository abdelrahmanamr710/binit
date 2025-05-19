package com.sams.binit.binit

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sams.binit/background_service"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startDatabaseListenerService" -> {
                    try {
                        Log.d(TAG, "Starting DatabaseListenerService from method channel")
                        startDatabaseListenerService()
                        result.success("Service started successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting service: ${e.message}")
                        result.error("SERVICE_START_ERROR", "Failed to start service", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startDatabaseListenerService() {
        val serviceIntent = Intent(this, DatabaseListenerService::class.java)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        
        Log.d(TAG, "DatabaseListenerService start requested")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Start the database listener service when the app starts
        try {
            startDatabaseListenerService()
            Log.d(TAG, "DatabaseListenerService started during onCreate")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting service during onCreate: ${e.message}")
        }
    }
}
