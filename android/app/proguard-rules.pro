# Keep OkHttp classes required by image_cropper / ucrop
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Also protect ucrop itself (very common fix for this error)
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Optional: keep anything related to image_cropper if needed
-keep class com.yalantis.ucrop.task.** { *; }
-dontwarn com.yalantis.ucrop.task.**