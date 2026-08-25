# SpineUp Implementation Gap Assessment and No-Code Plan

**Audit baseline:** `stabilize/architecture-and-critical-fixes` at `f483829`
**Scope:** Compare the current implementation with `SPINEUP_PRODUCT_AND_ARCHITECTURE_DECISION_RECORD.md`
**Constraint:** This assessment makes no code, commit, branch, or remote changes.

> **Health note:** I am an AI, not a medical professional. This is product and safety analysis, not medical diagnosis or treatment advice. A qualified clinician should review consequential health content before publication.

## Executive finding

The stabilization branch is now a technically healthier Flutter prototype, but it is still structurally closer to a **single-user gamified tracker with a mock social feed** than the agreed SpineUp product: a **private, local-first care-subject workspace for individuals and caregivers, with protected portability, source-aware health content, explicit safety boundaries, and Community only when governed well**.

The most important gap is not a missing screen. It is the absence of the conceptual boundary:

> **Session owner → one or more care subjects → subject-specific profile, events, routines, appointments, history, rewards, and exports.**

Today, almost all health data still hangs directly off one session-level `user_id`. Until that distinction exists, caregiver mode, multiple wards, safe switching, subject-specific export, and future optional cloud sync cannot be implemented reliably.

## Current state versus target state

| Capability | Current implementation | Agreed target | Gap severity |
|---|---|---|---|
| Self-use | Supported through a single local mock session | Supported as one valid workspace mode | Partial |
| Caregiver/ward use | Not modeled | Caregiver can manage one or more care subjects | **Critical** |
| Active-subject switching | Not available | Always-visible subject context and safe switching | **Critical** |
| Local-first trust | Partially communicated | Clear local-first, no-analytics, user-control promise | **High** |
| Export/import | No user-facing workflow | Protected, human-readable archive with preview and conflict policy | **Critical** |
| Local protection | Privacy copy claims encrypted database, but no verified encryption/device-auth flow is present | Honest, platform-supported protection with accurate wording | **Critical** |
| Cloud | UI copy frames syncing as an account capability, but auth is mock | Optional, explicit, user-initiated future backup/sync | **High** |
| Daily loop | Check-in, hardcoded routines, XP, streaks, and appointment preview exist | Check-in → routine → review, with source-aware routines and subject context | Partial |
| Learn library | No Learn screen/content model found | Articles/videos with source, owner, review state, date, limits | **Critical** |
| Journey | Chart and timeline exist | Clearly user-recorded history without clinical progression implication | **High** |
| Appointments | Scheduling and notes exist | Preparation questions, measurement summary, pre/post notes | Medium |
| Community | Active top-level tab, seeded and in-memory feed | Governed subsystem or Coming Soon | **Critical** |
| Auth | Email/Google/Apple are mock paths using one mock session | Optional cloud later; local core does not depend on account | High |
| Safety escalation | No complete urgent-symptom flow or Ghana-reviewed directory | Reviewed non-diagnostic safety messaging and local escalation path | **Critical** |
| Quality | CI now resolves, formats, analyzes, and tests successfully | Add tests for new care-subject, portability, content, and release gates | Partial |

## Critical gaps that must be resolved first

### 1. Care-subject architecture is missing

`ProfileData`, `UserProfile`, SQLite `user_profiles`, `events`, and `appointments` all assume one profile per `user_id`. `SessionService` still exposes one mock identity, `local_user_001`. Profile setup asks for a name, date of birth, sex assigned at birth, treatment stage, curve details, brace, physiotherapy, symptoms, and goals, but never asks whether the workspace is for the user or someone else. There is no caregiver relationship, ward record, active-subject context, subject switcher, or multi-subject export.

This is the **highest-priority architecture gap**. It affects every downstream feature, not only onboarding. The future boundary must distinguish:

- the session owner or caregiver;
- the care subject whose health data is being recorded;
- the relationship and permissions between them; and
- the subject currently selected in the UI.

The first implementation plan must include a migration strategy from current `user_id`-scoped records to subject-scoped records. The migration must preserve existing local data and must never silently attach a user’s history to the wrong subject.

### 2. Portability and local protection do not exist yet

There is no export/import service or UI. The current Me screen provides appearance, notifications, a short privacy dialog, and destructive deletion. It does not provide an archive, passphrase, import preview, conflict policy, attachment handling, or cloud-backup setting.

The privacy dialog says the database is encrypted, but the current SQLite helper does not show a verified encryption layer. This is a trust-critical mismatch. Until the implementation verifies encryption, the product should say that data is stored locally and protected by the device/app sandbox—not that the database itself is encrypted.

The target portability design must answer these questions before implementation:

| Portability decision | Required answer |
|---|---|
| Archive contents | Profiles, care-subject relationships, events, appointments, routines, content bookmarks, saved Community state if applicable, and attachments |
| Protection | User-chosen passphrase or equivalent secure protection; no unprotected health archive by default |
| Human readability | JSON/CSV-like content inside a clearly documented archive, while preserving typed metadata |
| Import behavior | Validate, preview target subject and record counts, then choose merge or replace |
| Duplicate handling | Stable IDs and deterministic conflict rules; never silent duplication |
| Attachments | Explicitly include, separately protect, or clearly report that they were omitted |
| Failure behavior | Transactional import with rollback; never leave a half-imported subject |

### 3. Entry and consent messaging contradict the approved product

Onboarding still markets an active peer community, “curve progression” tracking, streaks, and brace/exercise logging before explaining the care-subject model. Auth says “we’ll set up your diagnosis” and the guest warning says device changes lose data while encouraging account creation for syncing. That conflicts with the agreed product: private local-first use, protected export/import, optional future cloud, and no claim to diagnose.

The consent step is closer to the target because it says on-device by default and cloud off, but it still exposes an anonymous analytics toggle even though the decision is **no analytics for now**. It also does not explain export/import rights, deletion scope, caregiver ownership, or the distinction between a caregiver and a care subject.

This needs a **product-truth pass** before feature work. The first-run experience should explain purpose, non-diagnostic boundaries, local storage, portability, deletion, and “Me versus Someone I care for” before sensitive profile fields.

### 4. Health content is hardcoded, not governed

Today contains a hardcoded exercise catalog with instructions and cues, but no content model, source, author, review status, review date, evidence note, contraindication/stop guidance, or licensed video/article link. There is no Learn area. The current content therefore cannot meet the approved requirement for source-aware articles and exercise videos.

This is also a safety gap. The product currently presents specific movements such as side planks, thoracic extension, bird-dog, pelvic tilt/bridge, child’s pose, and wall angels as ready-to-follow activities. Because the team is not acting as clinicians, the app should not imply that these are appropriate for every person, curve pattern, age, treatment stage, or pain state.

The content plan must establish a registry with at least:

| Content field | Purpose |
|---|---|
| Title and type | Article, video, exercise, routine, or educational note |
| Source organization/author | Allows users to assess provenance |
| Source URL or license | Prevents untraceable content and link rot |
| Review state | Source-linked, reviewed, draft/community |
| Reviewer and review date | Establishes accountability |
| Audience and limitations | Prevents general information being read as individualized treatment |
| Safety/stop language | Tells users to stop and seek appropriate advice when needed |
| Last verified date | Supports maintenance |

### 5. Journey wording can imply clinical interpretation

Journey currently labels the chart **“Cobb Angle Progression”** and tells users to log a first reading to “track curve progression over time.” It also overlays pain and stretches on the same chart. The approved boundary says the app may show user-entered measurements but should not infer that a curve is improving, worsening, safe, or dangerous.

The gap is primarily wording and interpretation, but it is important. A safer target is **“Your recorded measurements”** with a visible note that Cobb-angle readings come from user-entered or clinician-provided records and should be discussed with a qualified professional. The chart should show dates and sources but avoid clinical trend conclusions.

Profile copy also says sex-at-birth affects “progression-risk insights,” but the current implementation does not provide a reviewed, evidence-backed risk model. That phrase should not remain unless the team decides to build and clinically review such a model; the recommended decision is to remove the promise and keep the field optional for personalization or recordkeeping.

### 6. Community is active but not releasable under the agreed trust model

Community is wired as a permanent navigation tab. It seeds posts on load and keeps posts, replies, saves, upvotes, and the moderation queue in widget memory. Reports only produce a debug print. Authors are represented by display names rather than a pseudonymous identity model. There is no persistent post store, moderation lifecycle, blocking, age-safety policy, report ownership, content review, or operational response process.

Some seeded content also makes health-adjacent claims, including that a curve change is “genuinely really good” or that a stretch helps morning stiffness. Those claims are not suitable as ungoverned community facts.

The plan should not delete Community conceptually, since it is part of the product vision. Instead, it should put Community behind a release gate:

> **If moderation, reporting, blocking, pseudonymity, age safety, and operational ownership are not ready, Community becomes Coming Soon or is omitted from navigation. The private core app must remain complete without it.**

### 7. Appointments lack preparation and follow-up structure

Appointment scheduling, editing, notes, completion, and attendance XP exist. The gap is that notes are generic free text. There is no structured question list, symptom summary, measurement summary, pre-visit preparation, post-visit outcome, or subject-aware context.

A good appointment workspace should help a user prepare a conversation, not create the impression that the app is the clinical record. It should distinguish:

- questions I want to ask;
- symptoms or concerns I reported;
- recorded measurements I may want to show;
- notes from the visit; and
- follow-up actions I personally choose to remember.

### 8. Authentication and guest language still imply cloud dependence

The implementation has a centralized session boundary, but authentication remains mock. Email, Google, and Apple paths all resolve to the same local mock identity, and the UI frames account creation as the way to prevent device-loss and enable sync.

This is acceptable as a prototype implementation detail, but not as the product’s trust story. The product should present local use as complete, not as an inferior guest mode. Real authentication and optional cloud sync should be a later, separately governed subsystem.

## Recommended no-code implementation sequence

### Phase 0: Decision and content preparation

No implementation should begin until the team approves the following documents: the product brief, care-subject model, privacy/portability brief, clinical-content policy, and Community go/no-go checklist. The remaining unresolved decisions are the minimum independent age/guardian policy, archive attachment strategy, Ghana-reviewed escalation wording, content reviewer ownership, and Community operational owner.

The output of this phase is not a screen. It is a signed decision pack and a content inventory showing which current exercise and Community claims are source-linked, reviewed, rewritten, or removed.

### Phase 1: Care-subject foundation

Implement the conceptual and data boundary first. Create the session-owner versus care-subject relationship, allow “Me” or “Someone I care for,” support multiple subjects for a caregiver, and make the active subject visible and switchable. Migrate current local records to a single clearly selected subject with a safe one-time migration flow.

The acceptance gate is that a caregiver can switch between two synthetic subjects and verify that profiles, events, appointments, rewards, charts, and deletion actions never cross subjects.

### Phase 2: Trust and portability

Add the local protection policy, accurate privacy copy, no-analytics consent state, export archive, protected import, preview, conflict handling, and subject-scoped deletion. Do not enable cloud yet. The acceptance gate is a phone-change simulation using synthetic data: export, transfer, import, verify all records and attachments, and confirm that invalid or wrong-passphrase archives fail safely.

### Phase 3: Safety and Learn content system

Replace the hardcoded exercise-only presentation with a source-aware content structure. Create the Learn experience for articles and videos, add source/review metadata, rewrite non-diagnostic language, remove unsupported progression-risk promises, and add reviewed stop/escalation language. Update Journey to display recorded measurements rather than inferred progression.

Add a named **contextual help capability** throughout profile setup and selected clinical or sensitive app surfaces. A small `?` icon should open a short plain-language explanation, followed by a **Learn more** action. Learn more should open a near-full-screen mobile modal or page with a clear `×` close control, the longer explanation, limitations, source links, review metadata, and related topics. Use this selectively for terms such as brace type, curve type, Cobb angle, treatment stage, data export, and deletion rather than beside every ordinary field.

Each topic must have one canonical content record that powers both the short contextual explanation and the longer Learn view. This prevents the profile tooltip, Learn library, and future article/video from drifting into contradictory or outdated explanations. The record should retain the source organization/author, URL or license, review state, reviewer and date, audience, limitations, safety/stop language, and last-verified date.

The acceptance gate is a content review checklist: every health claim has a source, owner, review date, limitation note, and safe presentation. A Ghana-based reviewer must verify the local escalation directory before release. Every contextual-help topic must resolve to its canonical record and must avoid diagnosing, predicting progression, or prescribing treatment.

### Phase 4: Complete the private daily loop

Connect Today, Learn, routines, daily check-ins, Journey, and Appointments around the active care subject. Let users save content into a personal routine without presenting it as an individualized prescription. Add structured appointment preparation and post-visit notes. Ensure XP rewards adherence to user actions, never clinical outcomes.

The acceptance gate is a full synthetic journey: create a self profile, create a caregiver/ward profile, check in, open a source-linked exercise, save it, complete a routine, review history, prepare for an appointment, export the subject, and delete or restore it safely.

### Phase 5: Community decision and gated delivery

Run the Community trust review only after the private core works. If the team has moderation ownership, pseudonymous identity, reporting, blocking, age safety, persistence, abuse handling, and a content policy, then Community can be implemented as a separate governed subsystem. If not, replace the active tab with Coming Soon or remove it from navigation.

The acceptance gate is operational, not merely technical: the team can explain who receives a report, who acts on it, how quickly, what gets retained, and what happens when the content involves medical misinformation or a vulnerable user.

### Phase 6: Release validation

Run usability sessions with a self-user, a parent/caregiver, and—if available—a clinician or scoliosis-informed physiotherapist. Use synthetic data. Measure weekly return intent, completion of the check-in → routine → review loop, trust in local storage, export/import success, caregiver subject-switch accuracy, and comprehension of the non-diagnostic boundary.

Only after these pass should the team decide whether the app is ready for a public store release, a closed pilot, or another validation cycle.

## What to fix first when coding resumes

| Order | First implementation work | Reason |
|---|---|---|
| 1 | Care-subject/session model and migration | Every health record and future feature depends on correct ownership |
| 2 | Entry/consent/trust flow rewrite | The current product promise conflicts with the agreed local-first model |
| 3 | Protected export/import and accurate privacy controls | This is the core user-trust promise for changing phones |
| 4 | Learn/content metadata and clinical-safety wording | Current exercises and Journey copy are not governed enough for a health app |
| 5 | Subject-aware Today/Journey/Appointments | Makes the full private daily loop coherent |
| 6 | Community gate or Coming Soon state | Prevents an ungoverned social feature from undermining trust |
| 7 | Additional validation and release hardening | Confirms that the product works for both self-users and caregivers |

## Final assessment

The branch has a solid prototype foundation: the daily check-in, routine interaction, appointment scheduling, Journey visualization, profile setup, event ledger, and CI are real pieces. However, it lacks the **trust architecture** and **care-subject architecture** that define the product we have now agreed to build.

The correct next move is not to add more screens. It is to redesign the product around ownership and portability, then make health content and Community earn their place through review and governance. Once those decisions are accepted, the implementation sequence above gives us a clean path from the current single-user prototype to the intended private, caregiver-capable SpineUp app.

## References

[1]: https://github.com/TyeLenol/spineup/tree/stabilize/architecture-and-critical-fixes "SpineUp stabilization branch"
[2]: https://github.com/TyeLenol/spineup/actions "SpineUp GitHub Actions quality history"
[3]: https://link.springer.com/article/10.1186/s13013-017-0145-8 "2016 SOSORT guidelines: orthopaedic and rehabilitation treatment of idiopathic scoliosis during growth"
[4]: https://www.aafp.org/pubs/afp/issues/2020/0101/p19.html "Adolescent Idiopathic Scoliosis: Common Questions and Answers"
[5]: https://dataprotection.org.gh/ "Ghana Data Protection Commission"
[6]: https://ghs.gov.gh/ "Ghana Health Service"
