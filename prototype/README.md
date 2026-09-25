# Prototypes

## v3 - `game.html`: interactive data story (current, about 6 minutes)

**The journey:**
1. **A good day:** sun, no rain.
2. **Night, in the rain:** a warning plays over community radio and appears as a post in a community group (a generic social-feed look, no platform branding). The text is a **real isiZulu warning** issued by eThekwini on 27 Jun 2023.
3. **"What do you do?":** six everyday choices, shuffled. Five lead to **GAME OVER**: the water rises, and the screen and sound are drowned out. One (walk to the hall on the hill) means you live, *by luck*.
4. **The data:**
   - what the warning actually said (it never says what to do);
   - South Africa's warnings are in English;
   - the watched sky (real stations);
   - ten years of floods;
   - the 286 people (4 in 5 in non-English-speaking places);
   - second-language research;
   - "What does Level 9 mean?" (a quiz, with real quotes);
   - the **braille twist** (can you read this?), plus the sign-language fact;
   - a world map of language-driven failures and fixes.
5. **Back to the game:** same day, same rain. The warning now comes in your language and says where to go. You live.

**The rising water:** with every screen the page floods a little more. The water rises, the page blurs and desaturates, sound is muffled by a low-pass filter, and rain and droplets streak the glass. The replay drains it.

**Controls.** Continue button / Space / right arrow: next. Left arrow: back. Poster mode for review: `game.html?scene=<id>` (ids: title, goodday, night, reveal, flip, sky, years, people, second, levels, braille, worldmap, day2, night2, end); add `&p=0..1` for animated scenes, `&over=drown|live` for the outcome card, `&reveal=1` for the quiz or braille answer. Stills: `screenshots/game/`.

**Content and sources:** `methods/scripts/game_content.ps1` defines the choices, the illustrative plain-language warning, the research figures (each with a DOI) and the world cases (each with URLs). `build_prototype_data.ps1` bundles it into `data/story-data.js`.

**Honesty notes:**
- The household is fictional; the place and the isiZulu warning are real.
- The English translation of the warning is ours and needs a native-speaker check.
- The replay warning is illustrative, not issued.
- The world map is not a controlled comparison.
- Braille is uncontracted (Grade 1) English, generated letter by letter.
- The sign-language fact is sourced to The Presidency and Parliament (19 Jul 2023).
- Radio voice: see `audio/README.md`. Native-speaker recordings are preferred; synthetic voices are placeholders.
## v2 - `film.html`: 60-second data film

| Scene (s) | What it shows | Data |
|---|---|---|
| 0-9 Hook + question | A real official isiZulu warning (eThekwini newsflash, 27 Jun 2023), then the question *What does this warning tell you to do?* Class mode pauses here. | `data/warning_language.json` (verbatim text + URL) |
| 9-15 Reveal | The translation: it only says "heed the warning", never what to do | Project translation, **pending native-speaker check** |
| 15-19 Flip | Official warnings are in English; most people in the places where flood deaths happen grew up speaking something else | `warning_language.json` |
| 19-26 Watched sky | Every real station at its published position: 16 radars, 188 weather stations, 531 river gauges, plus 17 weather satellites; radar availability caveat | `data/observing_network.json` (WMO OSCAR, WMO Radar Database) |
| 26-35 Ten years | 67 floods, 34 warned beforehand (ticks), one dot per placed death | `floods_2016_2026.json`, `death_sites_geocoded.json` |
| 35-44 The people | The 286 dots regroup into a 22x13 grid, coloured by the expected first-language mix of the places they died: **228 not English, 58 English** | `death_site_language.json` (top-3 Census 2011 shares, remainder = Other, largest-remainder rounding) |
| 44-48 Typical place | Median death site: 3 in 100 residents speak English as a first language | `stats.median_english_pct` |
| 48-56 World | Bangladesh, Odisha, Mozambique before/after local-language warnings (circle area per row; not a controlled comparison) | `global_language_cases.json`, `global_lastmile_cases.json` |
| 56-61 Close | The forecast was right. The words weren't. | |

**Why the design changed from v1.** v1 lit each place by its English share, which made English-majority suburbs glow and look like the majority. v2 shows people as equal-sized dots, so the proportion is literal.

**Controls.** Space: play/pause, or reveal at the question. Right/left arrows: next/previous scene. R: restart. H: hide controls (for screen recording). URL options: `?mode=video` (no pause), `?record=1` (autostart, no UI), `?t=SECONDS` (still frame).

**To make a video file:** open `film.html?record=1` full-screen and screen-record, for example with Xbox Game Bar (Win+Alt+R) or OBS.

**Not yet real:** the isiZulu translation needs native-speaker confirmation; there is a Tshivenda slot in `build_prototype_data.ps1` (the `$hook` block) for when a verified Tshivenda warning is sourced. No radar range rings are drawn, because the 200 km figure is unverified.

---

## v1 - `index.html`: scroll prototype



A working prototype of the story mapped out in `../storyboard-same-rain.md`, built on the project's real data.

## How to open
Double-click `index.html`. It runs from the file system with no server or internet, because all libraries are stored locally in `vendor/`. Scroll to move through the story. Sound is optional; turn it on with the button at the top right.

Tested target: current Chrome, Edge and Firefox on desktop. The English voice uses the browser's built-in text-to-speech, so it varies by system.

## What is real and what is placeholder

| Element | Status |
|---|---|
| Flood events, warning ticks and alert levels | **Real**, from `data/floods_2016_2026.json` (hazard_type = flood) |
| Death dots (one per person) | **Real**: sub-place/main-place death sites with per-place counts, from `data/death_sites_geocoded.json`. Deaths that couldn't be placed are counted in the timeline caption but not drawn. |
| Brightness of each place in the beam | **Real**: Census 2011 English first-language share at that site |
| "64%", median English share, n | **Computed** by `methods/scripts/build_prototype_data.ps1` |
| Forecasting-system facts in "The watched sky" | **Only verified claims** from `data/forecasting_infrastructure.json` are displayed |
| Radar rings | Drawn only for radar sites with published coordinates in that file. Currently 1 of 17 (Irene); the others are listed without coordinates. |
| Scene stills | `screenshots/` holds 14 renders made with headless Edge in poster mode (`index.html?scene=<name>&p=<0-1>`) |
| Pretoria → provincial capital lines | **Schematic**; capital positions are approximate |
| English warning voice | **Placeholder**: browser text-to-speech reading *illustrative* wording in SAWS impact-based format. **Not a verbatim SAWS warning.** |
| Voices in African languages | **Placeholder tones**, one per language, panned to where that language's death sites are and louder where more people died. To be replaced with consented recordings by native speakers (see the storyboard's ethics section). |
| Translated warnings in the "fix" scene | **Not yet produced**; they need native-speaker translation and recording |

## Rebuild the data
```powershell
cd ..\methods\scripts
.\build_prototype_data.ps1     # writes prototype\data\story-data.js
```
The prototype reads only `data/story-data.js`, so every on-screen number traces back to the audited data files.

## Files
- `index.html`: the prototype (HTML/CSS/JS in one file)
- `data/story-data.js`: generated data (don't edit by hand)
- `vendor/`: d3 v7 and topojson-client v3 (from cdn.jsdelivr.net/npm), plus world-atlas 50m country boundaries (Natural Earth, public domain) wrapped as JS
