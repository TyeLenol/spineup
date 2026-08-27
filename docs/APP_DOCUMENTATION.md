# SpineUp application documentation

**Project:** SpineUp
**Platform:** Flutter Android and Web
**Current documentation revision:** 1.0
**Author:** Manus AI

## 1. What SpineUp is

SpineUp is an open-source, local-first scoliosis self-management companion designed for a school project and a possible future F-Droid-oriented public release. It helps a person, parent, or caregiver keep a small, understandable record of everyday care activities without requiring an account, cloud synchronization, advertising, analytics, or a medical-device claim.

The app is intentionally a **recording, learning, routine, and conversation-support tool**. It is not a clinician, diagnostic system, progression predictor, treatment planner, or emergency service. The app’s copy and safety labels repeatedly direct users to qualified healthcare professionals for individual assessment, new or worsening symptoms, and questions about exercises or treatment.

> SpineUp records what a person chooses to track. It does not diagnose scoliosis, measure progression, prescribe exercises, or replace professional care.

The current repository supports Android and Web builds. iOS is not part of the present delivery scope. Community is intentionally hidden for now; its model and screen remain in the source tree but are not part of the active four-tab navigation experience.

## 2. Product principles

| Principle | What it means in the implementation |
| --- | --- |
| **Local first** | User records are stored on the device. A user does not need an online account to use the main experience. |
| **Private by default** | Health-related records are scoped to the active local owner and care subject. The app does not silently upload them. |
| **Portable by choice** | Users can export and import protected archives when changing phones or preserving a backup. |
| **Caregiver-aware** | One local owner can manage separate care spaces for themselves and people they care for. |
| **Non-diagnostic** | Cobb angles, symptoms, exercises, and articles are framed as records or general information rather than clinical conclusions. |
| **Gentle motivation** | XP, levels, streaks, milestones, and feedback encourage return use without turning health information into a competition. |
| **Warm and human** | The interface uses a mature hand-drawn identity, cream/sage/coral/lavender colors, expressive illustration, restrained motion, and clear hierarchy. |
| **Open-source direction** | The project avoids mandatory proprietary identity, cloud, analytics, or store-specific account assumptions. |

## 3. User-facing feature inventory

### 3.1 First launch and onboarding

The app begins at the branded splash screen. The splash uses the SpineUp loop-and-dot mark and then checks local state. A first-time user sees a three-screen onboarding carousel that introduces gentle care, support for oneself or someone else, and protected portability. The carousel supports skip, next, back, progress dots, keyboard navigation on Web, swipe navigation, and reduced-motion-aware transitions.

After onboarding, the local-first welcome screen explains that the user can create a private space for themselves or someone they care for. The primary action opens the six-step profile setup flow. No sign-in or account creation is required for the current product direction.

### 3.2 Profile setup and care spaces

Profile setup is a six-step flow. It is reused for first-run setup, editing the current profile, and creating a new ward profile.

| Step | Purpose |
| --- | --- |
| 1. Ownership | Choose **Me** or **Someone I care for**. Ward profiles require a relationship selection. |
| 2. Consent and privacy | Explain local storage, protected export/import, deletion, separate caregiver-owned profiles, and the non-diagnostic boundary. |
| 3. Basics | Add only the essentials the user is comfortable recording, including a display name and optional basics. |
| 4. Curve details | Optionally record known Cobb angles, curve type, Risser or Lenke information, and related details from a clinic visit or report. |
| 5. Care routine | Optionally record brace and physiotherapy context. The copy makes clear that this does not replace a clinician’s plan. |
| 6. Goals | Choose the areas the user wants to track, such as pain, brace hours, physiotherapy consistency, surgery preparation, progression conversations, or exploration. |

A ward profile is a separate local care subject. When ownership changes from self to ward during setup, the app discards previously entered health fields instead of allowing a caregiver’s health data to leak into the ward profile. The owner can later switch between care spaces from **Me**.

Profile completion saves both structured profile data and a runtime display profile. A profile-completed event is recorded once for the care subject, without XP, so initial setup does not artificially start the user at a higher level.

### 3.3 Today

**Today** is the daily action surface. It is intentionally short and action-oriented rather than an activity archive.

The page includes the current date and greeting, the active profile avatar, a daily check-in card, the active routine entry, a compact streak/XP progress area, the current level card, and the next appointment card. The routine entry opens a bottom sheet rather than adding a long exercise list to the main scroll.

The daily check-in records a journal-style event with the information selected by the user. Saving the check-in refreshes the snapshot and shows the restrained action-reward feedback component.

The routine flow supports the following actions:

1. Open **Today** and tap the active routine.
2. Review the routine’s exercises in the sheet.
3. Expand an exercise to read its description and safety label.
4. Start the guided flow.
5. Move through step-by-step instructions with optional timers, pause/resume, previous, next, and finish-early controls.
6. Mark the exercise complete, record the event locally, and receive the relevant XP feedback.

The user can edit or replace the active routine through the routine library. Exercise cards are not medical prescriptions; their copy consistently advises a comfortable range and stopping when pain or feeling unwell occurs.

### 3.4 My Journey

**My Journey** is the local record-review surface. It shows the user’s recorded Cobb-angle history in a modern chart with an adaptive number of date labels, exact-date tooltips, selectable time ranges, and optional contextual overlays for pain or completed stretches. Pain and activity context are not displayed as if they were measurements on the same clinical scale as a Cobb angle.

The page also provides a privacy reminder, a compact recent-records preview, and access to full activity history. An expandable action button allows the user to log a Cobb angle or schedule a visit. Records are presented as observations and conversation aids; the chart does not calculate or predict curve progression.

### 3.5 Learn

**Learn** combines local educational topics with source-linked external content. Its main sections are **Topics**, **Articles**, **Videos**, and **Saved**. Search and category chips help users narrow the content without forcing a single linear reading path.

The Topics section contains source-linked topic guides and contextual help. The reusable question-mark help pattern can show a short explanation first and provide a **Learn more** action for a fuller bottom sheet or detail view. This pattern is used for complex profile or care concepts where a short label alone would not be sufficient.

Articles and videos are represented by `ExternalContentItem` records. A card displays the content kind, source, title, summary, category, save state, and—when applicable—routine inclusion state. The detail page provides source information, safety framing, and a link to the original source.

For curated article entries, SpineUp renders a readable in-app brief with key points, sections, estimated reading time, review date, limitations, and a link to the original source. RSS-discovered entries are presented as source-linked summaries and open the original article rather than pretending that the full third-party article has been copied into the app.

YouTube items with a recognized video ID can play in the detail page through an embedded player with controls, fullscreen support, captions, and privacy-enhanced mode. The original video source remains available as a separate action. Exercise videos can be saved and added to **My Routine**; inclusion also saves the item for the active care subject.

### 3.6 Me

**Me** is the active care-space and personalisation surface. It shows the active subject’s identity, avatar, level and XP, care-profile summary, progress and milestones, and navigation to related management actions.

The user can edit the active profile, add or switch a ward profile, open Avatar Studio, and enter Settings. The profile summary separates structured care information from the lightweight runtime display profile so that a decorative avatar choice is not confused with clinical data.

### 3.7 Avatar Studio

Avatar Studio is fully local. It supports three curated DiceBear-based illustrated styles: Open Peeps, Croodles, and Line Face/Lorelei Neutral. Each style exposes a controlled set of options with a maximum of five choices per supported feature, and the randomize action respects the current style rather than silently changing it.

Users can switch between an illustrated avatar and a locally selected photo. The photo path is stored as local runtime state; it is not embedded in the protected archive payload. The archive preview reports omitted attachments so the user is not led to believe that the photo itself has been exported.

Avatar selections are stored per care subject and included in the profile’s runtime metadata for protected archive transfer where appropriate. Avatar Studio contains local license credits for the open-source avatar packages.

### 3.8 Settings

Settings is grouped into four areas:

| Group | Current responsibilities |
| --- | --- |
| **Preferences** | Appearance mode and the Android daily reminder. |
| **Help and guidance** | Replay the page-aware quick tour and view About information. |
| **Privacy and portability** | Explain local storage, export a protected archive, inspect an archive before import, and import using explicit mode selection. |
| **Danger zone** | Delete all local data belonging to the current owner after confirmation. |

The reminder is Android-only and local. The user chooses a time, Android notification permission is requested when needed, and the schedule is stored and rescheduled locally. The reminder is a quiet prompt rather than a clinical adherence alarm.

## 4. Application architecture

SpineUp uses a deliberately small Flutter architecture rather than a large state-management framework. Widgets compose the user experience; services centralise persistence and domain rules; models provide serializable structures; the database helper owns SQLite access.

```text
lib/
├── main.dart                         App bootstrap, theme, top-level routes
├── data/
│   └── database_helper.dart           SQLite connection, schema, queries, migrations
├── models/                            Plain domain and serialization models
├── screens/                           User-facing routes and feature composition
│   ├── profile_setup/                 Six-step profile setup and reusable steps
│   └── ...                            Today, Journey, Learn, Me, Settings, media flows
├── services/                          Persistence, sessions, routines, archives, reminders
├── theme/                             Theme, transitions, edge-to-edge helpers
└── widgets/                           Shared navigation, avatars, tours, feedback, art
```

### 4.1 Startup and routing

`SpineUpApp` creates the `MaterialApp`, configures light/dark themes, keeps the cream canvas behind route transitions, and starts at `SplashScreen`. The splash checks local care-subject state and routes either to onboarding or the main navigation shell. The current session layer is provider-ready but intentionally local/mock; no external identity provider is wired into the app.

`NavigationShell` provides the active four-tab experience: Today, My Journey, Learn, and Me. It keeps a per-subject tutorial registry, switches the active care subject through `SessionService`, and restores a pending external-content return when Android activity recreation occurs.

### 4.2 Service responsibilities

| Service | Responsibility |
| --- | --- |
| `SessionService` | Holds the current local owner, active care subject, display name, and active-subject notifier. Enforces that a subject belongs to the current owner. |
| `DatabaseHelper` | Opens `spineup.db`, creates and upgrades SQLite tables, scopes records, and provides event/profile/appointment/care-subject queries. |
| `ProfileStore` | Reads and writes structured `ProfileData` JSON for a care subject. |
| `ProfileMapper` | Maps structured setup data to care-subject rows and runtime display-profile fields. |
| `GamificationService` | Logs events, calculates XP, levels, streaks, milestones, and runtime profile snapshots. |
| `RoutineService` | Stores the active routine per owner and care subject and provides the built-in exercise catalog/templates. |
| `ExternalContentService` | Loads curated content, refreshes RSS feeds, caches feed items, stores saved content, and stores routine-video selections. |
| `PortableArchiveService` | Creates, previews, decrypts, validates, and imports protected owner-scoped archives. |
| `ReminderService` | Stores and schedules one owner-scoped Android daily reminder with timezone-aware local notifications. |
| `QuickTourService` | Tracks page-guide completion in local preferences and drives page-aware focus overlays. |

## 5. Local data model

### 5.1 SQLite database

The database is created at the platform database path as `spineup.db`. The current schema version is **6**. Migrations preserve older single-user data by creating a self care subject for the historic owner identifier before the current multi-subject flow is used.

| Table | Scope and purpose | Important fields |
| --- | --- | --- |
| `care_subjects` | Owner-scoped self and ward profiles | `id`, `owner_user_id`, `subject_type`, `display_name`, `relationship`, timestamps |
| `events` | Timeline records and XP-bearing actions | `id`, `user_id` (care-subject ID), `type`, `timestamp`, JSON `payload`, `xp_value` |
| `user_profiles` | Runtime profile and avatar display state | `user_id`, preset, optional photo path, display name, diagnosis text, brace status, age range, avatar style/options/seed/mode |
| `appointments` | Scheduled or attended visit records | `id`, `user_id`, title, scheduled date/time, notes, status, completed event ID |

The event enum currently includes `stretchCompleted`, `journalEntry`, `appointmentAttended`, `angleLogged`, and `profileCompleted`. The user-facing app treats the `user_id` column as the active **care-subject ID**, not as a claim that a cloud account exists.

### 5.2 SharedPreferences

SharedPreferences is used for small local settings and indexes rather than the main timeline database. Current keys cover the selected active subject, active routine, cached external content, saved content IDs, routine-video IDs, pending external-content return IDs, reminder settings, page-tour completion, and appearance preferences.

Routines and saved content are scoped by both the local owner and active care subject. This prevents switching to a ward profile from showing the caregiver’s saved videos or active routine.

### 5.3 Attachments

A custom avatar photo is selected from the device and referenced by local path. The protected archive intentionally omits photo attachments. The export preview exposes omitted attachments so the user can make an informed portability decision.

## 6. Privacy, ownership, and portability

### 6.1 No-account operating model

The shipped product direction does not require sign-up, sign-in, cloud sync, analytics, or a hosted backend. `SessionService` currently supplies one local development session and keeps the owner/subject boundary in one place so a future identity provider would not require every screen to invent its own identity state.

This means that uninstalling the app, clearing app data, or losing the device can remove access to local records unless the user has made and safely retained a protected export. The app cannot recover a forgotten archive passphrase.

### 6.2 Care-subject isolation

A session owner may have a self profile and one or more ward profiles. All event, appointment, profile, routine, saved-content, and reminder access is intended to use the active care-subject scope. Database operations validate owner membership before activating, clearing, deleting, or replacing a subject.

Account-wide deletion clears the owner’s records, runtime profiles, appointments, and care-subject rows inside a transaction. Deleting a ward profile removes that ward’s records while retaining the owner’s other care spaces. The UI requires confirmation before destructive operations.

### 6.3 Protected archives

`PortableArchiveService` exports an owner’s care subjects, structured profiles, runtime profiles, events, and appointments as an authenticated encrypted envelope. The current format is:

| Property | Current value |
| --- | --- |
| Archive format | `spineup.protected-archive` |
| Schema version | `1` |
| Encryption | AES-256-GCM |
| Password-based key derivation | Argon2id |
| Payload | UTF-8, indented JSON after successful decryption |
| Minimum passphrase | 12 characters |
| Attachments | Local custom photo paths are omitted |

Import supports two explicit modes. **Separate subjects** creates new local IDs and refuses to silently merge an archived self profile with an existing local self profile. **Replace selected subject** requires exactly one archived profile and a user-selected local target, then clears that target’s records before restoring the archive. Import validates the passphrase and envelope before writing data.

The archive is designed to be human-readable after correct decryption, but its ciphertext and authenticated envelope do not expose health data without the passphrase. The passphrase is never recoverable by SpineUp.

## 7. External content and network boundaries

The application has an optional network path for Learn content and external media. The main local record experience does not depend on a remote account or cloud database.

On Android, the current `INTERNET` permission is declared in the debug and profile manifest variants, but not in `android/app/src/main/AndroidManifest.xml`. Because release builds use the main manifest, a release artifact may not be able to refresh RSS feeds, load thumbnails, open source pages, or play YouTube until the permission is added to the main manifest. This permission would only enable the already-designed optional external-content requests; it would not introduce cloud sync, accounts, or analytics.

### 7.1 RSS sources

The refresh path currently requests these RSS endpoints:

| Source label in the app | Feed URL | Category |
| --- | --- | --- |
| MedlinePlus · Scoliosis | `https://medlineplus.gov/feeds/topics/scoliosis.xml` | Scoliosis education |
| MedlinePlus · Spine | `https://medlineplus.gov/feeds/topics/spineinjuriesanddisorders.xml` | Spine and back |
| MedlinePlus · Back pain | `https://medlineplus.gov/feeds/topics/backpain.xml` | Pain and movement |
| Patient.info · Health guides | `https://patient.info/health/rss` | Health guides |
| Patient.info · Wellbeing | `https://patient.info/rss` | Mindfulness and wellbeing |

The service requests up to 20 items per feed, strips basic markup from descriptions, filters for relevant keywords, assigns a stable ID derived from the source URL, and caches at most 60 fetched items locally. Feed failure is intentionally non-fatal: curated content remains available when a source is offline, blocked, malformed, or unavailable.

### 7.2 Curated source-linked content

Curated content is compiled into the app as source-linked briefs or video references. The current set includes scoliosis education, posture, movement, back discomfort, mindfulness, breathing, sleep, mental wellbeing, and general activity. Each item carries a source URL, safety label, category, and, for reading briefs, key takeaways, sections, limitations, estimated reading time, and review date.

Curated briefs are not presented as full copies of the linked external pages. The detail view labels them as SpineUp reading briefs and keeps the original source action visible.

### 7.3 YouTube and external pages

Recognized YouTube items use `youtube_player_iframe` for embedded playback. A privacy-enhanced player is configured with controls, captions, and fullscreen support. Other external pages are opened through an in-app browser view when available, with a fallback to an external application. A pending-return marker lets the shell restore the user to the relevant SpineUp detail page after Android activity recreation.

The content layer is deliberately source-transparent. Users can see the source name, open the original link, select and copy the URL, and review the item’s safety boundary.

## 8. Motivation and XP rules

Gamification exists to make a repetitive self-management routine easier to return to, not to grade symptoms or reward a clinical result.

| Event | Base XP |
| --- | ---: |
| Completed stretch/exercise | 30 |
| Journal/check-in entry | 25 |
| Cobb-angle log | 50 |
| Appointment attended/recorded | 40 |
| Profile completion | 0 |
| First non-profile event of the calendar day | +5 daily bonus |

The current daily target shown in the UI is 600 XP. Cobb-angle logging awards base XP only once per calendar day; subsequent angle logs that day are still recorded but do not award additional angle XP. A level starts at 100 XP and the next level threshold increases by 25 XP per level. The streak counts consecutive calendar days ending today or yesterday on which the active care subject has at least one event.

The XP overlay is deliberately compact and action-specific. It reports what was completed and the XP awarded rather than covering the entire screen with a celebration. Milestones can unlock from XP thresholds, event counts, or streak lengths.

## 9. Notifications and reminders

Reminders are Android-only because the current notification implementation uses `flutter_local_notifications`, Android notification permission, boot receivers, vibration, and timezone-aware local scheduling. The user enables one daily reminder, chooses its time, and can change or disable it from Settings.

The reminder title is **A small care moment**. It is not a treatment adherence instruction and does not transmit data to a server. Users must allow Android notifications for the schedule to become active.

## 10. Design and accessibility direction

SpineUp’s visual system is intentionally warm, expressive, and calm. The primary visual language uses cream canvases, sage primary actions, coral active states, lavender supporting accents, rounded cards, hand-drawn separators, and a branded loop-and-dot mark. The design avoids cold clinical dashboards, excessive texture, dense statistics, and childish competition mechanics.

The application includes reduced-motion checks for top-level transitions and uses semantic labels/tooltips for important controls. Page-aware tutorials use a dimmed overlay and a glow/focus treatment on the actual target widget rather than relying on inaccurate pointer arrows. Each of Today, My Journey, Learn, Me, and Settings has its own tutorial script and completion state.

The Web and Android surfaces share the SpineUp name, metadata, splash identity, favicon, PWA icons, adaptive launcher icon, and native launch background. The wordmark is omitted from tiny launcher/favicon assets because it would not remain legible at those dimensions.

## 11. Source map for maintainers

| Concern | Primary implementation files |
| --- | --- |
| App bootstrap and routes | `lib/main.dart`, `lib/screens/splash_screen.dart` |
| Main navigation | `lib/screens/navigation_shell.dart`, `lib/widgets/glass_nav_bar.dart` |
| First-run onboarding | `lib/screens/onboarding_screen.dart`, `lib/screens/local_first_welcome_screen.dart` |
| Profile setup | `lib/screens/profile_setup/profile_setup_screen.dart`, `lib/screens/profile_setup/steps/` |
| Today and exercise flow | `lib/screens/today_screen.dart`, `lib/screens/daily_check_in_screen.dart`, `lib/services/routine_service.dart` |
| Journey and charts | `lib/screens/my_journey_screen.dart`, `lib/screens/activity_history_screen.dart` |
| Learn and external media | `lib/screens/learn_screen.dart`, `lib/screens/external_content_screen.dart`, `lib/services/external_content_service.dart` |
| Me and avatars | `lib/screens/me_screen.dart`, `lib/screens/avatar_studio_screen.dart`, `lib/widgets/dicebear_avatar.dart` |
| Settings and portability | `lib/screens/settings_screen.dart`, `lib/widgets/portable_archive_dialogs.dart`, `lib/services/portable_archive_service.dart` |
| Storage and ownership | `lib/data/database_helper.dart`, `lib/services/session_service.dart`, `lib/services/profile_store.dart`, `lib/models/care_subject.dart` |
| XP and milestones | `lib/services/gamification_service.dart`, `lib/models/milestone.dart`, `lib/widgets/action_reward_feedback.dart` |
| Reminders | `lib/services/reminder_service.dart`, `android/app/src/main/AndroidManifest.xml` |
| Theme and motion | `lib/theme/app_theme.dart`, `lib/theme/app_transitions.dart`, `lib/widgets/m3_squiggly_line.dart` |
| Branding | `assets/branding/spineup_mark.svg`, `lib/screens/splash_screen.dart`, `android/app/src/main/res/`, `web/` |

## 12. Development and validation

The project is managed with Flutter and Dart. The repository’s CI workflow currently uses Flutter **3.44.9 stable** and resolves dependencies with `flutter pub get`. The package environment declares Dart `^3.12.2`.

The standard local validation sequence is:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions runs a changed-Dart-files formatting check, full Flutter analysis, the complete Flutter test suite, and an Android debug APK build. The workflow is defined in `.github/workflows/flutter_quality.yml` and has a 20-minute job timeout.

The test suite covers local-first boundaries, database behavior, profile validation and setup, onboarding, Today additions, routines, external-content models, Learn, Journey, Settings, reminders, portable archives, splash routing, navigation, gamification, reward feedback, and favicon generation. These are widget and unit tests; a real Android device check is still valuable for launcher masking, notification behavior, WebView/source return, keyboard insets, and platform-specific media playback.

## 13. Current release posture and known limitations

SpineUp is a strong school-project build and a coherent local-first prototype, but the icon merge should not be interpreted as full F-Droid release readiness.

| Area | Current state |
| --- | --- |
| Android app identity | The application ID is still `com.example.spineup`, a placeholder that should be replaced before a public release. |
| Release signing | `android/app/build.gradle.kts` currently signs the `release` build type with the debug signing configuration. This is suitable for local release-mode testing, not for distributing an official signed release. |
| License | A recognized open-source `LICENSE` file still needs to be added and confirmed before public distribution. |
| F-Droid metadata | Repository metadata, screenshots, version tags, dependency/license review, and an isolated F-Droid build still need to be prepared. |
| Device QA | Real-device testing remains recommended for notifications, launcher masks, external media, and Android activity recreation. |
| Cloud and accounts | Deliberately not implemented. This is a product constraint, not a missing defect for the current local-first direction. |
| Community | Deliberately hidden from active navigation and deferred. |
| iOS | Not part of the current scope. |

The practical next public-release work is packaging and governance rather than adding another broad product surface: choose a permanent application ID, add the project license, set up a real release-signing process, audit dependency licenses, prepare screenshots and metadata, and test a clean source build.

## 14. Maintainer checklist

Before changing a feature, identify its active care-subject scope. Screens should use `SessionService.currentCareSubjectId` for health records and should not invent a second identity source. New persistent fields require a model serialization update, SQLite migration where applicable, protected-archive consideration, and tests for both a fresh database and an upgraded database.

Before adding external content, keep the source URL visible, retain a safety label, decide whether the item is an RSS discovery or a curated brief, and provide a graceful offline/failure path. Before adding notifications, keep the behavior local, owner-scoped, permission-aware, and testable without assuming that a notification permission has already been granted.

Before publishing a build, increment the version in `pubspec.yaml`, confirm the Android package identity, use a protected signing key, run the full validation sequence, install the artifact on a clean test device, and retain the exact source commit and build number used for the artifact.

## References

[1]: https://docs.flutter.dev/deployment/android "Flutter: Build and release an Android app"
[2]: https://developer.android.com/studio/publish/app-signing "Android Developers: Sign your app"
[3]: https://docs.flutter.dev/get-started/install "Flutter: Install Flutter"
[4]: https://docs.flutter.dev/testing/overview "Flutter: Testing Flutter apps"
