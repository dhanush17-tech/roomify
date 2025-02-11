package com.roomify.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.telephony.TelephonyManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.roomify.app/phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPhoneNumber") {
                try {
                    val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val phoneNumber = telephonyManager.line1Number
                    
                    if (phoneNumber != null && phoneNumber.isNotEmpty()) {
                        result.success(phoneNumber)
                    } else {
                        result.success("")
                    }
                } catch (e: SecurityException) {
                    result.error("PERMISSION_DENIED", "Phone permission not granted", null)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not get phone number", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
} 