# SpineUp Final IA Decision Record

## Decision 1: Keep four primary destinations

Do not add a fifth tab. Today, Journey, Learn, and Me are enough for the current school-project scope. Appointments, Daily Check-In, exercise guidance, profile management, and archive flows are contextual tasks and do not justify permanent navigation.

## Decision 2: Make Today a daily action launcher

Today should answer one question: “What is the next useful thing I can do for this profile today?” The top hierarchy becomes:

1. Greeting and active profile context.
2. Daily Check-In as the primary action, with a clear completed/uncompleted state.
3. Today’s Routine as one compact progress card that opens the complete routine sheet.
4. Streak/XP as supporting motivation.
5. Next Appointment as a small contextual card.

The eight exercise cards will no longer render inline in the main Today feed. They will remain accessible through a dedicated routine bottom sheet that reuses the existing guided exercise flow and completion rewards.

## Decision 3: Make Journey a record-and-reflection surface

Journey should answer: “What have I recorded over time?” The chart and its latest-record context remain primary. The long activity feed is removed from the main page because it makes the page unnecessarily long, repeats XP, and mixes journaling, exercises, measurements, appointments, and profile events.

Journey will show a compact recent-records preview and a “View all history” action. A new full-screen activity-history page will own the long event list and filtering. This preserves discoverability without making the chart page a chart-plus-feed hybrid.

## Decision 4: Make Me a calm control center

Me should answer: “Whose profile am I managing, and where do I control identity and data?” The top remains identity and active-profile switching. Progress becomes a compact entry point rather than a long trophy wall. Settings are grouped into Preferences, Privacy & Data, and Danger Zone. Archive and privacy actions stay accessible but are no longer visually mixed with achievements.

The first implementation pass will improve visual grouping, reduce the badge/achievement wall, and make headings and spacing communicate the new groups. Legacy diagnosis-centered visible copy will be changed to “Curve description”/“Recorded profile details” where the existing runtime model still supplies the data.

## Decision 5: Preserve gamification, change its position

Gamification remains a core retention mechanism. XP, streaks, levels, badges, and completion celebrations stay. They support completed self-management actions; they do not lead the health-record surfaces or headline appointments and clinical measurements.

## Decision 6: Keep SpineUp unique

The app should not imitate Duolingo’s exact path, Finch’s pet, or Headspace’s content catalog. It should combine their strongest principles—one dominant daily path, one clear emotional anchor, needs-based content, and task-first trust—around SpineUp’s unique combination of caregiver profiles, local-first privacy, non-diagnostic records, guided routines, and contextual learning.
