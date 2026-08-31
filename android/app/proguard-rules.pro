# Flutter's default R8 rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter embedding references Play Core classes that may not be present.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# Keep enums used via name lookup.
-keepclassmembers enum * { *; }

# sqflite / SQLite reflection.
-dontwarn org.sqlite.**
-keep class org.sqlite.** { *; }

# cryptography / encrypt libraries (use reflection/internal crypto providers).
-keep class javax.crypto.** { *; }
-keep class javax.security.** { *; }

# flutter_secure_storage.
-dontwarn com.facebook.react.**

# pdf / pdfrx (pdfium is a native lib, keep its bindings).
-keep class com.shockwave.pdfium.** { *; }
-keep class org.pdftron.** { *; }

# Audio (audioplayers / record / audio_waveforms).
-dontwarn com.ryanheise.audioplayers.**
-keep class com.ryanheise.audioplayers.** { *; }

# local_auth / biometrics reflection.
-keep class androidx.biometric.** { *; }

# Generic catch-all for any service classes referenced by name (JSON/service locators).
-keep class * extends android.content.ContentProvider { *; }
