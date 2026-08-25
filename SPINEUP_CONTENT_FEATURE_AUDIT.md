# SpineUp Content Feature Audit

## Current state

The current Learn surface is a local, statically defined `LearnTopic` registry. It supports title, category, short explanation, body, audience, limitations, safety note, review state, last-verified date, sources, related topics, search, category filtering, source display, and contextual `?` help. It does not fetch RSS, query YouTube, cache remote content, open external media, or save articles/videos.

The current exercise catalogue is a `const` list inside `today_screen.dart`. Each local exercise has a name, description, duration, icon, and guided timer steps. Exercises can be completed and logged as events, but users cannot add remote videos or articles to a personal routine. There is no content table, saved-content table, feed cache, or routine-item table in the current persistence boundary.

## Proposed capability boundaries

A future content layer should not replace canonical Learn topics. It should introduce separate records for external content, because a feed item has different fields and trust requirements: source URL, publisher, content type, thumbnail, published date, fetched date, source category, safety label, and availability state. Canonical Learn topics remain the authoritative definitions used by contextual help; remote content remains linked material that can be browsed, opened, and optionally saved.

Exercise videos should be saved by stable URL/YouTube video ID and metadata, not by downloading and copying the video into the archive. In-app playback can use an embedded player or hand off to YouTube, while offline video storage is a separate capability with licensing, storage, and platform constraints. A saved routine should store references to approved content plus ordering and completion metadata, not arbitrary remote content bytes.

RSS is suitable for publisher-owned article feeds when a source publishes a stable feed. RSS alone is not a reliable universal YouTube search API; YouTube channel feeds, official YouTube APIs, or curated video URLs are different source strategies. A school-project implementation should start with a small allowlist of trusted sources and curated feeds rather than scraping arbitrary search results.

## Verified YouTube constraints

The official YouTube Data API documentation describes retrieving a channel’s uploads by resolving the channel’s uploads playlist and then calling `playlistItems.list`; this is a channel/playlist discovery path, not unrestricted keyword search without API access [1]. The official YouTube IFrame Player API supports embedding and controlling playback, including queueing, play, pause, stop, seeking, and playback events [2]. The appropriate school-project model is therefore to store stable video IDs/URLs and metadata locally, then embed or open the YouTube player; downloading video files for offline storage is not part of the basic embed API and would introduce separate licensing, storage, and platform concerns.

[1]: https://developers.google.com/youtube/v3/guides/implementation/videos "YouTube Data API: Implementation: Videos"
[2]: https://developers.google.com/youtube/iframe_api_reference "YouTube IFrame Player API Reference"

## Verified article-feed options

NHS England publishes public RSS feeds for organizational blogs, alerts, and statistical publications, but a general NHS feed is not automatically a scoliosis-specific or mindfulness-specific editorial catalog [3]. MedlinePlus, a U.S. National Library of Medicine service, publishes RSS feeds for every health-topic page and states that topic feeds contain links added during the last 60 days [4]. This makes MedlinePlus a more useful technical model for topic-based health discovery, but SpineUp should still label the publisher, date, source link, and the fact that linked content is external rather than treating every feed item as a SpineUp-reviewed recommendation.

[3]: https://digital.nhs.uk/about-nhs-digital/rss-feeds "NHS England Digital RSS feeds"
[4]: https://medlineplus.gov/rss.html "MedlinePlus RSS Feeds"

## Verified Flutter implementation options

The verified `rss_dart` package supports RSS 1.0, RSS 2.0, Atom, Media RSS, Dublin Core, and podcast namespaces; it is published by a verified publisher and depends on standard HTTP/XML packages [5]. The verified `youtube_player_iframe` package embeds YouTube through the official IFrame API, requires no API key for playback, supports Android and Web, and recommends static thumbnails for list items so a WebView/player is created only after the user taps [6]. That is a strong fit for a polished list-and-detail experience.

[5]: https://pub.dev/packages/rss_dart "rss_dart package"
[6]: https://pub.dev/packages/youtube_player_iframe "youtube_player_iframe package"

## Verified YouTube policy boundary

YouTube’s official developer policies prohibit API clients from downloading, importing, backing up, caching, or storing copies of YouTube audiovisual content without prior written approval, and prohibit making that content available for offline playback [7]. The policies allow a client to use the embedded player, but stored API data has refresh/delete obligations and must remain consistent with current YouTube data [7]. Therefore “save to the app” should mean save a bookmark/reference and routine placement, not download the video file. The app should refresh metadata, handle unavailable/deleted videos gracefully, and provide a delete-saved-item action.

[7]: https://developers.google.com/youtube/terms/developer-policies "YouTube API Services Developer Policies"

## Candidate seed content

The official NHS scoliosis Pilates video page describes a 32-minute Pilates-inspired class and gives explicit safety guidance: the class is general exercise information, users should seek professional advice when unsure or when health conditions/symptoms apply, and users should stop if they feel pain or become unwell [8]. This is an appropriate model for SpineUp’s video metadata and safety notice. It should be presented as an external NHS resource, not as a SpineUp-prescribed routine.

[8]: https://www.nhs.uk/live-well/exercise/pilates-and-yoga/scoliosis-pilates-exercise-video/ "NHS scoliosis Pilates video workout"

The MedlinePlus bones/joints/muscles topic page visibly offers a central “Subscribe to RSS” link back to the RSS directory rather than exposing a direct topic-feed URL in the rendered page. The implementation will therefore use verified directory/feed URLs only, or keep the source as a curated external article URL if a stable direct feed cannot be confirmed.

The NHS page exposes a first-party HTML5 video with a reviewed date, transcript/audio-description controls, and explicit safety text rather than a YouTube ID. This supports treating NHS media as an external article/video link that can be opened in a web view or browser, while YouTube content uses the embedded YouTube player. The source’s own 2025 media review date and stop-if-pain guidance should be shown in the content detail rather than copied as SpineUp medical advice.
