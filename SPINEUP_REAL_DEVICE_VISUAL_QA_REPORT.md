# SpineUp Real-Device Visual QA Report

**Review scope:** 21 portrait screenshots captured on the Android device, each at 720 × 1600 pixels. The review evaluates the rendered product rather than relying only on source code. It covers Today, Daily Check-In, the routine sheet, appointments, Journey, Activity History, Cobb-angle logging, Learn, Article and Video detail, Me, profile editing, avatar customization, milestones, Preferences, Privacy & Data, and Danger Zone.

## Executive verdict

SpineUp has a coherent and recognizable visual identity. The cream background, mint action color, orange active navigation state, rounded containers, large serif page titles, and friendly line icons create a distinctive product rather than a generic Flutter template. The strongest screens are **Learn, Article detail, Video detail, Log Cobb Angle, Edit Profile, and the grouped Settings layout**. They communicate purpose clearly and use the non-diagnostic/local-first positioning well.

The app is not yet at a “perfect finish” level on the device, but the remaining problems are concentrated and fixable. The largest visible defects are not missing features; they are **safe-area handling, clipped horizontal content, chart labeling, media placeholders, stale demo data, and reward prominence**. These issues make the app look like a functional school project instead of a deliberately finished consumer product.

> **Overall screenshot-based rating: 7.4/10.** The design direction is strong enough for a compelling school demo, but the P0 layout defects should be corrected before presenting it as polished.

## The five fixes that matter most

| Priority | Fix | Screens affected | Acceptance criterion |
|---|---|---|---|
| **P0** | Add reliable bottom scroll padding and safe-area handling wherever the fixed navigation is present. | Me, milestones, Learn, Activity History, Today, Journey | No heading, card, chip, CTA, or final row is covered by the navigation shell or gesture bar at the bottom of a 720 × 1600 device. |
| **P0** | Stop horizontal chips/carousels from being visibly cut off. | Learn tabs/categories, Activity History filters, avatar presets, badge carousel | Every row has deliberate left/right content padding; the first and last item are either fully visible or intentionally afford scrolling. |
| **P0** | Repair the Journey chart labels and framing. | My Journey | X-axis labels do not overlap; y-axis labels are mathematically ordered and readable; empty/sparse data has an intentional state; “recorded measurement” language is visibly non-diagnostic. |
| **P0** | Replace the blank media area and play icon on Article/Video detail with the correct surface. | Article detail, Video detail | Articles show a reading/cover treatment without a misleading play button. Videos show a real thumbnail/player frame before playback, with a clear fallback when the source cannot load. |
| **P0** | Present clean demo data and verify the latest build/data state. | Today, Check-In, Appointments, Journey, Activity History | No stale “Orthopedist Follow-up,” suspicious 12:00–4:00 AM test entries, or accidental default pain/brace values appear in a fresh demo profile. |

The current source branch already contains the recent copy and neutral check-in-default correction. Several screenshots still show older persisted data or an older installed build, including “Orthopedist Follow-up,” pain 2/10, and 8 brace hours. These screenshots are valuable evidence of the device’s current experience, but they should not be interpreted as proof that the latest source still contains those defaults. `flutter clean` does not erase app data; use a fresh profile or clear the app’s local storage before the final demo verification.

## Global visual system assessment

The palette is memorable and appropriate for a warm, supportive health companion. Mint works well for primary actions and positive confirmation, while orange is a strong active-navigation accent. Lavender appears in some status and badge elements, but it is not governed as clearly as mint and orange. Either define lavender as a deliberate “measurement/history” accent or reduce its use so the product has a tighter semantic color system.

Typography is one of SpineUp’s strengths. Large serif titles make the product feel editorial and differentiated, while the rounded sans-serif body text is approachable. The main typography problem is not the typeface; it is **content density and line-length management**. Long URLs, large paragraphs, and repeated metadata create oversized vertical blocks. Detail screens should collapse secondary information behind progressive disclosure instead of displaying every source field at once.

The rounded cards and outlined controls are consistent, but the app sometimes uses too many visual containers at once: a rounded page card, a rounded inner card, a rounded chip, a rounded navigation shell, and a rounded button can all appear in one viewport. Preserve the language, but reserve the strongest borders and shadows for primary actions and important state changes.

The bottom navigation is recognizable and tactile, but it is visually heavy. Its large outlined capsule, active orange pill, shadow, gesture-area spacing, and persistent footprint consume a substantial portion of every screen. That is acceptable only if every scrollable page receives enough bottom padding. At present, several screenshots show the navigation physically covering content, which is a launch-quality defect.

## Screen-by-screen audit

### Today

**What works.** Today has the correct product hierarchy: the Daily Check-In is the dominant action, the routine is a compact entry point, and XP and appointments are supporting information. The mint check-in card is readable and visually actionable. The greeting and active-profile context make the page feel personal without becoming childish.

**What needs correction.** The top-right “Profile: You” control and adjacent switch icon feel crowded and close to the page edge. The appointment row can display stale or test-like content, which weakens trust. The XP strip still receives more attention than it should for a health action. The page should also be checked with a long routine title, a long profile name, and a ward profile name so the top area does not collide or wrap badly.

**Finish direction.** Keep the check-in card dominant. Make the profile switcher a single compact control with a clear icon and label. Reduce XP to a quiet progress line or small secondary metric. Keep the appointment as a calm upcoming-visit row rather than a reward surface.

### Daily Check-In

**What works.** The form uses large touch targets, clear section labels, readable mood chips, obvious selected states, a generous notes field, and a strong full-width completion CTA. “Not recorded” is the right mental model for unanswered health fields.

**What needs correction.** The screenshots show pain and brace values already populated while mood is unanswered. This is either stale persisted state or an older build, but it demonstrates why fresh-profile verification is required. The form is long enough that the user may not know how much remains; the lower CTA is only visible after scrolling. The mix of selected mint chips, outlined chips, and neutral chips creates a slightly noisy rhythm. “Brace Wear” should visibly say “optional” if unanswered values are allowed.

**Finish direction.** Use an explicit unanswered state for mood, pain, and brace hours. Consider a small top summary such as “2 of 6 sections completed” or a sticky bottom action that appears only after the user has interacted. Keep the form calm and avoid turning every input into a colorful reward interaction.

### Routine sheet

**What works.** The bottom sheet has strong structure: handle, close action, large title, completion count, completed-state styling, and a clear list. The saved-video section is a useful differentiator and is presented with a trustworthy source label.

**What needs correction.** Repeated “+30 XP” labels make the exercise flow feel reward-led. Exercise rows are visually repetitive, icons are small, and the sheet is extremely tall. The last visible row can be clipped, and the user is not given a strong visual cue that the sheet itself scrolls.

**Finish direction.** Make exercise name, duration, and completion state primary. Move XP behind a small secondary label or omit it from the sheet. Separate “Routine exercises” and “Reference videos” with stronger section structure. Ensure the sheet has enough bottom padding above the gesture area.

### Appointments and Past Visits

**What works.** The appointment manager has clear Upcoming/Past Visits tabs, a strong “+ Schedule” action, readable cards, and neutral “Visit recorded” status language. The schedule form is spacious and easy to scan.

**What needs correction.** The screenshots show “Orthopedist Follow-up,” which must be treated as stale demo content or cleared after the latest build. Past Visits has too much empty lower space and feels unfinished when there is only one item. The schedule form defaults to an odd early-morning time such as `2:53 AM`, which looks like an implementation default rather than a user decision. The title field should communicate whether a visit type is required, and notes/keyboard behavior should be tested.

**Finish direction.** Default the date/time picker to a deliberate future time or require selection without implying a real appointment. Add a compact empty-state message for additional history. Keep appointment rewards out of the visible appointment-management surface.

### My Journey

**What works.** Journey has a strong page title, a privacy notice, a visible time-range control, recent records, and an understandable route to Activity History. The privacy message is a good trust signal.

**What needs correction.** The chart is the most visibly unfinished component in the screenshots. X-axis labels overlap, y-axis labels are awkward, sparse data is not framed gracefully, and the plotted points are not self-explanatory. “Latest: 24.0° Cobb” reads like a clinical dashboard headline and needs stronger context that it is a user-recorded value, not an interpretation. The floating action menu overlays recent records and feels detached from its trigger. The profile switch control is crowded at the top.

**Finish direction.** Simplify the chart to a small number of readable labels, use a “No measurements in this period” state when appropriate, and add a concise caption: “Recorded from your entries; not a diagnosis or prediction.” Replace the expanded floating menu with an “Add record” bottom sheet or a compact inline action group.

### Log Cobb Angle

**What works.** This is one of the cleanest screens. It has a single task, a clear non-diagnostic notice, one input, and one primary action. The safety language is appropriate and visible.

**What needs correction.** The visible “+50 XP” makes a sensitive measurement entry feel gamified. The input lacks an example, numeric keyboard hint, accepted range guidance, or a “Where do I find this?” help affordance.

**Finish direction.** Remove XP from the form. Add a contextual help icon beside the field label with a short explanation that users should enter the value from a clinician-provided imaging report. Use a numeric keyboard and validate the value without implying what it means clinically.

### Activity History

**What works.** The page has a useful title, back action, refresh action, filter controls, and consistent event cards. The mixed timeline is understandable.

**What needs correction.** The filter row clips the “Measurements” label. XP amounts are visually louder than the event type and make the screen feel like a rewards ledger. Several times look like test data or timezone artifacts, especially the cluster of entries around midnight and early morning. The screen leaves a large amount of empty space after a small list.

**Finish direction.** Give the event type, date, and content primary emphasis; make XP a small tertiary label. Ensure filters are fully visible and horizontally scrollable. Add an intentional empty state and clean demo data before presentation.

### Learn

**What works.** Learn is a standout. The large editorial heading, search affordance, plain-language promise, source-linked tags, and topic descriptions make the library feel credible and useful. The “records and educates; it does not diagnose or prescribe” line is especially effective.

**What needs correction.** The top tabs visibly clip “Saved,” and the category row clips its final item. The Exercise Safety card runs behind the bottom navigation, creating an obvious overlay defect. The screen has a lot of horizontal and vertical content competing for attention.

**Finish direction.** Use a horizontally scrollable tab row with deliberate fade/scroll affordance or a compact segmented control that fits the device width. Add bottom padding equal to the navigation height plus safe area. Keep the source-linked metadata, but reduce its visual weight slightly.

### Article detail

**What works.** Article detail has a polished editorial hierarchy, bookmark action, content type/category/source metadata, strong title, summary, source organization, safety limitation, and clear “Open source” fallback. This is a strong trust and content-governance surface.

**What needs correction.** The large blank media area with a play icon is confusing on an Article. It looks like a missing player or broken image. The raw URL is visually heavy and consumes a lot of vertical space.

**Finish direction.** Remove the play icon for articles and use a quiet cover/reading treatment instead. Collapse the raw URL behind “View source details” while keeping the source name and external-link action visible.

### Video detail

**What works.** The video detail communicates title, source, safety language, saved state, and source fallback well. “Remove from My Routine” clearly confirms that the save-to-routine feature works.

**What needs correction.** The blank media area and play icon make the screen look unfinished before playback. The filled bookmark has no explicit state label. The long raw source URL is too visually dominant.

**Finish direction.** Show a real thumbnail or player frame with a consistent loading/error state. Label the bookmark state accessibly. Use a compact source row and progressively disclose the full URL.

### Me profile summary

**What works.** The active-profile card is a strong caregiver-aware interaction. Profile details are easy to scan, and the edit action is discoverable.

**What needs correction.** The fixed bottom navigation covers the next content section. The default orange avatar is generic and looks like a placeholder. Level and XP occupy a large hero area and compete with profile information. The switch icon on the active-profile card and top-right profile pill feel redundant.

**Finish direction.** Fix scroll padding first. Reduce the XP/level hero or move it below active-profile and profile information. Use one consistent profile-switch entry point. Replace the default avatar with a more intentional illustration or a quieter empty state.

### Edit Profile Info

**What works.** This is a very usable form: the large name field, pill options, selected states, spacing, and Save Changes CTA are all strong. It looks close to finished.

**What needs correction.** “Recorded curve type” is a sensitive clinical-adjacent term and should have a contextual help icon. The choices could be mistaken for a self-diagnosis menu. Keyboard and sheet-height behavior need real-device confirmation.

**Finish direction.** Add a small `?` help affordance with a short explanation and a Learn More destination. Keep the label “recorded” and explicitly say users should use information already provided by a clinician. Ensure the sheet scrolls above the keyboard.

### Avatar customization

**What works.** The avatar area gives the profile screen personality and supports local photo selection without cloud language. The preset cards are friendly and memorable.

**What needs correction.** The preset carousel clips the first item, which makes the component look broken. The default orange avatar is repeated and overly abstract. The section adds a lot of vertical weight to Me.

**Finish direction.** Use proper horizontal padding and an intentional partial-card affordance, or show a two-row grid of presets. Give the default state a named neutral avatar rather than a blank orange circle. Keep the local-photo action, but make its privacy implication explicit.

### Progress and milestones

**What works.** Collapsing the section by default is the right information-architecture choice. The expanded badge carousel and achievement cards are visually engaging, and the distinction between Badges and Achievements is understandable.

**What needs correction.** The expanded section becomes very long, the badge carousel clips at the right edge, and the bottom navigation covers the last achievement/Preferences transition. Achievement icons are more decorative than semantically consistent.

**Finish direction.** Consider opening a dedicated Progress screen or use a compact grid. Ensure the carousel is fully padded and the expanded content receives sufficient bottom inset. Keep achievements supportive rather than allowing them to dominate Me.

### Preferences, Privacy & Data, and Danger Zone

**What works.** This is a major improvement over a flat settings list. The three grouped sections scan well, export/import descriptions are clear, and Danger Zone is visually separated without being excessively alarming. “Review before adding or replacing profiles” is excellent copy for protected portability.

**What needs correction.** The “Privacy & Data” section heading and the “Privacy & Data” row title repeat the same phrase. The notification toggle is visually heavier than the rest of the palette. Destructive deletion should have confirmation copy that clearly states it is irreversible and local data will be wiped.

**Finish direction.** Rename the row to “How SpineUp protects records” or “Privacy details.” Keep export/import prominent. Add a confirmation step with explicit scope, profile name, and irreversible consequence before deletion.

## Surfaces not represented in the uploaded screenshot set

The screenshots do not provide visual evidence for Splash, Onboarding, Sign-in, Sign-up, Forgot Password, the six-step Profile Setup flow, Care Subject Manager/Switcher, Community/Coming Soon, or every contextual-help modal. These surfaces were previously reviewed from source and documentation, but they still need a dedicated device screenshot pass before the app can honestly be described as visually audited end to end.

The highest-risk missing surfaces are Profile Setup and authentication because they establish trust before the user reaches the strong in-app screens. Capture them on the same device with the keyboard open, with validation errors, and with a ward/caregiver profile selected.

## Recommended implementation order

### Pass 1 — Device-blocking layout corrections

First fix bottom navigation safe-area padding, clipped horizontal rows, the Journey chart labels, and the Article/Video media hero. These changes will produce the largest visible improvement across the screenshot set. Re-run the same captures afterward; do not move to cosmetic refinement until every final row and chip is fully visible.

### Pass 2 — Demo trust and data integrity

Create a fresh demo profile or clear local app storage, then verify the neutral check-in defaults, appointment titles, appointment times, and activity timestamps. Remove all test-like midnight/early-morning activity from the presentation dataset. Verify that the latest APK is actually installed on the device before judging source changes.

### Pass 3 — Rebalance gamification

Reduce the repeated XP labels in the routine sheet, Journey actions, Activity History, Cobb-angle form, and appointment surfaces. XP, streaks, and badges should remain available, but health actions and recorded information should carry the visual weight.

### Pass 4 — Refine secondary surfaces

Improve the profile avatar default, reduce the size of the Me XP hero, refine the FAB menu, collapse raw URLs, add contextual help beside clinical-adjacent profile fields, and tighten the settings copy. These changes will make the app feel deliberately authored rather than simply functional.

### Pass 5 — Capture the missing first-run screens

Capture Onboarding, Sign-in, Sign-up, Forgot Password, Profile Setup, Care Subject Manager, Community/Coming Soon, and contextual-help modals. Check keyboard behavior, validation states, back navigation, and safe-area padding. Only after this pass should the visual audit be considered complete for all app screens.

## Final acceptance checklist

| Area | Pass condition |
|---|---|
| Navigation shell | No content is hidden behind the bottom navigation or gesture bar. |
| Horizontal controls | No tab, chip, carousel item, or filter label is clipped unintentionally. |
| Forms | Keyboard never covers the active field or primary CTA; unanswered health fields remain visibly unanswered. |
| Journey chart | Labels are legible, ordered, non-overlapping, and framed as recorded data rather than diagnosis. |
| Content media | Article and Video detail have distinct, intentional pre-play surfaces. |
| Data realism | Fresh demo data contains no stale titles, suspicious times, or fabricated health values. |
| Gamification | XP and badges support the health task instead of leading it. |
| Trust | Local-first, non-diagnostic, source-aware language is visible and consistent. |
| Accessibility | Text, icons, toggles, selected states, and external-link actions remain understandable without relying only on color. |
| Missing screens | First-run, auth, caregiver, and modal surfaces have their own device captures and pass the same checks. |

## References

[1]: `spineup_screenshot_findings.md` — source-confirmed notes from the 21 uploaded 720 × 1600 screenshots.

[2]: `SPINEUP_UI_UX_FINAL_FINISH_SPEC.md` — prior implementation-ready UI/UX finish specification.

[3]: `SPINEUP_VISUAL_DIRECTION_RESEARCH.md` — prior visual-direction benchmark and product positioning research.
