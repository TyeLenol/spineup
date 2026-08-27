# Building a SpineUp Android release from an IDE

This guide explains how to create a release-mode Android artifact from the SpineUp project using **VS Code** or **Android Studio**. It covers two different outcomes that are often confused:

1. A **release-mode test build**, which is optimized and useful for testing on a phone.
2. A **properly signed distributable build**, which is required before publishing an official APK through a store or distributing signed updates.

Flutter’s official Android release guide describes the same overall sequence: review the Android configuration, configure signing, choose the artifact type, build it, and test the output [1]. Android requires installable APKs to be digitally signed, and losing the permanent signing key can prevent future updates from being accepted [2].

## 1. Current SpineUp status

The repository currently has the following Android settings:

| Setting | Current value | Meaning |
| --- | --- | --- |
| App label | `SpineUp` | The name shown to users. |
| Application ID | `com.example.spineup` | Still a placeholder and should be replaced with a permanent ID before public distribution. |
| Flutter version used by CI | `3.44.9` stable | Use the same stable Flutter line when reproducing CI locally. |
| Dart environment | `^3.12.2` | Declared in `pubspec.yaml`. |
| Current version | `1.0.0+1` | `1.0.0` is the version name; `1` is the Android version code. |
| Release signing | Debug signing configuration | The current `release` build is optimized but is **not yet an official production-signed SpineUp release**. |
| CI validation | Resolve, format check, analyze, test, Android debug build | Defined in `.github/workflows/flutter_quality.yml`. |
| Branded text fonts | Fraunces and Outfit are bundled under `assets/fonts/` | Release typography no longer depends on Google Fonts runtime fetching. |

One platform detail is important before testing network-backed features in a release APK: the current `INTERNET` permission is present in the debug and profile manifest variants, but not in `android/app/src/main/AndroidManifest.xml`. A release build uses the main manifest, so RSS refreshes, source pages, thumbnails, and YouTube playback may be unavailable in the current release artifact until that permission is moved or added to the main manifest. This is not cloud sync; it only permits the optional outbound requests that Learn and external media already use.

The current `android/app/build.gradle.kts` intentionally contains:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

This makes `flutter run --release` and local release-mode testing convenient, but it must be replaced with a real private release key before distributing an official SpineUp APK. Do not use the current debug-signed output as the final public release.

## 2. Prerequisites

Install Flutter, Android Studio or the Android SDK command-line tools, an Android SDK platform and build tools, and a Java runtime supplied by Android Studio. Verify the environment from the project root:

```bash
flutter doctor -v
flutter --version
flutter pub get
```

The Flutter version used by CI is recorded in `.github/workflows/flutter_quality.yml`. If your local Flutter version differs, the project may still work, but matching CI reduces avoidable build differences.

Use a physical Android device or an emulator for testing. Enable Developer Options and USB debugging on a physical device, then verify that Flutter can see it:

```bash
flutter devices
```

## 3. Fastest path from VS Code: release-mode test APK

This is the recommended path when you want an APK on your phone for testing the current app without changing signing configuration.

### Step 1: Open the correct folder

In VS Code, open the repository root—the folder containing `pubspec.yaml`, `lib/`, `android/`, `web/`, and `test/`. Open **Terminal > New Terminal** and confirm that the terminal is in that folder.

### Step 2: Resolve and validate

Run:

```bash
flutter pub get
flutter analyze
flutter test
```

If these complete successfully, build the release-mode APK:

```bash
flutter build apk --release
```

Flutter writes the artifact to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

You can install it from the same terminal if a device is connected:

```bash
flutter install --release
```

Alternatively, copy `app-release.apk` to the phone and open it from the device’s file manager. Android may require permission to install an APK from that source.

You can also launch directly into release mode while connected to a device:

```bash
flutter run --release
```

This path tests the release build mode, tree-shaking, native startup, launcher icon, bundled branded typography, external media, local notifications, and performance more realistically than debug mode. The bundled Fraunces and Outfit files add roughly 528 KB before final APK compression, which is the expected trade-off for keeping the intended typeface consistent offline. It is still debug-signed in the current repository configuration, so it is for testing rather than public distribution.

## 4. Smaller architecture-specific APKs

A single APK can contain multiple CPU architectures and be larger than necessary. To create one APK per supported ABI, run:

```bash
flutter build apk --release --split-per-abi
```

Typical outputs appear under:

```text
build/app/outputs/flutter-apk/
```

The filenames normally identify the ABI, such as `app-arm64-v8a-release.apk`. For a normal modern Android phone, the arm64 artifact is usually the relevant one, but select the correct artifact for the device being tested. If you are unsure, use the universal `app-release.apk` instead.

## 5. App Bundle versus APK

Use an APK when you want to install directly on a phone or send a test file to someone. Use an Android App Bundle when a distribution service expects a bundle and will generate device-specific APKs. Flutter documents both build paths [1].

| Goal | Command | Output |
| --- | --- | --- |
| Universal release APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| ABI-split release APKs | `flutter build apk --release --split-per-abi` | Multiple APKs under `build/app/outputs/flutter-apk/` |
| Release App Bundle | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| Direct release-mode run | `flutter run --release` | Installs/runs on a connected device |

For the current F-Droid direction, do not assume that an App Bundle is the final artifact. F-Droid build and signing requirements are a separate packaging workflow. The repository still needs its permanent application ID, recognized open-source license, metadata, dependency review, and isolated source build before it should be described as F-Droid-ready.

## 6. Properly sign a distributable release

### 6.1 Create a release keystore in Android Studio

Keep the keystore outside the Git repository, in a backed-up private location. Android Studio provides a wizard:

1. Open the Android project in Android Studio. If the Flutter project is already open, allow Android Studio to sync the Android module; otherwise open the `android/` folder as the Gradle project.
2. Select **Build > Generate Signed Bundle / APK**.
3. Select **APK** if you need an installable APK, or **Android App Bundle** if your intended distribution workflow requires an AAB, then click **Next**.
4. Select the `app` module.
5. Beside **Key store path**, choose **Create new**.
6. Store the `.jks` file outside the repository. Choose a strong keystore password, a key alias, a strong key password, and a long validity period.
7. Record the keystore path, alias, and passwords in a password manager. The private keystore is part of the app’s long-term update identity; do not lose it and do not commit it to Git.

Android Studio can generate a signed artifact through this wizard, but a Flutter project should also have the signing configuration represented in `android/app/build.gradle.kts` so that command-line and IDE Flutter builds use the intended release key consistently.

### 6.2 Create `android/key.properties`

Create this file locally at `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=/absolute/path/to/your/spineup-release.jks
```

On Windows, use a path with escaped backslashes, for example:

```properties
storeFile=C:\\Users\\YourName\\Keys\\spineup-release.jks
```

Never replace the placeholders with real secrets in a message, issue, screenshot, or public commit. The current repository ignore rules do not yet add `android/key.properties` or keystore extensions automatically. Before creating the file, add local ignore entries such as these to your private working copy, and commit them only if you want the repository to enforce the policy for every contributor:

```gitignore
android/key.properties
*.jks
*.keystore
```

### 6.3 Load the properties in `android/app/build.gradle.kts`

At the top of `android/app/build.gradle.kts`, before the `android { ... }` block, add:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside the existing `android { ... }` block, add a release signing configuration and point the release build type to it:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

Remove the existing debug-signing assignment when you make this change. Do not keep both assignments in the same `release` block and assume the correct one will win; make the release configuration explicit.

Flutter’s official guide notes that running `flutter clean` after signing configuration changes can prevent cached build artifacts from affecting the result [1]. Run:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

If Gradle reports that the keystore file, alias, or password is missing, stop and correct `android/key.properties`; do not put secrets directly into `build.gradle.kts`.

### 6.4 Build the signed artifact

From the VS Code terminal or Android Studio’s terminal, run:

```bash
flutter build apk --release
```

For an App Bundle:

```bash
flutter build appbundle --release
```

The same commands can be run from Android Studio’s **Terminal** tool window. The important point is that the Flutter project root must be the current directory.

In Android Studio, you can also use **Build > Generate Signed Bundle / APK** after the Gradle signing configuration is in place. Select the `app` module, choose the `release` variant, select the configured keystore, and let Android Studio show the generated artifact location when the build completes.

## 7. Versioning a release

The current version is declared in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

The portion before `+` is the user-facing version name. The portion after `+` is the Android build/version code. Increase the build number for every distributable update. You can change the file before committing, or override it for a build:

```bash
flutter build apk --release \
  --build-name=1.0.1 \
  --build-number=2
```

For a maintainable release, update `pubspec.yaml`, commit the version change, and build from that commit rather than relying only on an unrecorded command-line override. The application ID should also be finalized before public distribution; changing it later creates a different Android application identity rather than an ordinary update.

## 8. Verify the artifact before sharing it

After the build completes, perform these checks:

1. Install the APK on a clean or reset test device.
2. Confirm the launcher name is **SpineUp** and the splash/icon mark is correct.
3. Run onboarding and create both a self profile and, if relevant, a separate ward profile.
4. Test Today check-in, routine editing, exercise completion, XP feedback, and appointments.
5. Test Journey chart rendering, Cobb-angle logging, contextual overlays, and activity history.
6. Test Learn topics, search, RSS refresh, curated article briefs, YouTube playback, source links, saving, and adding an exercise video to My Routine.
7. Test Me, Avatar Studio, subject switching, profile editing, and Settings.
8. Enable and disable the Android reminder and test behavior after an app restart or device reboot where possible.
9. Export a protected archive, inspect it, import it into a separate test profile, and verify that the custom photo omission is clearly represented.
10. Confirm that deleting local data removes the intended owner and care-subject records.

For a signed APK, the Android SDK includes `apksigner` in the build-tools directory. If it is available on your PATH, a basic signature verification command is:

```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

You can also inspect signing information from Android Studio’s Gradle tool window using the `signingReport` task. Android’s signing documentation describes the relationship between the signing key, upload key, certificates, and update continuity [2].

## 9. Android Studio workflow at a glance

| Action | Android Studio location |
| --- | --- |
| Sync Android module | Open the Flutter project or `android/` module and allow Gradle sync. |
| Create keystore | **Build > Generate Signed Bundle / APK > Create new** |
| Generate signed APK/AAB | **Build > Generate Signed Bundle / APK** |
| Inspect signing fingerprints | Gradle tool window > `app` > `Tasks` > `android` > `signingReport` |
| Run Flutter release mode | Use the integrated terminal: `flutter run --release` |
| Build Flutter release artifact | Use the integrated terminal: `flutter build apk --release` or `flutter build appbundle --release` |

Android Studio’s signing wizard is useful for key creation and artifact generation. The Flutter command-line build is usually the clearest repeatable path for this project because it runs from the same project root and is easy to reproduce in CI or release notes.

## 10. VS Code workflow at a glance

| Action | VS Code location |
| --- | --- |
| Open project | **File > Open Folder**, choose the folder containing `pubspec.yaml`. |
| Run validation | **Terminal > New Terminal**, then `flutter analyze` and `flutter test`. |
| Build test release APK | Terminal: `flutter build apk --release`. |
| Install to device | Terminal: `flutter install --release`. |
| Run directly in release mode | Terminal: `flutter run --release`. |
| Inspect output | Open the `build/app/outputs/` folder in the Explorer. |

The normal VS Code Run button launches a debug-oriented development session. Use the explicit release commands above when you want to test release behavior.

## 11. Troubleshooting slow builds

The first Android build can take a long time because Gradle, Android build tools, Flutter artifacts, and plugin dependencies may need to be downloaded. Release builds can also take longer than debug builds because Android release optimization and shrinking are more expensive. Do not interpret a long `assembleProfile` or `assembleRelease` step by itself as a code failure.

If a build appears stuck:

```bash
flutter doctor -v
flutter pub get
flutter clean
flutter build apk --release --verbose
```

Use `flutter run` in debug mode for normal UI iteration, and reserve release builds for pre-release checks. Avoid deleting all Gradle caches as a first response; a poor network connection can make the next build even slower. If the verbose output reports a specific dependency, Java, SDK, or signing error, fix that reported issue rather than repeatedly restarting the same build.

## 12. Release safety checklist

Before distributing an official build, confirm that the application ID is permanent, the license and release metadata are present, the release artifact is signed with a private non-debug key, the keystore is backed up securely, `key.properties` and private keystores are not tracked by Git, the version/build number is increased, the full tests pass, and a clean-device installation has been exercised.

Do not call a debug-signed `flutter build apk --release` output a production release. It is a useful release-mode test artifact, but a public update requires a stable signing identity. For the future F-Droid path, document the exact source commit and build recipe and complete the separate metadata, license, dependency, reproducibility, and device-validation work.

## References

[1]: https://docs.flutter.dev/deployment/android "Flutter: Build and release an Android app"
[2]: https://developer.android.com/studio/publish/app-signing "Android Developers: Sign your app"
[3]: https://docs.flutter.dev/get-started/install "Flutter: Install Flutter"
