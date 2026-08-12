# SpineUp Learn Content Source Notes

This note records the initial public source review for the Learn/contextual-help foundation. The first implementation deliberately uses short, non-diagnostic explanations and exposes source links rather than presenting app-authored medical claims as clinical guidance.

## Source records reviewed

| Source organization | Page | Initial use | Limitations and governance decision |
|---|---|---|---|
| Scoliosis Research Society | [SRS Bracing Manual](https://www.srs.org/Education/Manuals-and-Presentations/SRS-Bracing-Manual) | General brace terminology and the fact that brace systems differ. | The page is an historical manual with sections updated through 2009 and explicitly does not endorse one brace type. It is source-linked, not treated as a current treatment protocol. |
| NHS Inform / NHS 24 | [Scoliosis treatment for children and young people](https://www.nhsinform.scot/illnesses-and-conditions/muscle-bone-and-joints/neck-and-back-problems-and-conditions/scoliosis/scoliosis-treatment-for-children-and-young-people/) | High-level brace, exercise, and safety wording for growing people. | Last updated 7 April 2026. SpineUp will not turn its general information into personalized wear-time or treatment instructions. |
| NHS | [Treatment in adults — scoliosis](https://www.nhs.uk/conditions/scoliosis/treatment-in-adults/) | Plain-language explanation that exercise choices and safety should be discussed with a healthcare professional. | Page last reviewed 12 April 2023 with a stated next review date of 12 April 2026. It should be re-verified before release and is not used as a sole current clinical source. |
| SOSORT / Scoliosis and Spinal Disorders | [2016 SOSORT guidelines](https://pmc.ncbi.nlm.nih.gov/articles/PMC5795289/) | General terminology around assessment, bracing, and physiotherapeutic scoliosis-specific exercise (PSSE). | This is a professional guideline from 2016. It describes evidence and recommendations for professionals and patients, but SpineUp does not reproduce clinical thresholds or make progression predictions. |

## Initial canonical topics

The first content registry should include these topics:

1. **Cobb angle** — a measurement described from spinal imaging; SpineUp records what a user enters and does not interpret a trend or diagnose.
2. **Brace type** — brace names and broad categories can differ; the user should use the label provided by their clinician or orthotist.
3. **Exercise safety** — exercises should be sourced and reviewed; stop if something causes pain or concerning symptoms and ask a qualified professional before starting a new programme.
4. **Why we record measurements** — an app-specific explanation that the log stores user-entered records for personal organization and appointment conversations, not a prediction.
5. **Why we ask about sex assigned at birth** — an app-specific privacy explanation that the field is optional/sensitive and is not used to diagnose or predict progression.
6. **Export and import** — an app-specific explanation of local portability and the fact that the protected archive workflow is still being implemented.

## Review state

Until a named clinical reviewer is available, the initial records should use `sourceLinked` or `draft` states, show the source organization and URL, and display a limitation/safety note. They should not claim to be clinician-reviewed. Every topic must have one canonical record reused by both the Learn library and contextual `?` help.
