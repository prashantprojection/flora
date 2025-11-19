# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# General rules for Google HTTP client libraries and related dependencies
-keep class com.google.api.client.** { *; }
-keep class com.google.api.services.** { *; }
-keep class com.google.auth.** { *; }

# Keep model classes for libraries that use reflection for JSON serialization
-keep class com.google.gson.** { *; }
-keep @com.google.gson.annotations.SerializedName class * {
   <fields>;
}

# Keep classes related to gRPC and Protocol Buffers if used by the library
-keep class io.grpc.** { *; }
-keep class com.google.protobuf.** { *; }

# Keep classes for Google AI
# Note: These are general rules as specific ones are not documented.
# You may need to adjust them based on any runtime errors.
-keep class com.google.ai.client.generativeai.** { *; }
-keep class com.google.android.gms.tflite.** { *; }

# OkHttp rules (often a dependency)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task