# Same Rain, Different Words: research brief

**Team:** Hollie and Wandile · Harvard GSD MDE

**Thesis.** South Africa's flood forecasts are usually right. The warnings still fail at the last mile, because they arrive in a language most of the people at risk don't speak as a first language, and in a form (colour codes, levels, no instruction, no destination) that even fluent readers can't act on. When people die, official explanations blame where people live, or climate change, rather than the warning chain.

## What we collected
| | |
|---|---|
| Flood events, Jan 2016 – Sep 2026 | **72** (67 floods, 4 storms, 1 mine-dam failure); 45 deadly floods |
| Articles read and coded for media framing | **199**, across 53 deadly events |
| Unique sources cited across all datasets | **1,100 URLs** (full list in `methods/SOURCES.md`) |
| Cross-checked databases | GDACS, GLIDE/ReliefWeb, Dartmouth Flood Observatory, FloodList, NDMC declarations, EM-DAT (aggregates only) |
| Deaths placed at a suburb or village | **286 deaths at 113 sites**, each matched to Census 2011 home language |
| Observing network mapped | 17 radars, 188 weather stations, 531 river gauges (WMO databases), 17 satellites |
| International comparison | 19 disasters coded on 11 failure points; 26 language-in-warning cases; 24 research findings on second-language comprehension |

## South Africa: language
- **Warnings go out when the forecasts are right, and people still die.** In **34 of 67** floods a warning was issued beforehand, and people died in **23** of those.
- **Where people die, almost nobody speaks English as a first language:**
  - **64%** of placed deaths were in places where fewer than 1 in 10 residents speak English as a first language;
  - the **median** English first-language share at a death site is **3.1%**;
  - in the places where the 286 people died, **4 in 5** residents (228 of 286) grew up speaking another language: isiZulu 109, isiXhosa 48, Afrikaans 25 and others. English accounts for 58.
- **The warnings themselves are English only.**
  - Official warnings (from SAWS, the NDMC, the provinces and municipalities) are issued in **English**. No official Afrikaans or African-language warnings were verified; eThekwini's isiZulu posts are ad hoc.
  - This is despite the **Use of Official Languages Act (2012)**, which requires at least 3 languages, and **12 official languages**, including South African Sign Language since 19 Jul 2023.
  - South Africa has no public cell-broadcast system for emergency alerts.
- **Even in English, the warnings aren't understood:**
  - Limpopo, Jan 2026: *"very few had an idea of what [Level 10] meant"*;
  - KwaZulu-Natal, 2026: *"What is a level 4 and what does that mean?"*;
  - Walmer Airport Valley: **210 of 270** residents had never received a warning, and 88% trust isiXhosa community radio.
- **What works:** Quarry Road (Durban) runs a community WhatsApp-and-whistle warning system, and **no one drowned there** in April 2022.

## Correlations and patterns (media coding, 53 deadly events)
All of these patterns are **conditional on scale** (the size of the death toll):

| Pattern | Small (1–4 deaths) | Mid (5–19) | Mass (20+) |
|---|---|---|---|
| Death toll reported as rising | 0% | 81% | 71% |
| Blame put on "informal settlement" or "building in the wrong place" | 28% | 52% | **86%** |
| Climate change named as a cause | 12% | 33% | **71%** |
| President visits | 8% | 5% | 57% |

- **Officials dominate the coverage.** Articles quote **187 officials and 58 residents**, and **29 of 53** events quote no resident at all.
- **The warning chain is almost never the story.** Only **3 of 71** events are framed as a last-mile failure, and 32 have no discussion of the warning at all.
- **President visits follow party lines.** All **9** presidential flood visits were to ANC-governed provinces, and none went to the Western Cape (DA), despite 3 national disasters there.
- **The "wrong place" frame is used even where the state chose the place.** Lamontville, Feb 2025: 5 people died in a relocation camp that eThekwini itself built on a riverbank, after the Auditor-General had warned about such sites.
- **Relief follows the same threshold as the coverage.** Municipal relief is released only when a "major incident" is declared.

## Around the world
- **The common last-mile failures (out of 19 disasters):**
  - no instruction on what to do or where to go: 13;
  - accurate forecast, but the last mile failed: 13;
  - alert not understood: 11;
  - channel failure: 11;
  - "officials sent it, residents never got it": 11;
  - warning came late or at night: 10.

  South Africa shows all six.
- **Language failures elsewhere:**
  - **Mozambique:** during Cyclone Idai (2019, 600+ dead), warnings went out mostly in Portuguese and 33% of people lacked information in a language they understood. For Cyclone Freddy (2023, fewer than 200 dead), community radio broadcast in local languages.
  - **Bangladesh:** the Bhola cyclone of 1970 killed ~300,000; Cyclone Amphan in 2020 killed 26. About 76,000 volunteers relay warnings in spoken Bangla.
  - **Odisha, India:** the 1999 cyclone killed 10,000+; Cyclone Fani in 2019 killed several dozen, with loudspeaker warnings in the local language.
  - **Philippines:** during Typhoon Haiyan (2013), people didn't understand the English term "storm surge".
  - **New York:** in Hurricane Ida (2021), the 11 basement deaths were nearly all immigrants; alerts now go out in 14 languages.
- **Second-language research:**
  - stress slows reading in a second language but not in a first (Rai 2015);
  - noise hurts non-native listeners more (Garcia Lecumberri 2010);
  - a "tornado watch" was understood by **66%** of English speakers but **38%** of Spanish speakers given the official translation (Trujillo-Falcón 2022);
  - emotional words carry less force in a second language (Harris 2003).
- **The gap.** No study has tested whether people understand SAWS warnings in South African languages.

## Caveats
- **Places, not people:** language is measured for the place where each death happened (Census 2011). No individual's language or ethnicity was inferred.
- **A pattern, not a cause:** the data shows a strong pattern, not proof of what caused any one death.
- **The event list is thorough but not exhaustive.**
- **Some quotes need checking:** some came through page summaries, so check them against the source before citing.
- **The world comparisons are not controlled.**
- **The research used AI agents,** each given a written brief (in `methods/agent_prompts.md`). The processing reproduces byte-for-byte (`methods/METHODS.md`).

## Key sources
- Mokhele & Mvanyashe 2025, Walmer Airport Valley survey, IJDRR: https://doi.org/10.1016/j.ijdrr.2025.105573
- Amnesty International 2025, *Flooded and Forgotten* (AFR 53/0369/2025): https://www.amnesty.org
- eThekwini isiZulu warning, 27 Jun 2023: https://www.durban.gov.za/press-statement/Isexwayiso+Ngesimo+Sezulu
- Daily Maverick, Limpopo warnings: https://www.dailymaverick.co.za/article/2026-02-16-anatomy-of-a-disaster-how-sas-warning-systems-stalled-during-the-floods/
- South African Sign Language, 12th official language: https://www.thepresidency.gov.za/president-cyril-ramaphosa-enact-sign-language-12th-official-language
- Trujillo-Falcón et al. 2022: https://doi.org/10.1175/BAMS-D-22-0050.1
- Rai et al. 2015: https://doi.org/10.1037/a0037591 · Garcia Lecumberri et al. 2010: https://doi.org/10.1016/j.specom.2010.08.014
- Thieken et al. 2023, Ahr valley survey: https://nhess.copernicus.org/articles/23/973/2023/
- Translators without Borders, Cyclone Idai: https://translatorswithoutborders.org/in-need-of-words-using-local-languages-improves-comprehension-for-people-affected-by-cyclone-idai-in-beira-mozambique/
- WMO, Mozambique early warnings: https://wmo.int/site/science-action/weather-forecasts-and-early-warnings/mozambiques-life-saving-early-warning-systems
- Census 2011 by place: https://census2011.adrianfrith.com
- Full bibliography: `methods/SOURCES.md`

**Prototype:** `prototype/game.html` (interactive, about 6 minutes).
