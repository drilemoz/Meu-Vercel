import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}
val versionMeta = Properties().apply { rootProject.file("version.properties").inputStream().use { load(it) } }
val keyFile = rootProject.file("key.properties")
val signing = Properties().apply { if (keyFile.exists()) keyFile.inputStream().use { load(it) } }
val stableSigning = keyFile.exists()
if (stableSigning) {
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach {
        require(!signing.getProperty(it).isNullOrBlank()) { "Assinatura incompleta: $it" }
    }
}
val allowTestSigning = System.getenv("MEU_VERCEL_TEST_SIGNING") == "true"
android {
    namespace = "app.meuvercel.android"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "app.meuvercel.android"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = versionMeta.getProperty("versionCode").toInt()
        versionName = versionMeta.getProperty("versionName")
    }
    signingConfigs {
        if (stableSigning) create("stable") {
            storeFile = rootProject.file(signing.getProperty("storeFile"))
            storePassword = signing.getProperty("storePassword")
            keyAlias = signing.getProperty("keyAlias")
            keyPassword = signing.getProperty("keyPassword")
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = if (stableSigning) signingConfigs.getByName("stable")
                else if (allowTestSigning) signingConfigs.getByName("debug") else null
        }
    }
}
// Fail a release invocation instead of silently publishing a production-looking unsigned APK.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release") } && !stableSigning && !allowTestSigning) {
        error("Assinatura persistente ausente. Para teste, defina explicitamente MEU_VERCEL_TEST_SIGNING=true.")
    }
}
flutter { source = "../.." }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
