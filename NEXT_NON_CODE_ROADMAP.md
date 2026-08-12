# SpineUp: Next Steps Without Writing Code

## Executive recommendation

The next phase should be a **product-definition and validation sprint**, not another implementation sprint. The stabilization branch now has a passing Flutter quality gate and a coherent prototype baseline.[1] Before adding backend services, real authentication, community infrastructure, or more gamification, the team should decide what SpineUp is allowed to promise, who it is for, what data it is allowed to collect, and what the first release must prove.

The goal of this phase is to leave the team with a signed-off product brief, a user-tested critical journey, a data-and-privacy position, a safety policy, and a release checklist. Only after those decisions are stable should implementation resume.

## 1. Decide the product boundary

SpineUp currently spans onboarding, daily activities, journal/check-ins, Cobb-angle tracking, appointments, gamification, profile progression, and Community. That is too broad for an initial release unless the team explicitly defines which surface is the product and which surfaces are prototypes.

The recommended initial product boundary is: **a private, local-first scoliosis self-management companion focused on daily check-ins, activity adherence, appointment preparation, and personal progress history**. Community, social identity, real authentication, and clinician-facing synchronization should be treated as later-stage capabilities rather than prerequisites for the first validated release.

| Decision | Recommended position | Why it matters |
|---|---|---|
| Primary user | A person with scoliosis, with a parent or caregiver considered as a secondary participant | Determines language, consent, accessibility, and onboarding requirements |
| Core promise | Help users reflect on daily symptoms and routines and prepare better for care conversations | Avoids implying diagnosis, treatment, or clinical prediction |
| First-release loop | Check in → complete a small routine → review progress → prepare for appointment | Gives the product one measurable recurring behavior |
| Secondary features | Gamification and profile customization support retention but do not define clinical value | Prevents reward mechanics from becoming the product’s main promise |
| Deferred features | Community, real OAuth, cloud sync, clinician portal, and public sharing | These add identity, moderation, privacy, and operational obligations |

## 2. Choose the trust and data model

The team must make one explicit decision between two product models. The current prototype behaves like a local-first app with mock authentication, while some of its screens imply account-based behavior. That ambiguity should end before backend work begins.[1]

The safer near-term choice is **local-first by default**. Under that model, health entries remain on the device, account creation is optional or absent, export is user-initiated, and the app clearly states that it is not a replacement for professional medical care. If the team instead chooses cloud accounts, it must first define identity ownership, recovery, consent withdrawal, deletion semantics, encryption, retention, support access, and breach response.

A decision workshop should answer the following questions in writing:

1. Is an account required to use the core daily loop?
2. What happens when a user changes devices or loses the device?
3. Can a parent manage a minor’s account, and how is that relationship represented?
4. Which data can be exported, deleted, or shared?
5. What information is never sent to analytics or Community?
6. Who can access a report, post, or moderation record?

No external authentication provider should be selected until these answers exist.

## 3. Validate the user journey before expanding the feature set

The next non-code activity should be a small, structured usability study. The objective is not to prove that people like the visual design; it is to discover whether the intended user understands the product’s purpose and can complete the core loop without confusion or unsafe interpretation.

Test the following journey using the current prototype or clickable screens:

> A new user understands the app’s purpose, gives appropriate consent, completes onboarding, records a daily check-in, completes one routine, finds their progress history, and prepares a question for an upcoming appointment.

Recruit at least three user perspectives: a person living with scoliosis, a parent or caregiver, and—if available—a clinician or scoliosis-informed physiotherapist reviewing language and risk boundaries. Do not collect real health records during informal testing. Use scripted scenarios and synthetic data.

| Research question | Evidence to collect | Decision threshold |
|---|---|---|
| Does the user understand what SpineUp is for? | User restates the purpose in their own words | Most participants describe support/tracking, not diagnosis or treatment |
| Is onboarding too long or intrusive? | Drop-off points, hesitation, questions about sensitive fields | Every field has a clear reason or is removed/deferred |
| Does the user understand XP and streaks? | Verbal explanation of what rewards mean | Users do not interpret XP as clinical improvement |
| Can the user correct a mistaken entry? | Edit and recovery behavior | A mistaken journal entry can be corrected without duplicate reward or confusion |
| Can the user find useful progress information? | Time-to-find and interpretation of Journey | Users can distinguish personal history from medical measurement or prediction |
| Are safety boundaries clear? | Reactions to pain, brace, and Cobb-angle language | No critical screen implies that the app diagnoses or adjusts treatment |

## 4. Establish health-safety and content governance

Before publishing health-related copy, the team should create a lightweight content review process. Every symptom, brace, pain, Cobb-angle, exercise, and appointment interaction should have an owner and a safety classification.

The team should define three content categories. **Tracking content** records what the user reports. **Educational content** explains general concepts with clear limitations. **Action content** recommends or changes what the user should do. The first release should emphasize tracking, keep education carefully reviewed, and avoid automated action recommendations.

The product should also define escalation language for concerning inputs. The app does not need to diagnose, but it should have reviewed copy for situations such as severe or worsening pain, new neurological symptoms, breathing difficulty, acute injury, or distress. That copy should direct users to appropriate professional or emergency help rather than awarding, withholding, or interpreting XP.

A clinician review is especially important for exercise content, brace-related framing, Cobb-angle interpretation, and any claim that a routine improves progression, pain, or adherence.

## 5. Decide whether Community belongs in the first release

Community is not simply another screen. It creates moderation, abuse reporting, age-related safety, privacy, identity, content retention, and crisis-response obligations. In the current prototype, posts and reports are held in widget memory, so Community should not be treated as production-ready.[1]

The recommended decision is to **defer public Community until the team has a moderation model**. If the team keeps it in the prototype for user research, label it clearly as a non-production preview and use synthetic content. Before enabling real posting, define:

- who may post and whether minors can participate;
- whether users are pseudonymous or identifiable;
- how harassment, medical misinformation, self-harm content, and personal-data exposure are handled;
- how reports are triaged and how quickly action is expected;
- what content is retained, deleted, or exportable; and
- who is accountable for moderation outside business hours.

## 6. Define success measures before implementation resumes

The next sprint should not be measured by the number of screens or packages added. It should be measured by whether the product’s core hypothesis is supported.

| Metric | Initial question |
|---|---|
| Onboarding completion | Can the intended user complete onboarding without abandoning or misunderstanding consent? |
| First-session comprehension | Can the user explain what the app does and does not do? |
| Daily-loop completion | Can users complete a check-in and one routine in a reasonable session? |
| Correction success | Can users fix an entry without duplicate history or reward? |
| Appointment usefulness | Do users say the history helps them prepare a question or summarize their experience? |
| Safety comprehension | Do users know when SpineUp is not an adequate substitute for professional care? |
| Retention signal | Do users return because the loop is useful, not only because a streak is at risk? |

The team should choose concrete targets only after the first usability sessions establish realistic baselines.

## 7. Prepare a release-readiness decision record

Before the next coding sprint, produce one short decision record with the following sign-offs:

| Area | Required sign-off |
|---|---|
| Product | Target user, first-release promise, included surfaces, deferred surfaces |
| Clinical/content | Reviewed language for exercises, symptoms, brace tracking, measurements, and escalation copy |
| Privacy | Local-first versus cloud model, consent, deletion, export, analytics, and data retention |
| Safety | Boundaries for medical claims, urgent symptoms, minors, and community content |
| Design | Critical journey, accessibility baseline, empty/error/loading states, and terminology |
| Engineering | Canonical data model, auth boundary, persistence strategy, migration policy, and CI gate |
| Operations | Support contact, incident ownership, moderation ownership if applicable, and release rollback plan |

The decision record should explicitly list unresolved questions. An unresolved decision is acceptable; an implicit decision is not.

## Recommended sequence

The most efficient order is a **one-week decision sprint**:

| Stage | Outcome |
|---|---|
| Day 1 | Product boundary and first-release promise agreed |
| Day 2 | Local-first/cloud, identity, consent, and deletion position agreed |
| Day 3 | Critical user journey tested with synthetic data |
| Day 4 | Clinical/content and safety review of health-related copy |
| Day 5 | Community decision, success measures, and release gates documented |
| End of week | Go/no-go decision for the next implementation sprint |

The next implementation sprint should begin only if the team can state, in one paragraph, **who SpineUp serves, what it promises, what it refuses to promise, what data it keeps, and what behavior the first release is trying to improve**.

## What should not happen next

The team should not add more screens, introduce a backend, configure OAuth, open public Community, or expand gamification until the product boundary and trust model are agreed. Those changes are expensive to reverse because they affect data ownership, user expectations, privacy language, and the architecture of every subsequent feature.

## References

[1]: https://github.com/TyeLenol/spineup/tree/stabilize/architecture-and-critical-fixes "SpineUp stabilization branch"
[2]: https://github.com/TyeLenol/spineup/actions "SpineUp GitHub Actions quality history"
