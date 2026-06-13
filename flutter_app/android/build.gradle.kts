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

// Fix: AGP 8.6+ requires namespace in build.gradle for library modules.
// isar_flutter_libs 3.1.x doesn't set namespace, so we inject it here.
subprojects {
    plugins.withId("com.android.library") {
        val libExt = project.extensions.findByType<com.android.build.gradle.LibraryExtension>()
        if (libExt != null && libExt.namespace == null) {
            libExt.namespace = "io.isar.${project.name}"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
