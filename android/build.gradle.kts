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

// whisper_ggml 2.6.0 (anclado por la constitución) fija compileSdk 34 en su
// propio android/build.gradle, por debajo de lo que exige su propia
// dependencia transitiva ffmpeg_kit_flutter_new_min (>= 35). No es editable
// desde el árbol de este repo sin tocar el paquete de pub cache ni cambiar
// la versión anclada, así que se fuerza compileSdk 36 en todos los
// subproyectos Android para que la comprobación de AAR metadata pase.
// Descubierto en la primera compilación real sobre dispositivo del
// incremento 2; ni research.md ni quickstart.md lo documentaban.
// Debe registrarse ANTES de `evaluationDependsOn(":app")` de abajo: ese
// bloque fuerza la evaluación inmediata de `:app`, y `afterEvaluate` lanza
// si el proyecto ya terminó de evaluarse.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
