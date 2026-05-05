## Basic ProGuard/R8 rules for Flutter + typical plugins.
# Keep Flutter embedding and generated plugin registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Keep GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep classes referenced from native code by name
-keepclassmembers class * {
    native <methods>;
}

# Preserve Parcelable implementation used by Android
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep OkHttp and Gson models if used by reflection (safe fallback)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.google.gson.**

# Keep Firebase / Google Play services plugins entries if present
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# Add any additional plugin-specific keep rules here.
