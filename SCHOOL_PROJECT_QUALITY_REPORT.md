# SpineUp School-Project Quality Pass

## Final scope

SpineUp is now being treated as a **polished Android/Web school-project demonstration**, not as a production healthcare platform. The current objective is that the completed app looks coherent, feels dependable during a demo, and keeps its privacy and non-diagnostic boundaries clear.

| In scope now | Deferred unless time remains |
|---|---|
| Android and Web behavior | iOS work |
| Today, Journey, Learn, Me, onboarding, care-subject switching, and local archive flows | West Africa-specific content and localization expansion |
| Visual consistency, reliable loading, correct subject-scoped data, navigation, empty states, and CI-green code | Advanced portability hardening and formal security review |
| Community shown as Coming Soon | Community backend, moderation operations, and live social features |
| Local-first storage and user-initiated export/import | Cloud sync and real authentication |

This scope is appropriate for a school project because it prioritizes a strong, demonstrable product experience over future infrastructure that is not necessary for the project evaluation.

## Reliability issue found and fixed

The audit found one important data-freshness problem in the completed care-subject manager. The navigation shell kept Today and Journey alive in memory, while switching the active care subject only refreshed the small profile indicator. That meant a user could switch from their own profile to a ward and briefly continue seeing the previous subject’s loaded Today or Journey data.

> The fix makes subject changes behave as users expect: selecting a different care profile recreates the subject-scoped screens and reloads their records.

The navigation shell now listens to `SessionService.activeCareSubjectNotifier` and gives Today, Journey, and Me keys containing the active subject ID. When the active subject changes, Flutter receives new subject-scoped screen instances. Learn remains shared because its library content is not tied to one care subject. The data model, SQLite isolation, active-subject persistence, deletion rules, and portability service were not changed by this fix.

A widget regression test was added to prove that Today receives a different key after the active subject changes. This protects the exact bug boundary that a school-project demo could otherwise expose.

| Change | Reason |
|---|---|
| Subject-keyed screen instances in `NavigationShell` | Prevent stale subject data after profile switching |
| `ValueListenableBuilder` around the animated screen area | Rebuild the screen child when the active-subject notifier changes while retaining the existing transition design |
| New navigation widget regression test | Prevent the stale-data bug from returning |
| Dedicated audit and quality reports | Make the project’s design choices and validation evidence easy to explain during review |

## What has been validated

The polish work is on the dedicated branch `polish/school-project-quality`, based on the previously green stabilization branch. The final branch head is `9c4e75c`, and the working tree is clean. The final workflow completed successfully in [Flutter quality run 31652342444](https://github.com/TyeLenol/spineup/actions/runs/31652342444).

| Validation step | Result |
|---|---|
| Dependency resolution on pinned Flutter 3.44.9 | Passed |
| Changed Dart-file formatting | Passed |
| Dart and Flutter analyzer | Passed |
| Complete automated test suite | Passed |
| `git diff --check` before commits | Passed |
| Subject-switch regression coverage | Added and passed in the complete test run |

The sandbox used for this work contains the Dart formatter but not the Flutter executable, so the authoritative analyzer and widget-test result comes from the repository’s pinned GitHub workflow rather than a local Flutter invocation. This is why the report claims CI validation, not a local emulator screenshot pass.

## Demonstration path

For a strong school-project presentation, the recommended path is to start with onboarding, complete the “Who is this for?” profile setup, and land on Today. From there, demonstrate a daily check-in, one routine item, the XP/streak feedback, and the appointment card. Open Journey to show that the chart is titled **Your Recorded Measurements** and avoids clinical progression claims. Open Learn to demonstrate search, categories, source-aware topic details, and a contextual `?` help modal.

Finish in Me by showing the active profile indicator, opening the profile manager, switching to a ward, and returning to Today. The key behavior to demonstrate is that the active profile name and subject-scoped records change together. The export/import controls can be shown as a user-controlled local feature, while Community should remain visibly labeled Coming Soon.

## Remaining work for this project

The core implementation is in a good state for the school-project target. The remaining work is primarily **manual presentation validation**, not another architecture milestone. On an Android device/emulator and a Web viewport, the app should be checked for keyboard behavior during onboarding, narrow-width layout, bottom navigation clearance, scrolling to the last card, dialogs, empty states, and subject-switch transitions. Any issues found there should be fixed as small polish patches and re-run through CI.

If extra time remains after that manual pass, the best optional additions are a small amount of Ghana/West Africa-aware copy or examples and further visual refinement. Cloud sync, live Community, iOS, advanced security review, formal content governance, and production authentication should remain outside the school-project finish line.

## Source and validation links

The repository documentation remains the source of truth for the broader product decisions and the protected archive design. The quality evidence is the successful workflow linked above.

## References

[1]: https://github.com/TyeLenol/spineup/actions/runs/31652342444 "SpineUp Flutter quality workflow run 31652342444"
[2]: https://github.com/TyeLenol/spineup/tree/polish/school-project-quality "SpineUp school-project-quality branch"
