import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A helper class to provide OAuth authentication functionality
/// without relying on flutter_web_auth_2 which has compatibility issues
class WebAuthHelper {
  static const MethodChannel _channel = MethodChannel('app.laptopcare/auth');

  /// Authenticate using a URL and expected callback URL scheme
  static Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) async {
    try {
      // Try to use the native method channel first
      return await _channel.invokeMethod('authenticate', {
        'url': url,
        'callbackUrlScheme': callbackUrlScheme,
      });
    } catch (e) {
      // Fall back to URL launcher if the method channel fails
      return _launchURL(url);
    }
  }

  /// Launch URL with fallback options
  static Future<String> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return url; // Return the URL as if authentication succeeded
      } else {
        throw Exception('Could not launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      throw Exception('Failed to launch authentication URL: $e');
    }
  }
}
