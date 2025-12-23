# 1. Flutter Core & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Firebase - Total Preservation
# We keep every class in the firebase and gms packages to prevent runtime crashes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**

# 3. Agora RTC Engine - Total Preservation
-keep class io.agora.** { *; }
-keep class com.agora.** { *; }
-keepnames class io.agora.** { *; }
-dontwarn io.agora.**

# 4. Background Services & Isolates
# This ensures the background isolate can find the entry points
-keep class id.flutter.flutter_background_service.** { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# 5. Native JNI Bridge (Crucial for Agora/Firebase)
-keepclasseswithmembernames class * {
    native <methods>;
}

# 6. AdMob & Facebook
-keep class com.google.android.gms.ads.** { *; }
-keep class com.facebook.** { *; }

# 7. Data & Storage (Hive)
-keep class com.ibeam.hive.** { *; }
-dontwarn com.ibeam.hive.**

# 8. Kotlin & Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# 9. General Preservation
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
