# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# App-specific Widget Providers
-keep class io.github.sslaia.wikinusa.** { *; }
-keepclassmembers class io.github.sslaia.wikinusa.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }
-keepclassmembers class es.antonborri.home_widget.** { *; }

# SQLite3 & Drift
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }
-keep class com.simonoid.** { *; }

# Audio session & Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-dontwarn com.ryanheise.**

# Google Play Core & Deferred Components (referenced optionally by Flutter engine)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**

# AndroidX Startup & Initializers
-keep class * extends androidx.startup.Initializer {
    <init>();
}
-keep class androidx.startup.** { *; }

# AndroidX WorkManager & Room (used by home_widget and background tasks)
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
    *;
}
-keep class * extends androidx.room.RoomDatabase {
    <init>();
    *;
}
-keepclassmembers class * extends androidx.room.RoomDatabase {
    *;
}
-keep class androidx.room.** { *; }
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**


