# How Apps Present External Articles and Videos

**Author:** Manus AI  
**Date:** 14 August 2026  
**Purpose:** Explain the real delivery models behind polished reading and video experiences, then choose the correct hybrid for SpineUp.

## The short answer

Most polished apps do **not** use RSS alone to create a beautiful in-app reading experience. RSS is usually the **discovery layer**: it provides a title, link, publication date, author, summary, image, and sometimes the full article body.

Apps then choose one of four delivery models:

| Model | What the app receives | What the user sees | Typical use |
|---|---|---|---|
| **RSS discovery** | XML metadata and a summary/link | A native card, then the original source | News aggregation, topic feeds, lightweight content tabs |
| **Reader extraction** | The original web page fetched and cleaned by a parser | A clean typography-first article view | Read-it-later and RSS-reader products |
| **In-app browser** | The original web page rendered by a real browser engine | The publisher’s actual page inside a branded browser surface | External sites with JavaScript, video players, cookies, captions, or complex layouts |
| **Licensed/structured content** | An agreed article format, API response, CMS export, or publisher feed | A fully native editorial layout controlled by the app | Apple News-style publishing, partner content, premium editorial apps |

For video, the equivalent models are **official embed SDKs**, **publisher-provided player pages**, **direct media files**, and **source-page browser viewing**. A YouTube video can be embedded through YouTube’s official iframe/player API. An NHS Brightcove page cannot be treated as if it were a YouTube video.

## Model 1: RSS is a feed, not a magazine page

RSS is an XML syndication format. A feed may contain only a headline and link, a summary and link, or the entire article body. Full-text feeds exist, but they are not guaranteed. FiveFilters describes this distinction directly: a partial feed expects the reader to visit the original page, whereas a full-text feed includes the article in the feed itself.[1]

This explains why different apps can look very different while consuming the same RSS feed. One app may show a clean card and open the source. Another may fetch the linked page and extract its main content. A third may have a commercial content agreement and receive a structured article payload. The RSS URL alone does not determine the final reader design.

## Model 2: Full-text extraction, used by serious RSS readers

Established readers such as **Inoreader** and **Feedbin** use an additional full-content step for feeds that provide only partial content. Inoreader describes a user-triggered “Load full content” action that fetches the source page and saves the extracted version when possible.[2] Feedbin similarly says it can extract the full content of an article for feeds that only offer partial content.[3]

The important detail is that this is **not RSS magic**. It is a server-side or local web-page extraction pipeline:

1. The app receives the RSS item and its source URL.
2. It fetches the original HTML page.
3. An article-extraction algorithm identifies the title, byline, main content, images, links, and publication information.
4. The output is sanitized before being rendered.
5. The app shows a clean reader view and keeps the publisher/source link visible.

Mozilla’s open-source **Readability.js**, the library used for Firefox Reader View, exposes this exact model. It parses a DOM document into a title, HTML content, text content, length, excerpt, byline, site name, language, and publication time.[4] Mozilla also warns that untrusted extracted HTML should be sanitized and recommends a sanitizer such as DOMPurify plus defense-in-depth security controls.[4]

This is why SpineUp’s current parser looks poor: it removes tags from arbitrary HTML and displays one large text block. It does not preserve a real document structure, select images intelligently, sanitize rich HTML, handle embeds, or distinguish an article body from page navigation.

## Model 3: An in-app browser or Custom Tab

Many apps appear to let users read external pages “inside the app,” but they are actually opening a browser surface that remains visually connected to the app.

On Android, **Chrome Custom Tabs** are designed for this purpose. Android’s documentation says Custom Tabs let developers add a customized browser experience directly within an app while using the user’s preferred browser engine, state, cookies, permissions, and security features. Android specifically recommends Custom Tabs when an app directs users to external domains, while WebView is more appropriate when the app hosts its own content or must inject JavaScript.[5]

A Custom Tab can preserve the source page’s:

- JavaScript and embedded media player;
- captions and transcripts;
- cookie and consent behavior;
- responsive layout;
- browser security features;
- publisher navigation; and
- original attribution and advertising model.

It can still feel like SpineUp by using a branded toolbar color, an in-app transition, and an obvious return path. This is often the most reliable way to show an NHS page or a publisher’s complex video player without trying to recreate the publisher’s infrastructure.

Flutter’s `webview_flutter` package is a different option. It renders a WebView inside the app and supports page progress, navigation decisions, HTTP errors, web-resource errors, JavaScript, and platform-specific media behavior.[6] It gives SpineUp more visual control, but it also means SpineUp inherits WebView compatibility, cookie, media, and security maintenance. For arbitrary external domains, Android’s own guidance favors Custom Tabs over WebView in many cases.[5]

## Model 4: Licensed or structured content

The highest-quality native reading experiences are usually built from **structured content agreements**, not arbitrary scraping. Apple News is a clear example: publishers submit content and use Apple News Format or the Apple News API to publish articles with controlled typography, layout, media, and interactive components.[7]

That model works because the publisher or content owner has agreed to provide the material in a structured form. The receiving app can safely design a native article page because it owns or licenses the structured content rather than guessing how to extract it from a public webpage.

For a school project, SpineUp does not need formal publisher partnerships. It can achieve the same visual principle by creating a small set of **manually reviewed SpineUp reading briefs** that contain original summaries, source links, and clearly marked attribution. The app should not copy third-party article bodies or images without the appropriate permission.

## What successful apps do with RSS and articles

The common pattern is a separation between **Feed** and **Library**. Readwise documents this explicitly: its Feed contains automatically pushed RSS content, while its Library contains content the user intentionally saves. When a user saves an article through its browser extension, Readwise obtains the rendered browser content and creates a clean, readable version rather than relying only on a URL.[8]

This separation is valuable for SpineUp:

| SpineUp area | Equivalent pattern | Behavior |
|---|---|---|
| **Articles** | Feed/discovery | Native cards from RSS metadata; source-first reading for unreviewed items |
| **Saved** | Library | User-selected items saved locally with source, date, and review state |
| **Reviewed Reading** | Clean reader library | Manually curated structured briefs with stable layout and safety framing |
| **Original source** | Browser/source view | Custom Tab or source browser for the publisher’s exact page |

## What successful apps do with videos

YouTube’s official IFrame Player API supports loading a video by ID, responding to player-ready and state-change events, and controlling playback through documented methods. Its documentation distinguishes between cueing a video and loading/playing it: cueing prepares the player, while `loadVideoById` loads and plays the video.[9]

This maps directly to SpineUp:

- YouTube source + video ID: use the official YouTube player and show player state/error feedback.
- NHS/Brightcove source page: open the official NHS page in a Custom Tab or reliable browser surface.
- Direct MP4/HLS source supplied by a publisher: use a native video player only if the source explicitly provides a stable, permitted media URL.
- Unknown source: show a source preview and an explicit **Open original video** action. Never show a dead play icon.

## Why the current SpineUp strategy failed

The previous implementation mixed three different content types into one generic detail page:

1. YouTube videos were embedded correctly enough to load.
2. The NHS video was treated as a generic item with a decorative placeholder even though it uses a Brightcove player page.
3. Articles were fetched as raw HTML and reduced to plain text.

That combination creates the exact symptoms you reported: YouTube works, the NHS item does not play, and articles look unattractive.

## The correct SpineUp architecture

SpineUp should use a **hybrid content resolver** with an explicit `ContentDeliveryMode`:

```text
ContentDeliveryMode
├── curatedBrief
├── rssDiscovery
├── readerExtraction
├── customTab
├── youtubeEmbed
└── unsupportedSource
```

### `curatedBrief`

Used for reviewed MedlinePlus, Patient.info, NHS, and SRS items. The body is authored or reviewed by SpineUp in a structured format:

```text
headline
summary
source metadata
reading time
sections[]
key takeaways[]
limitations
safety / stop language
original source URL
review status
```

### `rssDiscovery`

Used for live feed results. The app shows the title, source, publication date, summary, tags, and a strong **Read on source** action. It does not pretend that a live RSS item is a fully reviewed SpineUp article.

### `readerExtraction`

Used only as an optional fallback for trusted, permitted sources. It should use a real reader parser such as Mozilla Readability, preserve safe HTML structure, sanitize output, normalize images and links, and expose the original source. It should be tested per publisher rather than applied blindly to every URL.

### `customTab`

Used for NHS/Brightcove pages, pages with JavaScript players, pages with captions/transcripts, and sources where the publisher’s own layout is the most reliable reading experience. On Android this is preferable to a blank or broken custom parser for arbitrary external domains.[5]

### `youtubeEmbed`

Used for YouTube IDs through the official player. The screen should show loading, ready, playing, paused, ended, and error states. The user should always have an **Open in YouTube** fallback.

## Decision matrix for SpineUp

| Option | Visual control | Source fidelity | Reliability for external sites | Licensing risk | Recommended? |
|---|---:|---:|---:|---:|---|
| Raw RSS summary | High | Low | High | Low | Yes for discovery only |
| Raw HTML strip-to-text | Medium | Low | Low | Medium | No |
| Mozilla Readability + sanitizer | High | Medium | Medium | Medium | Only for approved sources |
| Flutter WebView | High | High | Medium | Low-to-medium | Selectively |
| Android Custom Tab | Medium | Very high | High | Low | **Yes for external source pages** |
| YouTube official embed | High | High for YouTube | High for YouTube | Low when used as intended | **Yes** |
| Manually curated structured brief | Very high | Controlled summary | Very high | Lowest when original | **Yes for demo content** |
| Full copied third-party article | High | High | Medium | High | No without permission/licensing |

## Final recommendation

For SpineUp’s Android/Web school-project demo, use this order:

1. Keep RSS for discovery metadata and filtering.
2. Replace the current raw article text block with curated structured reading briefs for the items users are expected to read in the demo.
3. For uncurated RSS items, show a polished summary card and open the original in a source browser rather than displaying a broken pseudo-article.
4. Use Android Custom Tabs or the supported in-app browser mode for NHS and other JavaScript-heavy external pages.
5. Keep YouTube embedded through the official player and add a clear source fallback.
6. Add publisher-specific delivery policies so MedlinePlus, Patient.info, NHS, SRS, and Mayo do not all go through one parser.
7. Keep original source, author, publication/review date, limitations, and safety language visible.

The core principle is simple:

> **Use RSS to discover. Use structured content to present. Use a real browser to preserve external pages. Use official embeds to play external media.**

### References

[1]: https://help.fivefilters.org/full-text-rss/ "FiveFilters: Full-Text RSS"
[2]: https://www.inoreader.com/blog/2022/11/how-to-take-advantage-of-the-full-content-view-in-inoreader.html "Inoreader: Full Content View"
[3]: https://feedbin.com/ "Feedbin: RSS and Full-Text Reading"
[4]: https://github.com/mozilla/readability "Mozilla Readability.js"
[5]: https://developer.android.com/develop/ui/views/layout/webapps/overview-of-android-custom-tabs "Android Developers: Custom Tabs"
[6]: https://pub.dev/packages/webview_flutter "Flutter WebView package"
[7]: https://developer.apple.com/documentation/applenews/getting-started-as-an-apple-news-publisher "Apple News Publisher Documentation"
[8]: https://docs.readwise.io/reader/docs/faqs/adding-new-content "Readwise Reader: Adding Content"
[9]: https://developers.google.com/youtube/iframe_api_reference "YouTube IFrame Player API Reference"
