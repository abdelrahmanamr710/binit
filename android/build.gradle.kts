buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2") // Correct: Inside dependencies {}
        classpath("com.android.tools.build:gradle:8.2.2") // Add this line to add the android gradle plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20") // Add this line to add the kotlin gradle plugin
    }
}

// Add namespace fix for Android modules
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            try {
                if (android.namespace == null) {
                    android.namespace = "${project.group}"
                }
            } catch (e: Exception) {
                // Ignore if namespace is already set
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
    val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
    rootProject.layout.buildDirectory.value(newBuildDir)
    subprojects {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
    subprojects {
        project.evaluationDependsOn(":app")
    }
}
