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

allprojects {
    repositories {
        google()
        mavenCentral()
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
