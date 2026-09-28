# SAME RAIN, DIFFERENT WORDS

**Team:** Hollie and Wandile · Harvard GSD MDE
### Storyboard: from the watched sky to the unheard warning (Acts 1–4)

> **Central line:** *People pray in the language they were born into. They were warned in the one they learned at school.*

The design rests on one visual metaphor and one sound metaphor.

- **Light is information.** The forecast is light. South Africa's sky is full of it. The warning is a beam sent down from Pretoria, and it only lights up the places whose language it speaks.
- **Voice is language.** The official warning speaks in one calm English voice that never changes. The people it's meant for speak, call out and pray in their own languages. The two never meet until the final scene.

---

## Numbers this story stands on (from `/data`)

| Figure | Value | Source file |
|---|---|---|
| Flood events 2016–Sep 2026 | **67** (72 including storms and a dam collapse) | `floods_2016_2026.json` (hazard_type = flood) |
| Deadly floods | **45** | same |
| Floods where a warning was issued before the event | **34 of 67** | `warning_issued = true` |
| Deadly floods that were warned | **23** | same |
| Deaths placed at a known suburb or village | **286 people at 113 sites** | `death_site_language_flat.json` |
| Deaths at sites where under 10% speak English as a first language | **182 (64%)** | same |
| Median English first-language share at death sites | **3.1%** | same |
| Warning language | **English** (no official African-language or Afrikaans warnings verified) | `warning_language.json` |

**Update 25 Sep 2026:** every **[verify]** item below has been fact-checked in `data/forecasting_infrastructure.json`: 5 verified, 7 partly verified, 0 false. The on-screen wording the prototype uses is taken from that file. Corrections: impact-based warnings went public in **October 2020**, not about 2019. SAWS runs **11** radars. Only 1 radar site (Irene) has published coordinates. SAWS use of Meteosat Third Generation data is unconfirmed. **New honesty beat:** main-radar availability fell to **52% (2022/23) and 44% (2023/24)** before recovering to 80% in 2024/25.

---

## ACT 1: THE WATCHED SKY
*Purpose: establish that this is not a failure of science. South Africa can see the storm coming.*

**Scene 1.1: Earth at night** (scroll 0–10%)
- **Visual:** a dark globe that rotates slowly toward southern Africa. Nothing is lit.
- **Sound:** a quiet room tone, and far-off rain.
- **Text:** *"On the night the water came, someone was watching."*

**Scene 1.2: The instruments switch on** (10–30%)
Each instrument lights up in turn as the reader scrolls. Every light has a label and a short caption.

| Light | What it represents | Visual |
|---|---|---|
| Satellite arc | EUMETSAT Meteosat geostationary satellites viewing Africa **[verify generation/coverage]** | a thin glowing orbit line, with a scan-sweep over SA |
| Pulsing rings | SAWS national weather radar network, **[verify count and sites]** | cyan rings pulsing at each radar site |
| Flickers | SA Lightning Detection Network **[verify]** | tiny white sparks |
| Grid shimmer | Numerical weather prediction (SAWS / Unified Model partnership **[verify]**); global flood models (GloFAS via GDACS: **61 GDACS alerts for SA** in our data) | a faint grid that ripples across the map |
| Gauges | River and rain gauges; Dept of Water & Sanitation dam monitoring (e.g. the 2022 Vaal Dam releases) | small points along the rivers |
| Nodes | Warning chain: SAWS → NDMC → provincial → municipal disaster centres | a glowing line from Pretoria to each province, then to each metro |

- **Text beat:** *"Satellites. Radar. Lightning sensors. Flood models. A colour-coded warning system built with the National Disaster Management Centre. South Africa has one of the best-watched skies in Africa."* (Pretoria's role as a WMO regional severe-weather centre is **[verify]**.)
- **Honesty beat, in small type:** *"It isn't perfect. In October 2017 the Durban radar was down during a storm that killed 8. But in most of the deaths that follow, the forecast was right."*

**Scene 1.3: The chain lights up** (30–35%)
- The whole system glows at once: a map of South Africa lit like a switchboard.
- **Text:** *"When a storm forms, this system sees it. It issues a warning. The warning goes out."*
- Hold for a moment on the bright map. Everything that follows plays against this brightness.

---

## ACT 2: IT KEEPS HAPPENING (the timeline)
*Purpose: show the pattern: accurate forecasts, then deaths, over and over, for ten years.*

**Layout.** The map stays on screen. A timeline runs along the bottom from 2016 to 2026, and a playhead moves as the reader scrolls.

**Scene 2.1: Storms arrive** (35–55%)
- For each of the 67 floods, a storm cell of soft blue light blooms over its location on the map when the playhead reaches its date.
- **Tick mark:** if a warning was issued (34 events), a small white **✓** appears on the timeline above that event, with the alert level where recorded (21 events): "Orange L9", "Red L10".
- **Dots fall:** for deadly events, the dots fall like raindrops onto the death sites, one dot per person where a per-site count exists (286 in total). Where only a total is known (e.g. April 2022, 435+), show a soft cloud of unplaced dots near the district, visibly different from placed ones. Never invent a location.
- **Pacing:** slow down on the landmark events: Durban 2017 (warned; the weather service's own head admitted most people never got it), Easter 2019, **April 2022 (435+)**, Ladysmith 2023, Lamontville 2025, **Mthatha 2025 (103)**, **Limpopo 2026 (Red L10, accurate)**. Speed up through the smaller ones so the rhythm itself says *again, again, again.*
- **Counter** (top corner): the number of warned floods counting up, and the number of lives lost counting up.

**Scene 2.2: The line** (55–60%)
- The playhead stops at today. The timeline is full of ticks, and the map is full of dots.
- **Text:** *"This isn't bad luck. And it isn't bad science. In 34 floods the warning went out. People still died in 23 of them."*
- **Quote card (Daily Maverick, Feb 2026, on Limpopo):** *"Technologically, the system worked. Socially, it faltered."*

---

## ACT 3: THE BEAM (the reveal)
*Purpose: the hidden problem. The warning is a light that only some people can see.*

**Scene 3.1: The warning goes out** (60–70%)
- Everything dims except the death dots, which glow faint red in the dark.
- From Pretoria, a single warning is sent. It's rendered as **light-text in English** spreading across the map like a sweep of torchlight: `RED LEVEL 10 — DISRUPTIVE RAIN — TAKE NECESSARY PRECAUTIONS`.
- **The key mechanic:** as the beam passes over each place, its brightness equals the share of residents who speak English as a first language (Census 2011).
  - Suburbs where English is the first language (Westville 72%, Walmer 73%) **blaze white.**
  - Tswinga (2.5% English), Slovo Park Mthatha (4.3%), Inanda (~2%), Lamontville (2%) barely flicker, and the red dots there stay in the dark.
- **Text, slowly, line by line:**
  *"The warning is light."*
  *"It reaches everyone."*
  *"It only lights up the people who speak its language."*

**Scene 3.2: The number** (70–75%)
- The screen goes black except for one figure: **64%**.
- *"Of the deaths we could place, 64% were in places where fewer than 1 in 10 people speak English as a first language."*
- Then, smaller: *"The median was 3%."*
- Then: *"Every warning was in English."*

**Scene 3.3: The honest exceptions** (75–78%)
- Briefly light the English-majority death sites (the N3, the Nahoon causeway, Margate) with a tag: *"motorists passing through"*.
- This builds trust: the reader sees we aren't hiding the dots that don't fit.

---

## ACT 4: SAME RAIN, DIFFERENT WORDS (the sound)
*Purpose: empathy. The reader should feel what it means that the warning and the person are in different languages.*

### The sound design

**Layer A: the official voice (English)**
- **Treatment:** a clean studio recording in a flat, calm, "broadcast" register, mixed dead centre at normal volume.
- **What it says:** the real warning text read verbatim, on a loop: *"The South African Weather Service has issued a Red Level 10 warning for disruptive rain…"*
- **Behaviour:** it **never changes** in pace, tone or volume, whatever happens on screen.

**Layer B: the people's voices (their first languages)**
- **Treatment:** warm, close, human, breathing voices in isiZulu, isiXhosa, Tshivenda, Xitsonga, Sepedi, SiSwati, Sesotho and Setswana.
- **What they say:** prayers, a parent calling a child's name, someone saying "the water is coming in", a neighbour shouting to wake the house. These are the everyday words people reach for in fear, and research shows emotion is carried in the first language. **Every line is written and performed by native speakers.**
- **Placement:** panned across the stereo field to match where each language's death sites sit on the map (Tshivenda far north-east, isiXhosa south-east, and so on).
- **Behaviour:** each voice's volume follows the deaths at that place. Voices swell as the reader scrolls through Act 2's death dots and overlap into a chorus, while Layer A keeps reading the warning, unchanged, over the top of them.
- **Captions:** every line is translated into English on screen, so English-speaking readers understand what is being said. The voices are people, not background texture.

**The turn (the strongest moment)**
1. The chorus peaks. The English warning is still reading "take necessary precautions".
2. **Hard cut to silence.** A black screen.
3. **Text:** *"People pray in the language they were born into."*
4. A beat.
5. *"They were warned in the one they learned at school."*

**The fix (sound resolves)**
- The same warning is now spoken **in isiZulu**, then isiXhosa, then Tshivenda, and so on, by warm voices. It no longer says "take necessary precautions". It says *what to do and where to go*: "Leave now. Go to the school on the hill."
- The prayers soften into ordinary speech: *"Sizwile."* (placeholder for "we heard"; the final wording comes from native speakers).
- On the map, the beam passes again, and **this time every place lights up.**
- **Text:** *"Same rain. Same forecast. Different words."*
- A smaller line: *"The difference between 'Level 10' and 'Leave now, go to the school' is one sentence."*

### Why this works (and why it is defensible)
- It is grounded in the research (`l2_comprehension_evidence.json`):
  - emotion is felt more strongly in a person's first language (Harris et al. 2003; Caldwell-Harris 2015);
  - stress and noise reduce second-language comprehension most (Rai et al. 2015; Garcia Lecumberri et al. 2010);
  - translated warning terms lose urgency (Trujillo-Falcón et al. 2022).
- It **dramatises the mismatch without claiming** anyone died because of a language. The pattern is shown as a pattern.

### Ethics and consent (non-negotiable)
- **No real victims' voices, names, photos or funeral recordings.** All voices are performed by consenting native speakers who are paid and credited. Ideally they come from affected communities and are invited in, not sampled.
- **Prayer is sacred.** Work with speakers on what feels respectful. Prayers can be replaced with other things people say in a flood if participants prefer.
- **The listener controls the sound:** audio is **off by default**, with a clear "Turn on sound (recommended)" invitation. There are mute and volume controls, full captions and transcripts, a content note before Act 4, and a `prefers-reduced-motion` fallback.
- **Talk about places, never ethnicity.** Always say "places where 97% speak Tshivenda", never "Venda people died".

---

## Hand-off to the next acts
- **Act 5 (explaining away):** the death-toll slider with the shifting explanations (`pattern_conditions.json`), ending on Lamontville.
- **Act 6 (not just us):** global comparisons ending with Mozambique Idai→Freddy and Quarry Road.
- **Act 7 (the rally):** the five asks, plus a ward lookup and a "hear the warning in your language" share tool.

---

## Build notes

| Piece | Approach |
|---|---|
| Map | MapLibre GL or D3 + TopoJSON of SA municipal/main-place boundaries. A dark basemap, with glow built from additive blending or SVG filters. |
| Death-site coordinates | **Needed.** `death_site_language_flat.json` has census place names and URLs but no lat/lon. Next data task: geocode the 113 sites (census main-place centroids or boundary files). |
| Instrument layer | Radar site coordinates **[verify from SAWS]**; satellite as a stylised arc, not geolocated. |
| Timeline | D3 scale on dates; ticks from `warning_issued`; labels from `alert_level`. |
| Scroll | Scrollama (already planned in `main.js`); each scene is a step with progress callbacks. |
| Audio | Web Audio API: one GainNode + StereoPannerNode per language, driven by scroll progress and deaths-at-site. The English track sits on a fixed gain. Preload after the user opts in to sound. |
| Accessibility | Captions synced to audio cues; text-only mode; colour-blind-safe palette (the brightness encoding doesn't rely on hue). |

## Open items before building
1. Verify the instrument facts marked **[verify]** (radar count and sites, Meteosat coverage, lightning network, Unified Model partnership, Pretoria's WMO regional-centre role, Google Flood Hub coverage of SA).
2. Get native speakers to write and record the Layer B lines and the fixed warnings.
3. Geocode the 113 death sites.
4. Decide on unplaced deaths: the soft-cloud treatment is proposed; the alternative is a separate counter.
