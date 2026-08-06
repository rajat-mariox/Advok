allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround: file_picker >= 11 skips applying the Kotlin plugin on AGP 9+, assuming
// built-in Kotlin is enabled — but Flutter 3.44 still runs with android.builtInKotlin=false,
// so its Kotlin sources never compile ("cannot find symbol FilePickerPlugin").
// Remove once on Flutter 3.47+ with android.builtInKotlin=true.
subprojects {
    if (name == "file_picker") {
        apply(plugin = "org.jetbrains.kotlin.android")
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
