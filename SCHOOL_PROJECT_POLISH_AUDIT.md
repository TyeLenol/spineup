# School-Project Polish Audit

## Scope

The immediate goal is a polished, reliable Android/Web school-project demonstration. iOS work, future content governance, advanced portability hardening, Community backend work, cloud sync, and real authentication are deferred. Community remains Coming Soon.

## Initial findings

| Area | Finding | Priority | Proposed direction |
|---|---|---:|---|
| Active care-subject switching | `NavigationShell` keeps Today, Journey, Learn, and Me in a static const screen list. `TodayScreen` and `MyJourneyScreen` are kept alive, while `SessionService.activeCareSubjectNotifier` only rebuilds the visible indicator. After switching subjects in Me, Today/Journey can retain the previous subject’s loaded data until their state is recreated. | High | Make subject-aware screens refresh when the active-subject notifier changes, preferably through a shell-level subject key/rebuild or a small subject-aware refresh mixin/listener. Preserve navigation state only where it is safe. |
| Navigation layout | `GlassNavigationBar` uses a fixed bottom margin of 24 rather than a SafeArea-aware layout. Main screens add bottom padding, but the bar itself should be checked on Android gesture/navigation-bar layouts and narrow Web viewports. | Medium | Validate with Android/Web screenshots; adjust only if clipping or overlap is observed. |
| Local toolchain | The sandbox has Dart 3.12.2 but no `flutter` executable. Formatting is available locally; analyzer and widget tests must be validated through the pinned GitHub Flutter workflow unless Flutter is installed separately. | Informational | Use remote CI for final Flutter validation and avoid claiming local Flutter execution. |

## Demo-critical flow checklist

1. First launch and onboarding completion.
2. Profile setup beginning with “Who is this for?” and completion for Me.
3. Today: check-in, exercise completion, XP/streak update, appointment card, empty states, and refresh.
4. Journey: recorded measurements and non-diagnostic wording.
5. Learn: search, categories, topic detail, sources, and contextual `?` help.
6. Me: profile display/editing, care-subject switching/add-ward flow, protected export/import entry points, and settings.
7. Community remains clearly marked Coming Soon.
8. Navigation and active-subject changes do not show stale data or overflow on Android/Web.

## Implemented reliability fix

The navigation shell now keys Today, Journey, and Me by the active care-subject ID inside a `ValueListenableBuilder`. When `SessionService.setActiveCareSubject` changes the notifier, the subject-scoped screens are recreated and reload their records instead of retaining the previous subject’s kept-alive state. Learn remains shared because its content is not subject-scoped. A widget regression test verifies that Today receives a different key after switching to a ward profile.

The change is intentionally narrow: it does not alter the care-subject data model, persistence, deletion rules, or portability behavior. It fixes the presentation/data freshness boundary where those completed features meet the four-tab navigation shell.
