# Flutter関連のルール
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase関連のルール
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin Metadata
-dontwarn kotlin.reflect.jvm.internal.**
-keep class kotlin.Metadata { *; }

# WorkManager
-keep class androidx.work.** { *; }

# その他のAndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**