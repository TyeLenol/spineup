# Stabilization Notes

## Baseline

The repository’s `main` and `gamified_tes` branches were verified at the same remote commit, `e14486c9934cae8e8879eff1634a0ac75616402a`. Work is being performed on `stabilize/architecture-and-critical-fixes`.

## Implemented batches

The first batch centralizes the prototype session identity, scopes structured profile storage and SQLite deletion by user, synchronizes onboarding into the runtime profile, routes signup and login differently, makes journal editing update an existing event, corrects milestone threshold calculations, guards appointment completion against wrong-user/cancelled/already-completed records, moves profile completion XP into the shared event ledger, and adds regression tests.

The second batch adds a Flutter quality workflow and iOS photo-library usage metadata. The workflow uses Flutter 3.44.9 because the project requires Dart `^3.12.2` and Flutter 3.44.0 shipped Dart 3.12.0 in the first run.

The first CI run failed at dependency resolution because Flutter 3.44.0 provided Dart 3.12.0. The second run resolved dependencies successfully but failed at the formatting step because the baseline contains unrelated formatting differences. The workflow was then changed to format only Dart files changed by the current push or pull request, while retaining a strict formatter exit code for those files. A third run for commit `a4ecdfd` was in progress at the time of this note.

The sandbox does not have Flutter or Dart installed, so local `flutter analyze` and `flutter test` cannot be executed. GitHub Actions is the validation environment.

## Important design decisions

`ProfileData` is treated as an onboarding DTO and `UserProfile` as the current runtime summary. `ProfileMapper` is the explicit adapter between them. Profile completion is represented by `EventType.profileCompleted` with `kXpProfileCompletion = 250`; the old profile-level XP field was removed so XP has one authoritative ledger.

## CI run findings

The first quality run was `https://github.com/TyeLenol/spineup/actions/runs/31628583224` on commit `8384871`; dependency resolution failed because Flutter 3.44.0 provided Dart 3.12.0 while the manifest requires Dart `^3.12.2`.

The second run was `https://github.com/TyeLenol/spineup/actions/runs/31628870391` on commit `8f3d1cf`; dependency resolution and formatting passed, but analyzer failed. The job metadata is available at `https://api.github.com/repos/TyeLenol/spineup/actions/jobs/94222227985`, and the check annotations at `https://api.github.com/repos/TyeLenol/spineup/check-runs/94222227985/annotations` only expose generic workflow annotations, not analyzer messages.

The third run is `https://github.com/TyeLenol/spineup/actions/runs/31629245697` on commit `a4ecdfd`; its job metadata is `https://api.github.com/repos/TyeLenol/spineup/actions/jobs/94223486524`. Dependency resolution and changed-file formatting passed; analyzer failed and tests were skipped. The analyzer check annotations are at `https://api.github.com/repos/TyeLenol/spineup/check-runs/94223486524/annotations`. Direct download of the signed job log was blocked by sandbox DNS resolution for `productionresultssa0.blob.core.windows.net`, so exact analyzer messages remain unavailable from this runtime.

The third CI run’s analyzer-stage failure was traced through the signed GitHub Actions log. The source code analyzer did not run: checkout cleanup failed because the repository contains a gitlink at `.reference` but no `.gitmodules` file, producing `fatal: No url found for submodule path '.reference' in .gitmodules`. Because `.reference` is not used by the Flutter app and its target repository is unknown, the stabilization branch removes this orphaned gitlink rather than inventing a submodule URL.

Run 4 (`https://github.com/TyeLenol/spineup/actions/runs/31629826768`) confirmed checkout cleanup is fixed. Analyzer then failed on one lint: `test/architecture_data_boundary_test.dart:2:8` imported `package:sqflite/sqflite.dart` unnecessarily because `sqflite_common_ffi` already exports the used database symbols. The redundant import has been removed locally.

Run 5 (`https://github.com/TyeLenol/spineup/actions/runs/31630160861`) reached the full test suite: 48 tests passed and one failed. The failing regression test correctly showed profile completion awarded 250 XP but `LogEventResult.dailyBonusAwarded` incorrectly reported `true` even when `includeDailyBonus: false`. The result metadata now uses the same gated condition as the XP calculation.
