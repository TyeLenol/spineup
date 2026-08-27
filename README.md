# SpineUp

SpineUp is an open-source, local-first Flutter app for scoliosis self-management, everyday record keeping, gentle routines, and care conversations. It is designed for a person using it for themselves or for a person they care for. The app requires no account and does not use cloud sync or analytics for its core experience.

SpineUp is **not a medical device, diagnostic tool, treatment planner, progression predictor, or emergency service**. It helps users record what they choose to track, explore general source-linked information, build a gentle routine, and prepare questions for a qualified healthcare professional.

> Your records stay on your device unless you deliberately export them. SpineUp does not replace professional assessment or care.

## Current status

The current app targets **Android and Web**. iOS is not part of the present scope. Community is intentionally hidden from the active navigation while that future surface is deferred.

The active navigation contains four areas:

| Area | Purpose |
| --- | --- |
| **Today** | Daily check-in, active routine, guided exercise steps, appointments, streaks, level, and XP. |
| **My Journey** | Local Cobb-angle history, contextual pain/activity information, recent records, and appointment/angle logging. |
| **Learn** | Topics, source-linked articles, videos, search, categories, saved items, and routine-video selection. |
| **Me** | Active care space, profile details, avatar customisation, progress, milestones, and Settings access. |

## What is implemented

SpineUp includes a three-screen warm onboarding flow, a six-step profile setup flow, self and caregiver-owned care spaces, structured profile fields, daily check-ins, local event history, appointment logging, Cobb-angle logging, a modernised Journey chart, guided exercises with timers, editable routine templates, page-aware quick tours, compact XP feedback, streaks and milestones, local daily Android reminders, and a local Avatar Studio.

Avatar Studio supports three curated DiceBear-based illustrated styles—Open Peeps, Croodles, and Line Face/Lorelei Neutral—with controlled feature options, style-preserving randomisation, local photo switching, per-care-subject persistence, and license credits.

Learn includes local topic guides, source-linked curated reading briefs, RSS-discovered article summaries, embedded YouTube playback where a video ID is available, original-source links, content saving, and the ability to add exercise videos to **My Routine**. Feed failure is non-fatal because curated content remains available offline.

## Privacy and data model

SpineUp stores the main record experience locally. SQLite stores care subjects, events, runtime profiles, appointments, and profile data in `spineup.db`. SharedPreferences stores small local settings such as the active subject, routine selection, reminder state, saved content IDs, feed cache, and quick-tour completion.

A session owner can manage separate care spaces for themselves and people they care for. Events, appointments, profile fields, routines, saved content, and reminders are scoped to the active care subject. Switching from a self profile to a ward profile does not copy the caregiver’s health fields into the ward profile.

Users can export an owner-scoped protected archive and later import it either as separate subjects or by explicitly replacing one selected subject. The archive uses AES-256-GCM with an Argon2id-derived key. A passphrase of at least 12 characters is required, and SpineUp cannot recover a forgotten passphrase. Custom photo attachments are intentionally omitted from the archive and are reported in the export preview.

The core product has no cloud database, mandatory sign-in, cloud sync, or analytics. External network access is limited to optional Learn refreshes, source pages, thumbnails, and YouTube playback. See the full privacy and portability description in [`docs/APP_DOCUMENTATION.md`](docs/APP_DOCUMENTATION.md).

## Technology and repository layout

| Layer | Main implementation |
| --- | --- |
| UI and navigation | Flutter widgets in `lib/screens/` and `lib/widgets/` |
| Domain models | `lib/models/` |
| Local persistence | `lib/data/database_helper.dart`, `sqflite`, `SharedPreferences` |
| Domain services | `lib/services/` |
| Theme and motion | `lib/theme/` |
| Android platform integration | `android/` for notifications, adaptive icon, launcher assets, and build configuration |
| Web/PWA integration | `web/` for favicon, manifest, metadata, and icons |
| Branding source | `assets/branding/spineup_mark.svg` |
| Automated quality | `.github/workflows/flutter_quality.yml` |
| Tests | `test/` |

The application starts in `lib/main.dart`, shows the branded `SplashScreen`, and then routes to onboarding or the `NavigationShell` based on local care-subject state. `SessionService` centralises owner and active-care-subject boundaries so screens do not invent separate identity rules.

## Getting started

Install Flutter and the Android tooling, then verify the environment:

```bash
flutter doctor -v
flutter --version
```

From the repository root, resolve packages and run the app:

```bash
flutter pub get
flutter run
```

To run a Web build, list available devices first and choose a Web device:

```bash
flutter devices
flutter run -d chrome
```

For ordinary development, use debug mode and hot reload. The project’s CI currently uses Flutter **3.44.9 stable** and declares a Dart environment of `^3.12.2`; matching those versions locally reduces avoidable differences.

## Validation before committing

Run the same core checks used by the repository’s quality workflow:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions resolves dependencies, checks formatting for changed Dart files, runs `flutter analyze`, runs the complete Flutter test suite, and builds an Android debug APK. The workflow is intentionally a debug-build quality gate; it is not a signed release pipeline.

## Building an Android release

There are two different meanings of “release APK.” A release-mode test APK is optimised for performance but, with the current repository configuration, still uses the debug signing configuration. A public distributable build must use a private release keystore and an explicit Gradle signing configuration.

Fraunces and Outfit are bundled under `assets/fonts/`, so the release APK uses the same branded typography as debug even when the device is offline. This adds roughly 528 KB before final APK compression.

For a quick local release-mode test from VS Code’s integrated terminal:

```bash
flutter build apk --release
```

The output is normally:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install it on a connected device with:

```bash
flutter install --release
```

For the complete VS Code and Android Studio procedure—including keystore creation, `android/key.properties`, Gradle signing, version numbers, App Bundles, verification, and troubleshooting—read [`docs/RELEASE_FROM_IDE.md`](docs/RELEASE_FROM_IDE.md). Flutter’s official Android deployment guide covers the same release concepts and build outputs [1], while Android’s signing guide explains why a permanent private signing key matters for updates [2].

## Important release limitations

The project is in a strong school-project state, but the icon/branding work should not be interpreted as full F-Droid release readiness. Before a public release, the project still needs a permanent Android application ID instead of `com.example.spineup`, a recognised open-source `LICENSE` file, dependency/license review, release metadata and screenshots, a real release-signing process, an isolated source build, and real-device QA.

The current release block in `android/app/build.gradle.kts` signs with the debug key so local release-mode testing works. Do not distribute that artifact as the official production release. Also remember that an app’s signing identity must be preserved for future Android updates [2].

The Android `INTERNET` permission is currently declared only in the debug and profile manifest variants, not in `android/app/src/main/AndroidManifest.xml`. Consequently, RSS refreshes, source pages, thumbnails, and YouTube playback may not work in a release APK until the permission is added to the main manifest. That permission would enable only the existing optional external-content requests; it would not add cloud sync, accounts, or analytics.

## Documentation

| Document | Contents |
| --- | --- |
| [`docs/APP_DOCUMENTATION.md`](docs/APP_DOCUMENTATION.md) | Full product, architecture, feature, storage, privacy, content, gamification, testing, maintainer, and release-posture reference. |
| [`docs/RELEASE_FROM_IDE.md`](docs/RELEASE_FROM_IDE.md) | Step-by-step VS Code and Android Studio release-build instructions. |
| [`assets/branding/spineup_mark.svg`](assets/branding/spineup_mark.svg) | Scalable source for the splash-derived SpineUp loop-and-dot mark. |
| [Flutter Android deployment guide](https://docs.flutter.dev/deployment/android) | Official Flutter build and release reference. |
| [Android app signing guide](https://developer.android.com/studio/publish/app-signing) | Official Android keystore and signing reference. |

## Contributing

Keep changes scoped to the feature being improved and preserve the local-first boundary. When adding persistent data, update the model serialization, SQLite migration if required, protected archive behavior, and tests. When adding external content, keep the original source visible, retain safety framing, and provide a graceful offline path.

Before opening a pull request, run formatting, analysis, tests, and an Android debug build. For changes involving notifications, external media, launcher assets, adaptive icons, or Android activity recreation, also test on a real Android device when possible.

## References

[1]: https://docs.flutter.dev/deployment/android "Flutter: Build and release an Android app"
[2]: https://developer.android.com/studio/publish/app-signing "Android Developers: Sign your app"
