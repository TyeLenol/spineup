# SpineUp Content Discovery and Saved Routine Plan

## Direct answer

The feature is not part of the current implementation, but it fits SpineUp well and can be added. It was not included in the earlier build because the current milestone focused on private local records, the core daily loop, source-aware canonical Learn topics, and reliable navigation. Live external feeds introduce source-quality, platform, caching, Web CORS, and content-availability concerns that should be designed rather than bolted onto the static Learn registry.

## Important interpretation of “saved to the app”

For YouTube, SpineUp should save a **bookmark/reference** to a video, not download the video file. The app can store the video ID, source URL, title, channel, thumbnail URL, category, and the user’s saved-routine placement, then play the video through the official YouTube embedded player when the user opens it. YouTube’s official policies prohibit API clients from downloading, caching, or storing copies of audiovisual content without prior written approval and prohibit offline playback [1].

This still gives the user the desired experience: they browse a video, tap “Save,” add it to “My routine,” and open the routine later to watch it during the exercise session. If the video is deleted, made private, or unavailable, SpineUp can show “Video unavailable” and let the user remove or replace the saved reference.

## Recommended experience

Learn should become the home for external educational content without weakening its canonical topics. The top-level Learn experience should have three filters or tabs: **Topics**, **Articles**, and **Videos**. A fourth **Saved** filter can show saved articles and videos, while “My routine” remains accessible from Today and contains selected exercise videos alongside the existing guided exercises.

The article/video cards should show the title, publisher or channel, content type, publication date where available, source label, and a short source-status badge such as “External source” or “SpineUp topic.” Cards should never imply that SpineUp reviewed or endorsed every feed item. The detail view should show the source, open/play action, limitations, and a save action. Canonical Learn topics remain the place for reviewed explanations, safety language, and contextual `?` help.

## Content sources

Start with a small allowlist rather than arbitrary web search. For articles, use stable official feeds from sources such as MedlinePlus health-topic feeds and selected NHS or other public-health feeds. MedlinePlus explicitly provides RSS feeds for health-topic pages and identifies the feed items as links added to its topics within the last 60 days [2]. This is technically useful, but it still does not mean every linked article is a SpineUp-reviewed recommendation.

For videos, begin with a manually curated set of trusted scoliosis, physiotherapy, exercise-safety, mindfulness, and stress-relief channels or specific approved video IDs. YouTube’s official Data API supports retrieving a channel’s uploads playlist and its items [3]. It is not the same as unrestricted “search all YouTube” functionality, which would require an API key, quota management, policy compliance, and stronger moderation. The embedded-player package can play approved YouTube IDs in Android and Web without storing video files [4].

## Viable implementation options

| Approach | What the user gets | Tradeoffs | Cost | Setup complexity |
|---|---|---|---|---|
| **Curated feeds and approved channels in Flutter** | Browse a small set of health articles and videos, save references, add videos to My Routine, and play them in-app | Best fit for the school project, but Web may need a small feed proxy if sources block browser cross-origin requests; no arbitrary YouTube search | Low package/development cost; no YouTube Data API key required for playback | Moderate |
| **Manual content catalog with periodic JSON updates** | The same polished Articles/Videos/Saved/Routine experience, with predictable content and no live-fetch failures | Not truly live; someone must update the catalog manually; less impressive as a feed feature | Lowest | Low |
| **Full live content service** | Arbitrary article/feed search, broader YouTube discovery, server-side normalization, caching, moderation, and source management | Adds a backend, API keys/quota, Web CORS handling, source moderation, privacy/policy work, and more failure points than this school project needs | Higher ongoing setup/maintenance | High |

## Recommendation

Use the first option, but keep the source list curated and the feature explicitly external-content based. It demonstrates real RSS integration, useful browsing, saving, routine personalization, and embedded video playback without introducing cloud storage of health data or an overbuilt backend. If the Web build encounters CORS restrictions, the fallback should be either a tiny read-only public-feed proxy or opening the source in the external browser; do not weaken the Android/local-first path to solve Web feed fetching.

## Data model boundary

Do not turn remote articles/videos into `LearnTopic` records. Add a separate `ExternalContentItem` model with `id`, `type`, `title`, `description`, `sourceName`, `sourceUrl`, `contentUrl`, optional `videoId`, optional `thumbnailUrl`, `publishedAt`, `fetchedAt`, `category`, `contentStatus`, and `safetyLabel`. Add a subject-scoped `SavedContentItem` or `RoutineItem` record that stores the external item ID/reference, order, saved date, and optional completion count. Store metadata only, not remote article bodies or YouTube video bytes.

The feed cache can be public-content metadata rather than health data. User saves and routine selections must remain subject-scoped and local, and if portability is later expanded they should be included as metadata references with clear unavailable-content behavior.

## Safety and product rules

Only show content from an allowlisted source catalog. Use categories such as Scoliosis, Movement, Mindfulness, Stress relief, Caregiving, and General health. Do not auto-label a feed item as “safe exercise” merely because its title contains exercise words. Videos should display a short reminder that general content is not a personalized prescription, and users should stop if an activity causes pain or concerning symptoms.

Do not reward reading an article or watching a video with health claims. If gamification is used, reward the user for organizing or completing a self-chosen routine, not for a medical outcome. Keep external articles and videos separate from canonical reviewed topic explanations so the trust boundary remains visible.

## References

[1]: https://developers.google.com/youtube/terms/developer-policies "YouTube API Services Developer Policies"
[2]: https://medlineplus.gov/rss.html "MedlinePlus RSS Feeds"
[3]: https://developers.google.com/youtube/v3/guides/implementation/videos "YouTube Data API: Implementation: Videos"
[4]: https://pub.dev/packages/youtube_player_iframe "youtube_player_iframe package"
