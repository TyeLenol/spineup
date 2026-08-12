# SpineUp Product and Architecture Decision Record

**Status:** Proposed for founder review
**Implementation status:** No code changes requested or included in this record
**Audience:** SpineUp product, design, clinical-content, privacy, and engineering collaborators

> **Health note:** I am an AI, not a medical professional. This record is product and safety analysis, not medical diagnosis or treatment advice. A qualified clinician should review consequential health content before publication.

## 1. Executive decision

SpineUp will be a **private, local-first scoliosis companion**. It will support both people managing their own scoliosis and parents or caregivers managing one or more wards. A user can choose during profile setup whether the profile represents **themselves or someone else**. The app will work without an account, keep health data on the device by default, and let the owner export and re-import a human-readable, protected archive when changing phones.

Cloud services may be introduced later as an **optional, user-initiated backup or synchronization feature**. Cloud use will never be required for the core local experience. The product will not use analytics initially, will not sell or share health data, and will not present itself as a doctor, diagnostic tool, treatment planner, or replacement for professional care.

The near-term objective is not to narrow the vision to a small demo. The intended product is the full SpineUp experience: onboarding, profiles, daily check-ins, routines, educational articles and exercise videos, appointments, history, progress, gamification, portability, and Community when Community can meet a real trust and moderation standard.

## 2. Product promise and boundaries

### Recommended product promise

> **SpineUp helps people with scoliosis and their caregivers privately track routines, symptoms, appointments, and personal progress so they can build consistent habits and have better-informed conversations with healthcare professionals.**

This promise is strong because it describes support, organization, and reflection without claiming that SpineUp can diagnose, predict curve progression, prescribe exercises, or replace a clinician.

### What SpineUp is and is not

| SpineUp is | SpineUp is not |
|---|---|
| A private tracking and self-management companion | A diagnostic system |
| A place to record symptoms, routines, measurements, and appointments | A system that interprets a Cobb angle as a treatment decision |
| An educational library with source transparency | A substitute for a physiotherapist, orthopaedic specialist, or emergency service |
| A habit and preparation tool | A tool that changes brace prescriptions or clinical plans |
| A caregiver workspace for one or more wards | A medical record system unless a future clinical integration is explicitly designed and governed |
| A user-controlled portable archive | A hidden analytics or advertising data pipeline |

The product should use language such as **“record,” “review,” “prepare,” “learn,” and “discuss with your clinician.”** It should avoid language such as **“correct,” “cure,” “guarantee,” “prevent progression,” “your treatment plan,” or “your curve is getting worse”** unless a qualified clinical and regulatory review explicitly supports the wording.

## 3. Users and profile ownership

SpineUp has three first-class user situations rather than one:

| User situation | What the user needs | Product implication |
|---|---|---|
| Self-user | Track their own routine, symptoms, appointments, and history | The default personal workspace |
| Parent/caregiver | Track one ward, including reminders and appointment preparation | Caregiver ownership must be explicit and understandable |
| Multi-ward caregiver | Switch between two or more wards without mixing data | A ward switcher and strict data isolation are core architecture requirements |

The profile setup should begin with an ownership question: **“Who is this space for?”** The choices should be **“Me”** and **“Someone I care for.”** A caregiver should then be able to create or select a ward profile. The interface must always show whose data is currently active, especially before recording symptoms, appointments, Cobb-angle entries, or journal notes.

The current user model should therefore be understood conceptually as:

> **Account/session owner → one or more care subjects → subject-specific profile, events, routines, appointments, content history, and exports.**

This distinction matters more than the current prototype’s single `local_user_001` identity. A caregiver is not the same thing as the person whose health data is being recorded.

## 4. Full app structure before coding

The app should be organized around a **care-subject workspace**, not around disconnected screens. The current prototype has several screens that are individually attractive but need to become one coherent system.[1]

### A. Entry and trust layer

The entry layer contains the splash screen, orientation/onboarding, consent, privacy explanation, and the first profile decision. Its job is to establish trust before asking for sensitive health information.

The first-run sequence should be:

1. Explain what SpineUp does and does not do.
2. Explain local-first storage and the user’s export/delete rights.
3. Ask whether the workspace is for the user or someone else.
4. Create the first care subject.
5. Collect only information needed to personalize the experience.
6. Let the user skip optional clinical details and add them later.
7. Show the first useful action rather than ending on a form-completion reward.

### B. Care-subject switcher

The care-subject switcher is essential for caregivers. It should be available from the main shell and should clearly show the active subject’s name or chosen nickname. Switching subjects should require a visible state change and should refresh every user-scoped surface.

The most important safety rule is **no cross-subject leakage**. A check-in, appointment, export, history chart, Community post identity, and gamification total must always belong to the active subject or clearly belong to the caregiver account itself.

### C. Today workspace

Today is the daily action center. It should answer three questions:

1. What can I do today?
2. How am I feeling today?
3. What is coming up next?

Its sections should be the daily check-in, today’s routine or guided exercise, upcoming appointment, and a short progress/reward summary. A routine can contain a mixture of exercise instructions, source-linked videos, and educational context. The user should be able to save exercises into a personal routine only when the content is presented as general educational or clinician-approved material, not as an individualized prescription.

### D. Journey and history

Journey is the reflective layer. It should combine check-ins, routines, appointments, and user-entered Cobb-angle records in a timeline and filtered view. It must distinguish **what the user recorded** from **what the app infers**. For the first version, the app should avoid inferring clinical progression from measurements.

Recommended labels include **“Your recorded measurements”** and **“Your reported symptoms.”** The chart should show dates, source, and optional notes. It should not label a curve as improving, worsening, safe, or dangerous without clinical review.

### E. Learn library

Learn should contain articles and exercise videos with visible source metadata. Each item should include the publishing organization or author, publication/update date when available, evidence or review status, intended audience, and a plain-language limitation statement.

The content system should support three states:

| Content state | Meaning |
|---|---|
| Reviewed | A qualified reviewer has checked the content and the product’s presentation |
| Source-linked | SpineUp is linking to an external source without claiming independent clinical validation |
| Community or draft | Not suitable for medical guidance until reviewed |

The initial content strategy should prioritize authoritative organizations and peer-reviewed guidance. The 2016 SOSORT guideline covers assessment, bracing, physiotherapeutic scoliosis-specific exercises, respiratory function, sports, and education, but it is written for professionals and its recommendations vary in evidence strength.[2] Therefore, SpineUp should translate evidence carefully and display the source rather than flattening all recommendations into equal-confidence “quests.” The Scoliosis Research Society’s patient material similarly separates the rationale, indications, brace types, and expected outcomes of bracing.[4]

A useful evidence rule is: **every health claim in Learn must have a source, an owner, a review date, and an explicit confidence or limitation note.**

### F. Appointments

Appointments should help a user prepare, record questions, store notes, and mark what happened. The app should not act as a clinician’s record or imply that a missed or completed appointment proves anything about health status.

A preparation checklist can include:

- symptoms or concerns the user wants to discuss;
- routine or brace questions;
- recent recorded measurements, clearly marked as user-entered;
- medication or treatment questions entered by the user; and
- a post-appointment note area.

### G. Me and settings

Me should be the control center for profile ownership, ward switching, data export/import, privacy, local protection, content preferences, and account/session settings. It should not be only an avatar and badge page.

The highest-trust settings should be easy to find:

| Setting | Required behavior |
|---|---|
| Export my data | Creates a human-readable protected archive and explains what it contains |
| Import data | Validates the archive, previews the target subject, and requires confirmation before merging or replacing |
| Delete data | Explains scope and consequences, then deletes only the selected subject or local workspace |
| Local protection | Uses device authentication/encryption where the platform supports it |
| Cloud backup | Off by default; unavailable until the user explicitly enables it |
| Analytics | No analytics initially; no health data collected for product analysis |

### H. Community

Community should be treated as a governed subsystem, not a normal content tab. The recommendation is to keep the experience in the product plan, but make it conditional for the release:

> **Community ships only if posting, identity, reporting, moderation, privacy, and age-safety flows pass a defined trust gate. Otherwise, the navigation presents “Coming soon” or removes the surface without affecting the private core app.**

The first Community version should be pseudonymous, avoid public health claims, provide reporting and blocking, and clearly separate peer experience from medical guidance. If the team cannot staff moderation and respond to reports, Community should not be enabled.

## 5. Data and privacy decisions

Ghana’s Data Protection Commission identifies accountability, lawfulness, purpose specification, openness, security safeguards, and data-subject participation among its data-protection principles. It also states that data controllers and processors must register with the Commission.[5] This means “local-first” is a strong trust posture, but it is not a substitute for privacy governance if SpineUp later processes data through cloud services, analytics, support systems, or Community moderation.

### Recommended privacy position

1. **No analytics for now.** Do not collect usage analytics until the team has a clear purpose, consent language, retention period, and data inventory.
2. **Local data is protected.** Use platform-supported secure storage and device protection where possible. Do not describe the database as encrypted unless it actually is.
3. **Export is human-readable and protected.** The archive should be understandable to a person, but protected by a user-chosen passphrase or equivalent secure mechanism. The product should warn users that an export becomes their responsibility once copied outside the app.
4. **Import is deliberate.** Show the subject name, archive date, record categories, and conflict policy before importing. Never silently merge two subjects.
5. **Cloud is optional and explicit.** If introduced, cloud backup should be off by default, user-initiated, and governed by a separate consent screen. No cloud feature should silently become a prerequisite for core use.
6. **Caregiver consent is explicit.** The app must distinguish the caregiver’s control of a workspace from the ward’s health data. Minor and ward relationships require a reviewed consent and access policy before launch.

## 6. Safety and clinical-content recommendations

SpineUp should be a **tracking and education product**, not an automated clinical decision product. Existing clinical summaries emphasize that scoliosis management depends on factors such as curve magnitude, skeletal maturity, progression risk, symptoms, and clinical assessment; they also note limits in patient-oriented evidence and potential harms or burdens of interventions.[3] This supports a conservative product boundary.

The app should not:

- diagnose scoliosis from a photo, posture, or self-reported measurement;
- calculate or predict progression;
- recommend a brace type, brace schedule, or treatment change;
- prescribe a routine for a particular curve pattern;
- interpret pain severity as proof of curve progression; or
- imply that completing a routine earns clinical improvement.

The app may:

- let users record what a clinician has told them;
- show general educational material with source links;
- let users save routines as personal reminders or educational collections;
- show user-entered history without clinical interpretation; and
- encourage users to discuss concerning symptoms or questions with a qualified professional.

For Ghana, the app should use a **reviewed local safety directory** rather than hardcoding emergency information from an unverified source. The Ghana Health Service provides official health-service and facility-oriented public-health information, including a facility-finder direction and emergency-response information.[6] Before release, a Ghana-based health or operations reviewer should verify the emergency wording, facility links, language, and offline fallback behavior.

## 7. Recommended success measures

For the first full-app release, I recommend three primary success measures:

| Priority | Measure | Why |
|---|---|---|
| 1 | Weekly return use by active care subject | Measures whether the product becomes a trusted recurring companion |
| 2 | Completion of the check-in → routine → review loop | Measures whether the app’s central structure is useful rather than merely browsable |
| 3 | User trust and portability success | Measures whether people understand local-first storage and can export/re-import without fear or confusion |

Secondary measures should include appointment-preparation usefulness, caregiver subject-switch accuracy, safety-boundary comprehension, and Community report-handling quality if Community is enabled. XP, streaks, and badge counts are supporting engagement signals, not the main definition of success.

## 8. Open decisions still recommended for agreement

The major direction is clear, but these decisions should be confirmed before coding resumes:

| Decision | Recommendation |
|---|---|
| Profile ownership | Support “Me” and “Someone I care for” from the beginning; design the data model around care subjects |
| Minimum independent age | Start with an explicit age/guardian policy rather than assuming all users can consent independently |
| Export protection | Use a passphrase-protected archive; define whether attachments are embedded or separately encrypted |
| Import conflicts | Default to preview plus explicit replace/merge choice; never silently overwrite |
| Learn content | Source-linked first; only label content “reviewed” after a named reviewer and review date exist |
| Exercise videos | Use official or licensed sources; maintain a review/expiry list for links |
| Community | Ship only behind a trust gate; otherwise show Coming Soon or omit it from navigation |
| Ghana escalation | Verify local emergency and health-facility information with a Ghana-based reviewer before release |
| Cloud | Defer implementation; design the consent and threat model now, not the infrastructure |
| Release definition | “Near finished” should mean the full core journey is coherent, portable, safe, and tested—not that every possible integration exists |

## 9. No-code approval gate before implementation

Before writing more code, the team should approve five artifacts:

1. **Product brief:** the promise, users, full feature map, and non-goals.
2. **Care-subject model:** how self-users, caregivers, and multiple wards work conceptually.
3. **Privacy and portability brief:** local protection, export/import, deletion, cloud opt-in, and no analytics.
4. **Clinical-content policy:** evidence sources, review ownership, language restrictions, and escalation rules.
5. **Community go/no-go checklist:** posting, identity, moderation, reporting, blocking, age safety, and operational ownership.

Only after those artifacts are approved should we explain the implementation architecture in technical detail and begin the next coding branch. The first technical sprint should then implement the agreed care-subject and portability boundaries before adding more surface area.

## References

[1]: https://github.com/TyeLenol/spineup/tree/stabilize/architecture-and-critical-fixes "SpineUp stabilization branch"
[2]: https://link.springer.com/article/10.1186/s13013-017-0145-8 "2016 SOSORT guidelines: orthopaedic and rehabilitation treatment of idiopathic scoliosis during growth"
[3]: https://www.aafp.org/pubs/afp/issues/2020/0101/p19.html "Adolescent Idiopathic Scoliosis: Common Questions and Answers"
[4]: https://www.srs.org/Patients/Resources/Video-Library/SRS-Patient-Webinar--Brace-Treatment-in-Adolescent-Idiopathic-Scoliosis1 "Scoliosis Research Society patient webinar on brace treatment"
[5]: https://dataprotection.org.gh/ "Ghana Data Protection Commission"
[6]: https://ghs.gov.gh/ "Ghana Health Service"
