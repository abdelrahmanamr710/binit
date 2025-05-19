plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sams.binit.binit"
    compileSdk = 35 // Latest stable SDK

    defaultConfig {
        applicationId = "com.sams.binit.binit"
        minSdk = 23 // Minimum supported API level
        targetSdk = 35 // Latest stable SDK
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Enable Java 8+ desugaring required by flutter_local_notifications
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8" // Match Java compatibility
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM for consistent versions
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    
    // Firebase Auth
    implementation("com.google.firebase:firebase-auth-ktx")
    
    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Firebase Realtime Database
    implementation("com.google.firebase:firebase-database-ktx")
    
    // Firebase Firestore (if needed)
    implementation("com.google.firebase:firebase-firestore-ktx")
    
    // Core library desugaring for Java 8+ APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    
    // AndroidX AppCompat
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // Local notifications plugin
    implementation(project(":flutter_local_notifications"))
    
    // Add other plugin dependencies below
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
}

flutter {
    source = "../.."
}
