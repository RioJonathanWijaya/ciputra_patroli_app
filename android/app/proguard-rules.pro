# Keep AndroidX classes
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.** { *; }
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.annotation.** { *; }

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep your model classes
-keep class com.example.ciputra_patroli.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep custom application class
-keep class com.example.ciputra_patroli.** { *; }

# Keep image compression libraries
-keep class com.example.ciputra_patroli.services.** { *; }

# Keep location services
-keep class com.google.android.gms.location.** { *; }

# Keep HTTP client
-keep class org.apache.http.** { *; }
-keep class org.apache.http.client.** { *; }

# Keep JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions

# Keep WebView
-keepclassmembers class * extends android.webkit.WebView {
    <methods>;
}

# Keep custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
} 