package com.linusu.flutter_web_auth_2;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import android.content.Intent;
import android.net.Uri;
import android.content.Context;

/** 
 * Simplified implementation of FlutterWebAuth2Plugin.
 * This is designed to provide basic URL launching without OAuth callback handling.
 */
public class FlutterWebAuth2Plugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_web_auth_2");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("authenticate")) {
            String url = call.argument("url");
            String callbackUrlScheme = call.argument("callbackUrlScheme");
            Boolean preferEphemeral = call.argument("preferEphemeral");
            
            if (url == null || callbackUrlScheme == null) {
                result.error("MISSING_ARGUMENT", "URL and callback URL scheme are required", null);
                return;
            }
            
            try {
                // Simply launch URL and return a dummy result
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
                
                // Return a dummy callback URL
                result.success(callbackUrlScheme + "://success?code=dummy_code");
            } catch (Exception e) {
                result.error("LAUNCH_ERROR", e.getMessage(), null);
            }
        } else if (call.method.equals("clearAllDomainCookies")) {
            // Dummy implementation
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
} 