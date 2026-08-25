# SpineUp Final Information-Architecture Audit

## Current post-onboarding structure

SpineUp currently has four primary destinations: Today, My Journey, Learn, and Me. Daily Check-In, appointments, Cobb-angle logging, exercise instructions, the care-subject manager, privacy, and archive flows are opened as secondary pages or modal sheets from those destinations.

## Main findings

### Today

Today currently contains the greeting/date, active-subject context from the shell, a large level/XP card, streak and daily XP stats, check-in and routine summary cards, next appointment, then an eight-item expanded/collapsible exercise catalogue. The real value of the exercise section is not the eight inline cards; it is the guided exercise sheet launched from a card. Today therefore has a strong daily loop buried inside a long dashboard.

Recommended role: **the next useful action for today**. It should lead with check-in and a single routine entry point, show concise progress/streak feedback, and keep appointments as a small contextual card. The full routine should be opened from a dedicated “Today’s routine” view or a focused bottom sheet, not rendered as eight full cards in the main feed.

### My Journey

Journey currently combines privacy notice, chart filters, a Cobb-angle chart with optional pain/stretches overlays, an expandable FAB for Cobb/appointment logging, and a long Activity Log of up to 30 events. Each event tile can include labels and XP, making the screen a chart-plus-history-feed hybrid.

Recommended role: **recorded measurements and reflection over time**. The Activity Log should not be permanently appended below the chart. It makes Journey unnecessarily long, mixes unlike event types, repeats gamification in a reflective surface, and hides the chart’s core meaning. Replace it with a compact “Recent records” preview and a clear “View all history” action, or move history into a dedicated History sheet/page accessible from Journey. The chart should remain the primary surface.

### Learn

Learn has a coherent role: source-aware education, contextual definitions, safety notes, limitations, and related topics. It should remain a primary destination because it is a core differentiator and supports the rest of the app in context.

Recommended role: **understand terms and make informed self-management choices**. Avoid adding records, achievements, or community content here.

### Me

Me currently combines identity summary, active profile switching, profile info, avatar upload/presets, badges, achievements, appearance, notifications, protected export/import, privacy, and destructive account deletion. The active profile card is excellent, but the page is effectively four products stacked together: identity, progress/trophies, settings, and privacy/data management. The edit sheet also exposes legacy “Diagnosis / Curve Type” language despite the structured subject-scoped profile architecture.

Recommended role: **identity, active profile management, and personal controls**. Keep active profile management at the top. Move achievements into a compact progress entry or a dedicated progress detail sheet. Group appearance/notifications under Preferences, export/import/privacy under Privacy & Data, and deletion under a visually separated Danger Zone. Replace diagnosis-centered editing language with the current structured profile vocabulary.

### Appointments

Appointments are currently launched from Today’s next-appointment card and Journey’s FAB, then managed in a modal with Upcoming/Past Visits tabs. This contextual entry is correct; appointments do not need a permanent bottom-navigation tab for this school project. They should remain a secondary task surfaced when relevant.

Recommended role: **care planning and visit records**. Keep contextual access from Today and Journey, but remove reward-forward language from the appointment header/detail flow and use human-friendly dates.

### Daily Check-In

Daily Check-In is correctly launched from Today because it is a daily action. It should remain a focused full-screen form, not be embedded in Today. Its defaults and review language need refinement, but its placement is right.

### Exercise flow

The guided exercise sheet has richer interaction than the inline routine cards: steps, cues, timer, pause, finish-early, progress, and completion feedback. The sheet is the product experience; the eight-card catalogue is only a launcher. The UI should make that distinction visible.

### Care-subject manager

The care-subject manager is correctly launched from Me’s active-profile card because switching profiles is an identity/control task. The global active-subject indicator is helpful, but it should not compete with Today’s app-bar actions.

## Preliminary target structure

| Destination | Primary job | Primary content | Secondary content |
|---|---|---|---|
| **Today** | Do the next useful thing today | Check-in, one routine CTA, concise daily progress | Appointment reminder, streak/XP support |
| **Journey** | Review recorded measurements and patterns without diagnosis | Chart, range/filter controls, latest record | Recent records preview, full history action, log measurement/visit actions |
| **Learn** | Understand terms and safety context | Search, categories, topic cards, source-aware details | Contextual help deep links |
| **Me** | Manage identity and local controls | Active profile, identity summary, preferences entry points | Progress detail, privacy/data, export/import, danger zone |

## Principle

Do not create more top-level tabs just to solve local clutter. Popular products keep a dominant daily path on Home and move supporting progress/history/settings into dedicated areas or detail views. SpineUp should simplify the current four-tab shell rather than add a fifth destination unless a later feature set truly needs it.

## Implemented final cleanup

The final cleanup branch implements the placement decisions without adding a fifth navigation tab. Today now leads with the daily check-in, presents a compact routine progress entry point, moves the full exercise catalogue into a focused routine sheet, and compresses level/XP into a supporting progress strip. Journey now keeps the chart primary, shows only three recent records without XP pills, and routes full history to a dedicated Activity History screen with filters. Me now collapses avatar customization and progress/milestones into secondary expandable groups and separates Preferences, Privacy & Data, and Danger Zone settings. The existing care-subject manager, archive flows, guided exercise steps, and completion rewards remain available.

The reason for these changes is hierarchy, not feature removal: daily action should be immediate, reflection should remain readable, and control/destructive actions should be grouped by user intent. The implementation preserves SpineUp’s unique gamification, caregiver profiles, local-first portability, and source-aware learning while reducing the feeling of a mismatched feature stack.
