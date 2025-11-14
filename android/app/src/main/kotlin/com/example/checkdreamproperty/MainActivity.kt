// Add this to android/app/src/main/kotlin/com/example/yourapp/MainActivity.kt

package com.example.checkdreamproperty // Replace with your package name

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PHONE_CALL_CHANNEL = "phone_call_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_CALL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "makePhoneCall" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")
                        if (phoneNumber != null) {
                            val success = makePhoneCall(phoneNumber)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Phone number is null", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun makePhoneCall(phoneNumber: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            // Check if there's an app that can handle this intent
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                // Fallback: Try to open dialer
                val dialerIntent = Intent(Intent.ACTION_DIAL).apply {
                    data = Uri.parse("tel:$phoneNumber")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                
                if (dialerIntent.resolveActivity(packageManager) != null) {
                    startActivity(dialerIntent)
                    true
                } else {
                    false
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}