# SpineUp Content, Routine, and First-Run Product Review

**Scope:** Correct the earlier screenshot interpretation, audit the newly uploaded onboarding/auth/profile screenshots, diagnose why Articles and Videos do not behave as users expect, and define a researched routine-library experience with selectable routines and guided video.

## 1. Corrections to the previous screenshot audit

The earlier report overcalled two visual issues. Based on the user’s clarification, the fixed bottom navigation is not covering content; the screenshots were captured before scrolling far enough. Likewise, the horizontal rows are not clipped in normal use; the screenshots simply did not show the full row. These should be removed from the P0 defect list.

| Previous observation | Corrected interpretation | Priority now |
|---|---|---:|
| Bottom navigation covers content | Not confirmed; the user had not scrolled to the lower content. | Remove as defect; retain as a QA check. |
| Horizontal chips/carousels are clipped | Not confirmed; the user did not capture the full horizontal row. | Remove as defect; retain as a QA check. |
| Old appointment/check-in values are current bugs | The screenshots show older persisted data or an older installed build. | Demo-data verification only. |
| Article/video play surface does nothing | Confirmed by the user and supported by the current implementation. | **P0.** |
| Every user receives the same routine | Confirmed by the current source: the exercise list is a static constant. | **P0.** |

The app’s visual identity is stronger than the first report implied. The highest-value work has shifted from general spacing polish to **content functionality, routine ownership, and first-run trust copy**.

## 2. Why Articles and Videos currently feel pointless

### Articles are not readable inside SpineUp

The current `ExternalContentItem` model stores an article title, summary, source URL, content URL, safety label, and metadata. RSS items are created from the feed title, description, and link. The detail page displays the summary and then exposes the raw source URL plus an **Open source** button. It does not fetch or render the article body inside the app. The current dependency list also contains no in-app browser or HTML/article renderer.

Therefore, the user’s criticism is correct: the Articles section currently functions as a **curated discovery/bookmark layer**, not an in-app reading experience. The point is currently to help users find trustworthy content, save it, and open the original source. That is not enough for the intended product experience.

### The NHS video placeholder is a dead interaction

The curated NHS Pilates item is stored as a video with `videoProvider: ExternalVideoProvider.web`, a source URL, and no YouTube `videoId`. In the detail page, items without a YouTube controller or thumbnail render `_ExternalMediaPlaceholder`, which is only a visual container with a play icon. It has no `onTap`, no button handler, and no `Open source` action attached to the placeholder itself. Clicking that play icon can therefore do nothing. This is the clearest explanation for the user’s report.

The correct behavior for a non-YouTube video should be one of the following:

1. Render an actionable **Watch on NHS source** button directly over the placeholder and in the action area.
2. Open the source in an in-app source reader/browser where supported.
3. If the source cannot be embedded, label the surface explicitly as **External video — opens the NHS source** rather than presenting a dead play control.

A dead play icon should never be shown.

### YouTube playback is also under-specified

For YouTube items, the current code creates a `YoutubePlayerController` and calls `cueVideoById`. The package documentation distinguishes cueing a video from initializing it for playback; its `fromVideoId` constructor exposes an explicit `autoPlay` option and the controller also provides load/play methods.[4] The current page does not add a custom play handler, a player-state error surface, a loading state, or a reliable fallback when the iframe cannot initialize.

The YouTube path should be corrected to:

- initialize from the video ID with an explicit `autoPlay: false` state;
- show a real thumbnail/loading surface before the iframe is ready;
- display the player’s controls and state clearly;
- listen for player errors and show a readable message;
- always provide **Open in YouTube** as a fallback; and
- never report that a video is “saved” or “ready” when the player has failed to load.

The likely immediate bug is the NHS web-video placeholder, but the YouTube path needs the same level of explicit state handling before it can be called finished.

## 3. What Articles and Videos should become

The intended experience should be a **source-aware reader and player**, not a list of links disguised as content.

### Article experience

For the Android demo, the most reliable near-term implementation is an in-app source reader that loads the original page inside a controlled reader surface, while retaining the original source name, safety notice, and an external fallback. This avoids copying entire copyrighted articles into the app and keeps the source authoritative.

For a more controlled long-term experience, curated articles can receive a SpineUp-authored reading body consisting of a short summary, selected key points, limitations, and source link. RSS-discovered items should not automatically become copied full articles. They can remain discovery cards until manually curated, reviewed, and given a legal/content-approved reader body.

The article detail should have this hierarchy:

| Section | Purpose |
|---|---|
| Source and category | Establish trust before the user reads. |
| Title and reading time | Set expectations. |
| Short SpineUp summary | Make the value obvious without copying the source. |
| In-app source reader or curated reading body | Deliver the actual reading experience. |
| Safety/limitations card | Preserve non-diagnostic boundaries. |
| Save/bookmark | Support return use. |
| Open original source | Preserve transparency and fallback. |

### Video experience

Video detail should distinguish three states:

| State | Visible UI |
|---|---|
| Loading | Thumbnail or branded skeleton with “Loading video…” and no misleading active play icon. |
| Ready | Actual embedded player or clear source-player frame with controls. |
| Unavailable | “This video could not load here” plus **Open source** and source name. |

Every video card should show source, approximate duration where available, category, safety note, and whether it is saved to My Routine. The save-to-routine action should not imply that SpineUp has downloaded or owns the media; it stores a reference to the original source.

## 4. Why every user receives the same routine

The current routine is not a user-owned object. In `today_screen.dart`, the eight exercises are defined in a top-level static `_exercises` constant. Every Today screen passes that same list into `_RoutineSheet`. The only user-controlled routine content is the separate set of saved external videos loaded from `ExternalContentService.savedRoutineVideos()`.

That means the current behavior is structurally expected: profile creation does not create a routine, users cannot browse the exercise catalog, users cannot remove or reorder the built-in exercises, and users cannot replace the starter list. The app has a **static exercise demo plus saved video references**, not an editable routine system.

This is not a small UI omission. It requires a new local-first routine model and a new browsing/editing flow.

## 5. Researched patterns from successful products

The research points to one consistent lesson: successful products separate **Discover**, **Choose**, **Do**, and **Review** rather than forcing every user into one fixed list.

| Product | Observed successful pattern | SpineUp adaptation |
|---|---|---|
| Nike Training Club | Broad library plus one-off workouts, programs, trainer-led classes, and goal-oriented entry points.[1] | Curated routine templates plus individual movement cards; do not imply clinical treatment plans. |
| Fitbod | Exercise library organized by body area/equipment, with visual demonstrations, metadata, detail pages, and browse categories.[2] | Browse by movement category, equipment, duration, effort level, and space; show video/visual guidance on detail. |
| Apple Fitness+ | Explore tab with featured activities, activity types, new content, trainers, programs, collections, filters, and completion checkmarks.[3] | Add featured routines, category filters, duration filters, saved items, and completed-state markers. |
| Sworkit | Explicit custom-workout builder: search/filter the library, add/remove exercises, rename, reorder, and save.[5] | Add “Customize” and “Build my routine” flows with a simple reorderable editor. |
| Physitrack/PhysiApp | Clear separation between exercise library, curated/assigned programs, video instructions, and session logging.[6] | Keep self-selected reference routines distinct from future clinician/caregiver-assigned programs. |

### What these products succeed at

They make the next decision obvious. The user can start a recommended collection, browse by a meaningful filter, inspect an exercise before committing, and edit a routine without losing their place. Visual demonstrations are attached to the exercise detail rather than hidden in a separate content tab. Completed state is visible but does not prevent users from choosing a different item.

SpineUp should borrow that structure, not copy the medical or subscription assumptions of those products. The app is smaller, local-first, non-diagnostic, and designed for a school project demo. Its advantage should be **trustworthy curation plus user ownership**, not an algorithm that claims to know the perfect exercise plan.

## 6. Recommended SpineUp routine architecture

### User-facing information architecture

The Today routine card should become the entry point to a routine hub:

```text
Today
  └── My Routine
        ├── Start today’s routine
        ├── Edit routine
        ├── Browse routines
        └── Browse movements

Learn
  └── Movement library
        ├── Search
        ├── Categories
        ├── Filters
        └── Movement detail
```

The same library can be reachable from Today and Learn, but the jobs should remain distinct. **Today answers “What can I do now?”** Learn answers “What do I want to understand or explore?”

### Routine hub

The routine hub should show the active routine name, estimated duration, exercise count, completion progress, and a small **Edit** action. A secondary row should offer **Browse routines** and **Browse movements**. The starter routine can remain, but it must be presented as a starter template that the user can replace or customize.

Starter templates should use neutral, non-prescriptive names such as:

- Gentle movement reset
- Short posture break
- No-equipment mobility set
- Core and balance basics
- Explore a five-minute routine

Avoid names such as “scoliosis correction,” “curve treatment,” or “fix your spine.”

### Movement library

Each movement card should include a thumbnail or short visual demonstration, name, duration, category, equipment, effort level, and source/safety metadata. The minimum filters should be:

| Filter | Examples |
|---|---|
| Time | 2–5 min, 5–10 min, 10+ min |
| Equipment | None, chair, wall, mat, resistance band |
| Category | Mobility, balance, gentle strength, breathing, posture awareness |
| Effort | Gentle, moderate, ask-your-care-team/unknown where appropriate |
| Format | Guided steps, video reference, saved by me |

Do not filter by clinical diagnosis or claim that a movement is appropriate for a specific curve type unless the content has the required review and safety basis.

### Movement detail

The detail page should show a real demo surface first, then title, what the user will do, duration, equipment, step-by-step cues, stop/safety language, source, and actions:

- **Add to My Routine**
- **Preview in routine**
- **Save for later**
- **Open original source** when the demonstration is external

If there is no video, show a polished static illustration or step sequence and say **Video guidance is not available for this movement yet**. Never show a play icon that does nothing.

### Routine editor

The editor should be simple enough for a school-demo user to understand immediately:

1. Show the active routine name and total estimated time.
2. Provide **Add movement**.
3. Let the user remove an item with a clear delete affordance.
4. Let the user reorder items by drag handle.
5. Let the user rename the routine.
6. Save locally for the current care subject.
7. Provide **Restore starter routine** as a secondary action.

The editor should not require the user to create an account or send data to a server.

### Data model

A robust local-first implementation should move the routine out of `today_screen.dart` and into models/services:

| Object | Important fields |
|---|---|
| `ExerciseCatalogItem` | id, name, description, duration, category, equipment, effort, steps, thumbnail/video reference, source, safety label |
| `RoutineTemplate` | id, name, description, duration, exercise IDs, source/review state, safety label |
| `CareSubjectRoutine` | owner ID, care-subject ID, routine name, ordered exercise IDs, active flag, updated timestamp |
| `RoutineCompletion` | owner ID, care-subject ID, routine ID, exercise ID, date, completion event ID |

Routine ownership must be scoped to `currentUserId` and `currentCareSubjectId`, just like saved content. A SQLite migration is the durable architecture; a subject-scoped local preference is acceptable only for a deliberately temporary prototype.

## 7. First-run screenshot critique

### Onboarding

The onboarding visuals are more premium than the in-app dashboard and should become the visual reference for the product. Screens 1, 2, 4, and 5 have strong typography, readable progress, and coherent full-screen color fields. Screen 5’s “Your data stays yours” promise is particularly effective.

The main weakness is Screen 3, where a huge `+120` dominates the screen before trust and health value are fully established. Keep gamification, but present it as a supporting encouragement after the product promise. Screen 2’s “brace hours feed one daily ring” also risks turning brace use into a score; phrase it as optional tracking. Screen 4’s “Clear answers” should become “Clearer explanations” because SpineUp is not a diagnostic authority.

### Sign-up and Sign-in

The authentication screens are visually strong: large fields, clear CTA hierarchy, guest access, password guidance, and familiar social buttons. The product tension is that account creation is visually more prominent than the local-first guest path. Make **Continue as guest** the equal-weight or primary path for this prototype and explain that account creation is optional.

The codebase still contains mocked Google/Apple actions. Any provider button that does not complete real authentication should be removed for the demo or labeled honestly as unavailable. The Apple button is also unnecessary for an Android-first school project unless the Web flow genuinely supports it.

### Guest confirmation and blank transition

The guest warning dialog is excellent in principle: it explains device-only storage and device-change risk. Add the protected-export remedy directly into the first paragraph so the user sees both the risk and the solution.

One screenshot shows a blank gray shell with only the profile pill and bottom navigation after continuing as guest. If that state lasts longer than a brief transition, it is a blocking initialization defect. Add a branded loading state and an error/retry state; never leave users in an empty shell with no explanation.

### Profile Setup Step 1 — care subject

This is one of the best screens in the app. “Who is this profile for?” is plain, the two choices are understandable, selected state is obvious, progress is visible, and the CTA is safely positioned. Keep the structure.

### Profile Setup Step 2 — privacy and data

The visual card design is strong and the contextual help icon beside portability is exactly right. The copy is not ready for a user-facing demo because it says “Before release,” “in this prototype,” and “will be added before caregiver release.” Those are internal roadmap notes. Replace them with stable wording:

> “Protected export and import help you move a human-readable copy to a new phone. SpineUp shows a preview before anything changes.”

For deletion:

> “You can edit your information later. Deleting local data is irreversible and removes the records stored on this device.”

### Profile Setup Step 3 — essentials

The optionality treatment is respectful and visually clear. The `?` icon for sex assigned at birth is appropriate. The journey-status choices need contextual help because “Preparing for surgery” and “Recovering from surgery” are sensitive states. “Adult with scoliosis” should be repositioned as a profile context/audience option rather than a journey status.

### Profile Setup Step 4 — curve details

This is the strongest clinical-safety screen. It tells users to enter only what they know from a clinic report, permits skipping, explains the Cobb-angle source, and includes “Not sure.” Keep this pattern. Make “Skip for now” slightly more prominent so the form never feels like a self-diagnosis requirement.

### Profile Setup Step 6 — goals

The structure is clear, but several labels cross the non-diagnostic boundary: “Reduce pain,” “Hit my brace-hour targets,” “Prepare for surgery,” “Stay consistent with physio,” and “Track how my curve is changing.” Safer demo wording would be:

| Current label | Safer label |
|---|---|
| Reduce pain | Notice pain patterns |
| Hit my brace-hour targets | Record brace wear |
| Stay consistent with physio | Keep track of movement sessions |
| Prepare for surgery | Prepare questions for a surgery visit |
| Track how my curve is changing | Track recorded measurements |
| Just exploring for now | Explore at my own pace |

The explanatory subtitle should remain: goals shape reminders and app activities, not a treatment plan.

## 8. Priority roadmap

### P0 — Make content actually work

First, fix the dead NHS video placeholder and implement an actionable external/source-reader path. Then harden the YouTube player with explicit ready/loading/error states and a guaranteed Open Source fallback. Finally, add a genuine in-app article-reading surface, at least for curated content and preferably as a controlled reader of the original source.

### P0 — Replace the fixed routine with user ownership

Create the local routine model, starter-template picker, movement library, routine editor, and subject-scoped persistence. This is the feature that changes SpineUp from a static demonstration into a self-management companion.

### P1 — Add video guidance to the routine library

Attach a video/reference link or static visual demonstration to each curated movement. Start with a small, reviewed catalog rather than trying to populate every exercise. A movement without video must have polished written steps and no fake play control.

### P1 — Remove internal prototype language

Clean Step 2 privacy copy, ensure social buttons are honest, reframe onboarding reward copy, and adjust sensitive goal labels.

### P2 — Refine discovery and personalization

Add filters, reorderable routine editing, completion checkmarks, saved movements, and a small “recommended starting point” section. Do not add algorithmic clinical personalization in this release.

## 9. Acceptance criteria

| Area | Pass condition |
|---|---|
| Article | A user can open an article and read meaningful content inside SpineUp or inside a clearly labeled in-app source reader; the original source remains accessible. |
| Video | Tapping a video either starts playback, opens the labeled source, or shows a clear error/retry state. No dead play icons exist. |
| Routine | A user can browse a movement or routine, preview it, add it to My Routine, remove it, reorder it, and save the result for the active care subject. |
| Fresh profile | A new profile does not inherit another user’s routine or saved content. |
| Safety | No routine or goal is described as correction, treatment, prescription, or progression prediction. |
| Onboarding | No visible “prototype,” “before release,” or future-roadmap copy remains. |
| Auth | Guest access is clear and social provider buttons accurately reflect actual capability. |
| Loading | Guest initialization and content loading show branded loading/error states rather than blank shells. |
| Trust | Every external article/video shows source name, safety note, and a direct source fallback. |

## References

[1]: https://www.nike.com/ntc-app — Nike Training Club official app page.

[2]: https://fitbod.me/exercises — Fitbod official exercise guides and videos library.

[3]: https://support.apple.com/guide/fitness-plus/find-workouts-and-meditations-apdcd80997be/ios — Apple Fitness+ official guide to Explore, filters, programs, and collections.

[4]: https://pub.dev/documentation/youtube_player_iframe/latest/youtube_player_iframe/YoutubePlayerController-class.html — `youtube_player_iframe` controller documentation, including initialization, `autoPlay`, cueing, and playback APIs.

[5]: https://help.sworkit.com/en/articles/2561461-custom-workouts-in-sworkit-health — Sworkit official custom-workout and exercise-library guide.

[6]: https://www.physitrack.com/ — Physitrack official exercise-library, video-guidance, and program-building overview.

[7]: https://github.com/TyeLenol/spineup/blob/stabilize/architecture-and-critical-fixes/lib/screens/today_screen.dart — SpineUp routine implementation with the static exercise catalog.

[8]: https://github.com/TyeLenol/spineup/blob/stabilize/architecture-and-critical-fixes/lib/screens/external_content_screen.dart — SpineUp external content cards, detail page, player, placeholder, and source fallback implementation.

[9]: https://github.com/TyeLenol/spineup/blob/stabilize/architecture-and-critical-fixes/lib/services/external_content_service.dart — SpineUp curated content, RSS refresh, saved references, and saved routine-video implementation.
