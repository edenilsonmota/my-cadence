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
// Plugins antigos (ex.: keyboard_height_plugin, do editor) compilam contra SDKs
// que não precisamos instalar (android-31). Compila todos com o mesmo SDK do
// app; o targetSdk de cada um não muda.
val pluginCompileSdk = 37
subprojects {
    val forceCompileSdk = {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.compileSdk = pluginCompileSdk
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
