# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit specific rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.ml.** { *; }
-keep class com.google.android.gms.tflite.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Mobile Scanner
-keep class dev.robocode.mobile_scanner.** { *; }

# Prevent R8 from stripping away important classes
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
