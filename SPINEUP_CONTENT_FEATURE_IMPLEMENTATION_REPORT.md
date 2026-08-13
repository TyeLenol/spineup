# SpineUp Curated Content Feature Implementation Report

## Summary

SpineUp now has a separate external-content layer inside Learn. The feature supports curated and RSS-fetched articles, curated exercise and education videos, local saved references, a Saved view, and Add to My Routine for exercise videos. The implementation does not download or store remote video files. YouTube items play through the embedded player, while first-party web media and articles can open at their original source.

## User-facing flow

Learn now contains four sections: Topics, Articles, Videos, and Saved. Topics remains the canonical source-aware registry used by contextual help. Articles and Videos display external content with the publisher/channel, category, source label, summary, and safety note visible in the card/detail flow. Users can save a card locally and remove it later.

Exercise videos expose an **Add to My Routine** action. Saved exercise-video references appear in Today’s focused routine sheet underneath the existing guided exercises. Opening one launches the detail/player flow, where the user can watch the embedded YouTube item or open a first-party source. The existing guided exercise timer and completion/XP behavior remain unchanged.

## Architecture and privacy boundary

`ExternalContentItem` is deliberately separate from `LearnTopic`. Remote content has different fields and trust semantics: content type, publisher, source URL, content URL, optional video ID/provider, thumbnail URL, publication date, fetch timestamp, category, and safety label. The content service stores public feed metadata in a bounded cache and stores user save/routine IDs using owner-plus-active-care-subject-scoped SharedPreferences keys.

The app stores only metadata and stable references. It does not store a YouTube audiovisual copy or claim that external content is SpineUp-reviewed. This preserves local-first health-data behavior and keeps source attribution visible. Learn is keyed to the active care subject so saved content from one profile does not remain visible after switching to another profile.

## Feed and source strategy

The initial feed refresh reads selected public RSS sources and filters entries using a small relevance allowlist covering scoliosis, spine, back, posture, muscles, exercise, mindfulness, stress, wellness, pain, and mental health. Curated content remains available when a feed is unavailable or blocked. The seeded catalogue includes an NHS scoliosis Pilates video, a Scoliosis Research Society education video, a clearly labelled external YouTube movement video, MedlinePlus posture material, and NHS-linked mindfulness material.

The implementation intentionally avoids unrestricted search. A future full search service would require more source moderation, API-key/quota handling, Web CORS/proxy behavior, and content lifecycle work than the school project needs.

## Validation

The first remote analyzer run caught three service-level issues: a non-constant seed timestamp, RSS publication dates arriving as strings, and the resulting analyzer diagnostics. Those were corrected in a focused follow-up commit. The corrected workflow, [run 31661332612](https://github.com/TyeLenol/spineup/actions/runs/31661332612), passed dependency resolution, formatting, analyzer, and the full automated test suite. The branch head is `ecd76e3` and the working tree is clean.

## Known limitations

Direct RSS refresh may be restricted on Web by publisher cross-origin policies; curated content still works, and a future read-only proxy or external-browser fallback can be added if Web feed refresh is required. Remote metadata can become stale or unavailable, so the UI must handle deleted/private videos and dead article URLs gracefully. Saved references are currently local SharedPreferences metadata; extending archive export/import to include them is a separate follow-up rather than a reason to store remote media bytes.

## Why this is the right school-project scope

The feature demonstrates genuine feed parsing, source-aware browsing, local personalization, saved exercise routines, and embedded video playback while preserving SpineUp’s non-diagnostic, local-first identity. It adds visible usefulness without turning the project into an uncontrolled web search engine or cloud content platform.
