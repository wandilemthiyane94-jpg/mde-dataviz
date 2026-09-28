# Last Mile: *Same Rain, Different Words*

**Team:** Hollie and Wandile · Harvard GSD MDE

**What this project shows.** Over the last decade, South Africa's flood forecasts were usually right, and 34 of 67 floods had a warning issued beforehand. People still died. The official warnings are in English. The places where people died are overwhelmingly places where almost nobody speaks English as a first language: the median is 3.1%, and 64% of the deaths we could place were in places where fewer than 1 in 10 people do.

## For reviewers, in this order

1. **See it.** Open `prototype/game.html`, the interactive data story (v3, about 6 minutes, with headphones). Stills are in `prototype/screenshots/game/`. Earlier versions: `prototype/film.html`, the 60-second data film (v2), in Chrome, Edge or Firefox. No server or internet is needed. Class mode pauses at the audience question; use `film.html?mode=video` to play straight through, or `film.html?t=24` for a still at 24 seconds. The stills are in `prototype/screenshots/film/`. The earlier scroll version (v1) is `prototype/index.html`.
2. **Read the method.** `methods/METHODS.md` covers what was done, how AI research agents were used, the limitations, and a spot-check procedure.
3. **Check a claim.** Every event, death site and quote in `data/*.json` carries a source URL, and `methods/SOURCES.md` lists all 1,100 of them. Census language figures link to census2011.adrianfrith.com.
4. **Re-run it.** Run the scripts in `methods/scripts/` (Windows PowerShell 5.1). The processing reproduces byte-for-byte; see METHODS §4.

## Folder map

| Path | Contents |
|---|---|
| `storyboard-same-rain.md` | The narrative and design concept |
| `prototype/` | Working prototype of Acts 1–4, its data file, vendored libraries and screenshots |
| `data/` | Final datasets and analysis write-ups (`pattern_conditions.md`, `global_comparison.md`); `data/README.md` is the per-file change log |
| `data/raw/` | Unmodified research outputs, original project data, source documents, the geocoding cache and Census boundary files |
| `methods/` | `METHODS.md`, `agent_prompts.md` (every research brief), `SOURCES.md`, `geocode_log.md`, `scripts/` |

## The three caveats that matter most

- **Places, not people.** The language figures describe the places where people died (Census 2011). No victim's language or ethnicity was inferred.
- **A pattern, not a cause.** No source documents a specific person failing to understand a specific English warning. What the data shows is English-only warnings set against the languages of the places where people died.
- **Not every flood.** The event list is thorough but not exhaustive. Search limits were reached, and small local floods are under-represented.
