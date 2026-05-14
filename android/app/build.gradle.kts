import java.util.Base64

// Decode dart-defines injected via --dart-define-from-file
val dartDefines: Map<String, String> = run {
    val map = mutableMapOf<String, String>()
    if (project.hasProperty("dart-defines")) {
        (project.property("dart-defines") as String).split(",").forEach { entry ->
            val decoded = String(Base64.getDecoder().decode(entry))
            val idx = decoded.indexOf('=')
            if (idx > 0) map[decoded.substring(0, idx)] = decoded.substring(idx + 1)
        }
    }
    map
}

val appBundleId = dartDefines["APP_BUNDLE_ID"] ?: "com.yourcompany.firebase_template"
val deepLinkHost = dartDefines["DEEP_LINK_HOST"] ?: ""
val customScheme = dartDefines["CUSTOM_SCHEME"] ?: "yourapp"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.yourcompany.firebase_template"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = appBundleId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["deepLinkHost"] = deepLinkHost
        manifestPlaceholders["customScheme"] = customScheme
    }

    buildTypes {
        release {
            // TODO: Add your own signing config before releasing
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
