# SpineUp Protected Local Archive Portability

## Milestone status

The protected local archive portability milestone is complete on the `stabilize/architecture-and-critical-fixes` branch. The implementation preserves SpineUp’s private, local-first posture while giving users an explicit way to move their own records between devices. No cloud synchronization, remote backup, analytics, real authentication, or Community backend was introduced.

| Item | Result |
|---|---|
| Feature commit | `6714916` — `feat: add protected local archive portability` |
| Follow-up fix | `eb5d763` — `fix: resolve portability analyzer issues` |
| Branch | `stabilize/architecture-and-critical-fixes` |
| Validation workflow | [Flutter quality run 31648057601](https://github.com/TyeLenol/spineup/actions/runs/31648057601) |
| Remote result | **Success** — dependency resolution, formatting, analyzer, and tests all passed |
| Working tree | Clean after the follow-up commit |

## Why this change was necessary

A private local-first health app still needs a trustworthy answer to the phone-change problem. Users should not be forced into cloud storage merely to preserve their own records, but an unprotected raw database export would expose sensitive information and would be difficult to validate safely during import. The portability feature therefore treats export as a user-initiated, passphrase-protected archive operation rather than as synchronization.

> SpineUp exports and imports only when the user explicitly chooses those actions. The app does not upload the archive or silently reconcile it with local data.

## Archive and cryptography design

`PortableArchiveService` creates a human-readable UTF-8 JSON payload and places it inside an authenticated encrypted envelope. The payload contains a stable format/schema version, export timestamp, owner metadata, care subjects, subject-scoped structured profiles, events, appointments, runtime profile summaries, export scope, and an explicit attachment manifest. The outer envelope records the KDF and cipher metadata needed to derive the key and authenticate the payload during import.

| Boundary | Implemented behavior | Reason |
|---|---|---|
| Key derivation | Argon2id with a per-archive random salt | Makes passphrase-derived keys substantially harder to brute-force than a direct hash and avoids reusing a key across exports |
| Encryption | AES-256-GCM with authenticated `SecretBox` output | Protects confidentiality and detects archive tampering before preview or import |
| Archive format | JSON envelope containing base64url-encoded salt, nonce, MAC, and ciphertext | Keeps the file inspectable as a format while ensuring the actual record payload remains protected |
| Passphrase policy | Minimum 12 characters; confirmation required for export | Reduces accidental weak-passphrase use and makes the unrecoverable-passphrase rule visible to the user |
| Failure behavior | Wrong passphrase or modified archive raises a portability error | Prevents untrusted or unauthenticated records from being shown as a valid preview |

The service deliberately does not claim device-level encryption, forensic protection, cloud backup, or passphrase recovery. A strong passphrase remains the user’s responsibility. Before a production release, the KDF parameters, platform implementations, archive-size limits, memory handling, and attachment policy should receive a dedicated security review.

## Import safety and subject isolation

Import is a two-stage operation. The archive is first authenticated and decrypted, then a preview shows the creation time, schema version, subject names and types, record counts, and omitted attachment categories. Nothing is written during preview. The user must then choose an explicit import mode.

| Import mode | Behavior | Safety rationale |
|---|---|---|
| Import as separate subjects | Creates new owner-scoped subject records and remaps imported subject IDs; event, appointment, and profile references follow the remapping | Preserves the existing local records and avoids identifier collisions across devices |
| Replace selected local subject | Available only for a single-subject archive; requires a second confirmation naming the selected subject and deleting only its records before import | Provides a controlled restore path without deleting other care subjects owned by the user |
| Silent merge | Not available | Prevents ambiguous conflict resolution and accidental mixing of records |

The export is owner-scoped through the current session owner and includes all subjects belonging to that owner. Records remain subject-scoped in SQLite. Separate-subject imports generate fresh IDs, while the original IDs are retained only as import metadata for auditability. Replace mode uses a records-only deletion boundary so the selected subject identity can remain stable while its events, appointments, profile rows, and subject-scoped profile data are replaced.

## User-facing workflow

The Me screen now exposes **Export protected archive** and **Import protected archive** actions. Export requests and confirms a passphrase, serializes the owner’s local data, and opens the platform file-save boundary with a `.spineup` filename. Import opens the platform file picker, requests the passphrase, blocks until authentication succeeds, presents the preview, and requires the user to select a non-silent mode. Replace mode presents an additional destructive confirmation before records are cleared.

The dialogs explain that SpineUp cannot recover a forgotten passphrase, that archive data is not imported until authentication succeeds, what the preview counts represent, which attachments were omitted, and why importing as separate profiles or replacing a selected profile are different choices. The export success path also accounts for Web’s browser-download behavior, where the file-picker API returns no filesystem path even though the download has been initiated.

## Data coverage and limitations

Appointments now have explicit JSON serialization and deserialization so they can travel with the event ledger and structured profiles. Attachments are represented by an explicit omitted/unavailable manifest rather than by copying raw device paths, because paths are not portable and could disclose more than the user intended. The archive does not include credentials, tokens, or remote-service data.

| Included | Explicitly not included |
|---|---|
| Care-subject identity, type, display name, relationship, and timestamps | Passwords, authentication tokens, or cloud credentials |
| Subject-scoped `ProfileData` and runtime profile summaries | Cloud state or server-side synchronization metadata |
| Subject-scoped events and appointments | Raw attachment files and device-specific absolute paths |
| Export scope, counts, format/schema metadata, and creation time | Clinical diagnoses, predictions, or treatment recommendations generated by SpineUp |

## Regression coverage and CI correction

The portability regression suite verifies protected export and preview counts, rejection of a wrong passphrase, remapped IDs for separate-subject import, subject/event preservation, and refusal to create a second self profile through a silent-looking separate import. The first remote run identified three analyzer issues and one informational lint issue. They were fixed in a separate follow-up commit rather than being mixed into the feature commit.

| Diagnostic | Modification | Reason |
|---|---|---|
| `_loadAll` called from `_SettingsSectionState` | Added an optional `onDataChanged` callback to `_SettingsSection`, passed `_MeScreenState._loadAll`, and invoked the callback after import | Keeps reload responsibility in the parent state that owns the data while allowing the settings child to notify it |
| `CareSubjectType` unresolved in archive dialog | Imported `profile_data.dart`, the canonical declaration site of `CareSubjectType` | Avoids duplicating the enum and fixes Dart’s non-transitive import behavior |
| Redundant `sqflite` test import | Removed the direct import | The test already receives the required database API from `sqflite_common_ffi` |
| `use_build_context_synchronously` info | Added a `mounted` guard after the asynchronous file-picking step | Prevents use of a disposed widget’s context after the async gap |

The successful remote workflow confirms that dependency resolution for `cryptography_plus` and `file_picker`, formatting, Dart/Flutter analysis, and the complete test suite all pass on the pinned Flutter toolchain. The local patch also passed `git diff --check` before each commit.

## Product and safety alignment

This milestone supports the approved product decisions: private by default, local-first storage, user-controlled portability, strict care-subject isolation, truthful limitations, and non-diagnostic behavior. It does not change the Community tab’s gated status, add analytics, or introduce any backend that would alter the app’s privacy model.

The next recommended milestone is **appointment preparation**: structured pre-visit questions, concise symptom and recorded-measurement summaries for the active care subject, and a visit-ready view that clearly distinguishes user-entered records from clinical interpretation.

## Files changed

The implementation is centered in `lib/services/portable_archive_service.dart`, `lib/widgets/portable_archive_dialogs.dart`, and `lib/screens/me_screen.dart`. Supporting changes add appointment JSON support in `lib/models/appointment.dart`, a records-only replacement boundary in `lib/data/database_helper.dart`, dependencies in `pubspec.yaml`, and regression coverage in `test/portable_archive_service_test.dart`. The design rationale remains documented in `PORTABILITY_IMPLEMENTATION_NOTES.md`.
