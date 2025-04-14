plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sams.binit.binit"
    compileSdk = 34 // Explicitly set to the latest stable SDK

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17 // Use Java 17
        targetCompatibility = JavaVersion.VERSION_17 // Use Java 17
    }

    kotlinOptions {
        jvmTarget = "17" // Use Java 17
    }

    defaultConfig {
        applicationId = "com.sams.binit.binit"
        minSdk = 23 // Explicitly set to 23 (or higher)
        targetSdk = 34 // Explicitly set to the latest stable SDK
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    dependencies {
        // Import the Firebase BoM
        implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

        // Add the dependencies for Firebase products you want to use
        // When using the BoM, don't specify versions in Firebase dependencies
        implementation("com.google.firebase:firebase-auth")
    }
}

flutter {
    source = "../.."
}