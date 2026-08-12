plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.upreq.up_req"
    // compileSdk/ndkVersion explícitos (incremento 2): flutter.compileSdkVersion
    // resuelve a 34 con Flutter 3.44.9, pero ffmpeg_kit_flutter_new_min
    // (dependencia transitiva de whisper_ggml) exige compilar contra la API 35
    // o superior, y whisper_ggml exige NDK 29.0.13113456. flutter.ndkVersion
    // resuelve a 28.2.13676358, insuficiente. Descubierto al compilar en
    // dispositivo real; research.md/quickstart.md solo documentaron el alza
    // de minSdk a 24.
    compileSdk = 36
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.upreq.up_req"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdkVersion sube a 24 en el incremento 2: lo exige
        // ffmpeg_kit_flutter_new_min (research.md, decisión 7). Sigue muy por
        // debajo de Android 10 (API 29), el objetivo de producto.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
