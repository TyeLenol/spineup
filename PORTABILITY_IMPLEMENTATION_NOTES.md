# SpineUp Portability Implementation Notes

## Design basis

The portability workflow should use a human-readable canonical JSON manifest inside a protected binary envelope. The archive must carry a version, schema identifier, creation time, source owner metadata, care subjects, structured profile data, runtime SQLite records, and an explicit manifest of included and omitted content. Import must decrypt and authenticate the envelope before showing any data preview. No import may silently merge into the current owner or active subject.

## Candidate libraries reviewed

| Library | URL | Relevant finding | Decision |
|---|---|---|---|
| `cryptography_plus` 3.0.0 | https://pub.dev/packages/cryptography_plus | Verified Dart/Flutter package with AES-GCM, ChaCha20-Poly1305, Argon2id, PBKDF2, hashing, and secure random support. Its documentation describes authenticated `SecretBox` output containing nonce, ciphertext, and MAC. It recommends Argon2id for password hashing and links OWASP mobile cryptography guidance. | Use authenticated encryption with a password-derived key. Prefer Argon2id where supported by the selected Flutter implementation; record KDF parameters and salt in the archive header. Never invent a custom cipher or XOR scheme. |
| `archive` 4.0.9 | https://pub.dev/packages/archive | Verified Dart package supporting Zip, Tar, ZLib, GZip, BZip2, and XZ. The package supports memory-only interfaces for web and file-oriented APIs for native platforms. | Do not use ZIP encryption as the security boundary. If a binary container is needed, encrypt the canonical manifest with authenticated encryption and treat compression as optional. A plain JSON payload is easier to preview conceptually, while the exported file remains protected. |
| `brendan-duncan/archive` | https://github.com/brendan-duncan/archive | Maintained open-source repository with Dart CI, MIT license, and support for common archive codecs. | Credited as the archive implementation reference if the dependency is adopted. |

## Proposed archive envelope

The first portable format should be a single file with a clear SpineUp extension, for example `.spineup`. Its outer JSON-like header should identify `format`, `formatVersion`, `kdf`, `cipher`, `salt`, `nonce`, `createdAt`, and an authenticated payload. The decrypted payload should be UTF-8 JSON with a stable schema version and explicit sections:

- `owner`: session-owner export metadata, never a password or authentication token.
- `careSubjects`: one record per subject, including subject ID remapping metadata, subject type, display name, relationship, structured `ProfileData`, and creation/update timestamps.
- `events`: event ledger records grouped by subject.
- `appointments`: appointments grouped by subject.
- `runtimeProfiles`: current avatar/profile summaries grouped by subject.
- `attachments`: an explicit manifest of included, omitted, or unavailable local file paths; raw device paths must not be trusted or silently copied across phones.
- `exportScope`: subject IDs and record counts included in this archive.

## Import rules

A wrong passphrase or modified archive must fail authentication before any data is previewed as trustworthy. A valid archive must first produce a preview containing owner metadata, subject names and types, record counts, archive creation time, schema version, and any omitted attachments. The user must explicitly choose a non-silent mode.

The initial safe modes should be **Import as separate subjects** and **Replace selected local subject after explicit confirmation**. Silent merge is prohibited. Separate-subject import remaps imported subject IDs while preserving an internal original-ID reference for auditability. Replace mode must require selecting exactly one existing subject and must show a destructive warning naming the subject and record counts. A future merge mode should not be added until conflict semantics are separately designed.

## Security limitations

The passphrase is not recoverable by SpineUp. The first implementation must not claim device-level encryption, cloud backup, or forensic protection. The archive is protected against casual disclosure and tampering when the passphrase is strong and the authenticated-encryption implementation is correct; it does not protect a passphrase that is shared or stored insecurely. A later security review should verify KDF parameters, platform implementation behavior, archive size limits, memory handling, and attachment policy before release.

## File transfer UX research

| Library | URL | Relevant finding | Decision |
|---|---|---|---|
| `file_picker` 11.0.3 | https://pub.dev/packages/file_picker | Verified Flutter package supporting Android, iOS, desktop, Web, and WebAssembly. It provides `pickFiles()` with in-memory bytes and `saveFile()` save-as dialogs on all listed platforms. | Use it as the file boundary for importing `.spineup` bytes and saving an exported archive. Keep archive parsing and cryptography in a service so UI and platform file selection stay separate. |
| `share_plus` 13.3.0 | https://pub.dev/packages/share_plus | Flutter Favorite with cross-platform share UI and file sharing. Web can use Web Share or download fallback; file sharing is supported on Android, iOS, macOS, Web, and Windows, but not Linux. | Treat sharing as an optional convenience after export, not the only portability route. The primary flow must remain explicit save/import through the file picker. |

The package pages were reviewed on 2026-08-12. Dependency versions must be resolved by the pinned Flutter CI workflow before release; this increment should not claim platform support until that workflow passes on the repository’s target toolchain.

The `file_picker` 11.0.3 API reference confirms `FilePicker.saveFile` accepts `Uint8List bytes` and a `fileName`. On mobile it saves the bytes and returns a path; on desktop it opens a save dialog and writes the bytes; on Web it starts a browser download and returns null. This makes it suitable for one cross-platform export action without requiring platform-specific file-writing code in the UI.
