plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
} // ← cierre de plugins

android {
    namespace = "com.example.proyect_movil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    } // ← cierre de compileOptions

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    } // ← cierre de kotlinOptions

    defaultConfig {
        applicationId = "com.example.proyect_movil"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    } // ← cierre de defaultConfig

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        } // ← cierre de release
    } // ← cierre de buildTypes
} // ← cierre de android

flutter {
    source = "../.."
} // ← cierre de flutter

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}