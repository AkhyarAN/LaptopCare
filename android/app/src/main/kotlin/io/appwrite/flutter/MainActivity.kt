package io.appwrite.flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.laptopcare/auth"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register a method channel to handle authentication without flutter_web_auth_2
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "authenticate") {
                val url = call.argument<String>("url") ?: ""
                val callbackUrlScheme = call.argument<String>("callbackUrlScheme") ?: ""
                
                try {
                    // Launch browser with CustomTabs
                    val customTabsIntent = CustomTabsIntent.Builder().build()
                    customTabsIntent.launchUrl(this, Uri.parse(url))
                    result.success("success")
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
