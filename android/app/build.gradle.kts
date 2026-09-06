import java.util.Base64
import java.util.Properties

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
val appName = dartDefines["APP_NAME"] ?: "MyApp"
val deepLinkHost = dartDefines["DEEP_LINK_HOST"] ?: ""
val customScheme = dartDefines["CUSTOM_SCHEME"] ?: "yourapp"

// Replace YOUR_APP_NAME with your app's secrets directory name
val keystoreEnv = when {
    appBundleId.endsWith(".dev")     -> "dev"
    appBundleId.endsWith(".staging") -> "staging"
    else                             -> "prod"
}
val keystorePropsFile = File(System.getProperty("user.home"), ".secrets/YOUR_APP_NAME/android/$keystoreEnv/keystore.properties")
val keystoreProps = Properties()
if (keystorePropsFile.exists()) {
    keystorePropsFile.inputStream().use { keystoreProps.load(it) }
}

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

    signingConfigs {
        create("release") {
            if (keystorePropsFile.exists()) {
                storeFile = File(keystorePropsFile.parentFile, keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = appBundleId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The launcher label comes from the same secrets file as everything
        // else, so it tracks the environment instead of being hardcoded - and
        // a spawned app does not install under the template's name.
        manifestPlaceholders["appName"] = appName
        manifestPlaceholders["deepLinkHost"] = deepLinkHost
        manifestPlaceholders["customScheme"] = customScheme
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
