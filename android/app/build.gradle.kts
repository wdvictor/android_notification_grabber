import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun Properties.readOptional(vararg keys: String): String {
    for (key in keys) {
        val value = getProperty(key)?.trim()
        if (!value.isNullOrEmpty()) {
            return value
        }
    }

    return ""
}

val envProperties = Properties().apply {
    val envFile = rootProject.file("../.env")
    if (envFile.exists()) {
        envFile.inputStream().use(::load)
    }
}

val xApiKey = envProperties.readOptional("X_API_KEY", "xapikey")
val backendBaseUrl = envProperties.readOptional("BACKEND_BASE_URL", "backendbaseurl")

android {
    namespace = "br.syntax.nebula.notificationsgrabber.notification_grabber"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.syntax.nebula.notificationsgrabber.notification_grabber"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("String", "X_API_KEY", "\"${xApiKey.replace("\"", "\\\"")}\"")
        buildConfigField(
            "String",
            "BACKEND_BASE_URL",
            "\"${backendBaseUrl.replace("\"", "\\\"")}\"",
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
