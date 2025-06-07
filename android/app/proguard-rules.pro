# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# For flutter_web_auth_2 plugin issues
-keep class androidx.browser.** { *; }

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Appwrite specific
-keep class io.appwrite.** { *; }
-keep class com.linusu.flutter_web_auth_2.** { *; }

# Keep our custom implementation
-keep class com.linusu.flutter_web_auth_2.FlutterWebAuth2Plugin

# Exclude the original plugin implementation that uses Registrar
-keep,allowobfuscation class !com.linusu.flutter_web_auth_2.** { *; } 