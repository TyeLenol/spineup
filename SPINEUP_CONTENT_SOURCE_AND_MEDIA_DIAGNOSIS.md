# SpineUp Content Source and Media Diagnosis

**Author:** Manus AI  
**Date:** 14 August 2026  
**Scope:** RSS/source quality, in-app article presentation, and non-YouTube video reliability.

## Executive verdict

SpineUp should stop treating arbitrary RSS HTML as if it were a polished article body. RSS is excellent for **discovery, freshness, title, summary, author, publication date, and source linking**; it is not a reliable license or format for copying an entire third-party article into the app.

The premium solution is a **two-lane content system**:

| Lane | Content source | SpineUp presentation |
|---|---|---|
| **Reviewed reading** | Manually selected, source-reviewed items from MedlinePlus, Patient.info, NHS, SRS, and similar publishers | A SpineUp-authored, clearly labeled reading brief with title, source, reviewed date, key points, limitations, safety language, and a link to the original article. |
| **Live discovery** | Verified RSS feeds | A polished card with title, source, date, short summary, topic tags, and **Read on source**. Do not copy arbitrary HTML into the app. |

This gives users a beautiful reading experience without pretending that RSS feeds provide stable article layouts or permission to republish third-party bodies.

## Verified source shortlist

### 1. MedlinePlus topic feeds — strongest technical fit

MedlinePlus publishes RSS feeds for every health-topic page and explicitly provides a scoliosis feed. The relevant endpoints are:

- [MedlinePlus Scoliosis RSS](https://medlineplus.gov/feeds/topics/scoliosis.xml)
- [MedlinePlus Spine Injuries and Disorders RSS](https://medlineplus.gov/feeds/topics/spineinjuriesanddisorders.xml)
- [MedlinePlus Back Pain RSS](https://medlineplus.gov/feeds/topics/backpain.xml)
- [MedlinePlus Guide to Good Posture RSS](https://medlineplus.gov/feeds/topics/guidetogoodposture.xml)
- [MedlinePlus What’s New RSS](https://medlineplus.gov/feeds/whatsnew.xml)

MedlinePlus says that its topic feeds contain links added to a health-topic page during the last 60 days, and its feed directory includes Scoliosis, Spine Injuries and Disorders, Back Pain, and Guide to Good Posture.[1]

**Recommendation:** make MedlinePlus the primary live discovery source. It is official, topic-specific, source-transparent, and well aligned with SpineUp’s non-diagnostic education boundary. Treat it as a link-and-summary feed, not as a full-article republishing source.

### 2. Patient.info — strongest general clinical RSS option

Patient.info exposes three official feeds:

- [Patient.info editorial features RSS](https://patient.info/rss)
- [Patient.info patient information leaflets RSS](https://patient.info/health/rss)
- [Patient.info clinical/professional articles RSS](https://patient.info/doctor/rss)

The patient-information feed is the relevant one for SpineUp because Patient.info describes it as covering clinically reviewed patient leaflets. The editorial feed contains broader health and wellbeing features, while the professional feed is written for clinicians and should not be shown as ordinary patient education.[2]

**Recommendation:** use `https://patient.info/health/rss` for patient-facing discovery and `https://patient.info/rss` for carefully filtered mindfulness, stress, lifestyle, and wellbeing articles. Exclude the professional feed from the user-facing app unless it is manually reviewed and rewritten into an appropriate plain-language brief.

### 3. Mayo Clinic RSS — useful, but attribution and licensing must be respected

Mayo Clinic states that its RSS feeds may be used for personal use or as part of a noncommercial website or blog, with proper attribution and a link to MayoClinic.org. It also explicitly prohibits reposting content or framing MayoClinic.org pages and directs organizations that want to host Mayo content to its licensing program.[3]

**Recommendation:** use Mayo RSS only for discovery cards or manually authored summaries with attribution. Do not scrape and paste Mayo article bodies into SpineUp. Because the school project is noncommercial, this is potentially suitable, but the source link and attribution must always be visible.

### 4. NHS — excellent editorial source, poor RSS fit for this use case

The NHS page discovered during testing is high quality and includes a transcript, review dates, safety information, and a detailed description of its scoliosis Pilates video.[4] However, NHS England Digital’s official RSS page exposes feeds for NHS Digital blogs, Design Matters, Transformation, Tech Talk, Data Points, cyber alerts, and statistical publications—not a general RSS feed for NHS health pages.[5]

**Recommendation:** do not rely on NHS RSS for scoliosis articles. Use NHS pages as **manually curated sources** with a SpineUp-authored summary and a visible original-source link. NHS pages are excellent source material, but they are not the best live feed for this feature.

### 5. Scoliosis Research Society — strongest specialist authority, not an RSS-first source

The Scoliosis Research Society presents itself as an international society focused on optimal care for spinal deformities and provides education resources, a journal, webinars, and the Scoliosis Dialogues podcast.[6] Its public site is a valuable curation source, but it is not currently the strongest candidate for a simple user-facing RSS pipeline.

**Recommendation:** manually curate SRS education resources, webinars, podcast episodes, glossary items, and patient-facing explanations. Use the source’s own title, date, author or speaker, and original URL. Do not invent an RSS feed where one is not clearly published.

## What should change in the app

### Articles

The current HTML extraction approach is the wrong default for a premium app. It strips tags from an entire page and displays the result as one large text block. That produces exactly the problem you saw: weak hierarchy, no headings, no image treatment, no source structure, and unpredictable navigation text or page furniture.

The article detail screen should instead use a structured `ContentBrief` model:

| Field | Purpose |
|---|---|
| `title` | Human-readable headline. |
| `dek` | One-sentence summary under the title. |
| `sourceName` and `sourceUrl` | Visible source trust cue and outbound link. |
| `publishedAt` and `reviewedAt` | Freshness and review transparency. |
| `readingTimeMinutes` | Sets expectation. |
| `sections` | Curated headings and short paragraphs rendered as real typography. |
| `keyTakeaways` | Three to five concise points. |
| `limitations` | What the source does not establish. |
| `safetyLabel` | Stop/help language where movement, pain, or distress is involved. |
| `contentOrigin` | `curated`, `rss_discovery`, or `source_reader`. |

For RSS items, SpineUp should show a **beautiful discovery card** and either open a source reader or show a reviewed short brief. For curated items, SpineUp can render a fully structured reading page. The app should never make a raw scraped third-party page look like SpineUp-authored medical advice.

### Videos

Every video card needs an explicit state: **Loading**, **Ready**, **Playing**, **Could not load**, or **Open at source**. A decorative play icon without an action is not acceptable.

YouTube is working because the app has a YouTube video ID and can initialize the iframe player. The NHS item is different: it is not a YouTube video. The official NHS page uses a Brightcove player with a page-specific media ID and player script, rather than exposing a simple `.mp4`, `.m3u8`, or YouTube URL in the item data.[4]

Therefore, the current NHS item cannot be played by the YouTube controller. If its placeholder still does not open, the failure is in the external launch path or Android intent handling, not in the video ID. The best product decision is not to reverse-engineer or deep-link into the NHS Brightcove player. Instead:

1. represent the NHS item as a **source video page**;
2. use an explicit **Open NHS video** action;
3. show a source preview image or branded video card;
4. show its verified duration, transcript availability, review date, and safety summary; and
5. provide a clear error state if the external browser cannot be launched.

On Android, the launch path should log the exact URI and the result of `launchUrl`. If `launchUrl` returns false, the app should show **“No browser could open this source”** rather than silently doing nothing. The app can also offer a copy-link action as a final fallback.

## Recommended final source strategy

| Priority | Source | Use in SpineUp | Confidence |
|---:|---|---|---|
| 1 | MedlinePlus topic feeds | Live discovery for scoliosis, spine, back pain, posture, and muscles | Highest technical and trust fit |
| 2 | Patient.info patient feed | Live discovery for clinically reviewed patient leaflets | Strong, but filter carefully |
| 3 | Patient.info editorial feed | Mindfulness, stress, wellbeing, and lifestyle discovery | Useful with editorial review |
| 4 | NHS pages | Manually curated articles and videos | High quality, weak RSS fit |
| 5 | SRS education resources | Manually curated specialist education | Highest scoliosis specificity, lower automation |
| 6 | Mayo Clinic RSS | Discovery and attributed summaries | Good, but stricter reuse boundaries |

## Final recommendation

For the school-project demo, I recommend replacing the current generic HTML reader with **curated structured article briefs** and a separate **RSS discovery list**. Use MedlinePlus and Patient.info as the live feed layer. Manually curate NHS and SRS content into beautiful SpineUp briefs. Keep the original source link prominent. For videos, keep YouTube embedded and treat NHS/Brightcove videos as source pages with strong preview cards and an explicit external-browser fallback.

This approach gives users the quality they deserve while preserving source attribution, avoiding false medical authority, respecting content reuse boundaries, and making every media state understandable.

## References

[1]: https://medlineplus.gov/rss.html "MedlinePlus RSS Feeds"
[2]: https://patient.info/rss-feeds "Patient.info RSS Feeds"
[3]: https://www.mayoclinic.org/about-this-site/guidelines-sites-linking-to-mayo-clinic "Mayo Clinic Guidelines for Sites Linking to MayoClinic.org"
[4]: https://www.nhs.uk/live-well/exercise/pilates-and-yoga/scoliosis-pilates-exercise-video/ "NHS Scoliosis Pilates Video Workout"
[5]: https://digital.nhs.uk/about-nhs-digital/rss-feeds "NHS England Digital RSS Feeds"
[6]: https://www.srs.org/ "Scoliosis Research Society"
