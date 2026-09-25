# last-mile / data

Rebuilt 2026-09-25 from `lastmile-data.zip` (Desktop, untouched) plus a web research pass covering South African floods from Jan 2016 to Sep 2026.

## Files

| File | What changed |
|---|---|
| `floods_2016_2026.json` | **New master list.** 67 events, full schema: provinces, named places, deaths (raw text + number), disaster declaration, warning issued / alert level / quotes, warning category, sources, confidence, `database_matches`. |
| `flood_timeline.json` | Went from 8 rows to 68. Original fields (`year`, `event`, `deaths`, `region`, `note`) are unchanged; new fields are `id`, `month`, `deaths_text`, `warning_category`, `confidence`, `source_count`. The 2013 Limpopo row is kept for pre-2016 context. |
| `warning_events.json` | Went from 6 rows to 69. The 6 original rows are kept verbatim (`origin: "original"`); 63 new rows have `origin: "research_2026-09"` and include `warning_quote` / `resident_quote`. |
| `stacked_locations.json` | Original rows plus `news_years_2016_2026` and `news_event_ids`. **Lamontville changed** from `high_risk_invisible` to `model_and_media_agree` because of the Feb 2025 floods, which killed 7–12+. Isipingo is flagged for review (`update_note`). |
| `database_crosscheck.json` | Raw pulls from GDACS, FloodList, DFO (Dartmouth Flood Observatory), GLIDE/ReliefWeb and NDMC (National Disaster Management Centre). Also includes EM-DAT yearly aggregates, the SAWS level-to-colour scheme, 13 reference papers, and Census 2011 language data as a fallback. |
| `database_only_events.json` | 8 database records with no matching news event, all GDACS model alerts with no reported impact. The Dec 2021 Mthatha storms have now been added to the master list. |
| `sources.json` | 241 unique URLs, each with the event ids that cite it. |
| `model_weights.json`, `media_patterns.json`, `settlement_language.json` | Copied unchanged. |

## Update 2 — language layer (2026-09-25)

| File | What it is |
|---|---|
| `floods_2016_2026.json` | Now 71 events: 4 added from `floods_addendum` (Dec 2021 Mthatha, three Feb 2026 OR Tambo/Ntuzuma events). New field `hazard_type`: `flood` / `storm` / `non_weather`. 4 events are `storm` (Dundee 2023 plus 3 thunderstorm events); Jagersfontein 2022 is `non_weather`. Filter on this for a strict flood analysis. |
| `death_site_language.json` | One object per deadly event. It lists the places where people died, deaths per place, and the **Census 2011** first-language profile for each (census2011.adrianfrith.com). Covers 44 of 53 deadly events. |
| `death_site_language_flat.json` | The same data, one row per site, for charts: `top_language`, `english_pct`, `afrikaans_pct`, `english_or_afrikaans_pct`, `warning_language_official`. **Don't sum `deaths_at_place` across rows**, because district-level rows overlap named-site rows. |
| `warning_language.json` | Who issues warnings, on which channels, and in what language, plus the relevant policy (Use of Official Languages Act 2012 s4), the cell-broadcast status and event-specific evidence. |
| `media_patterns.json` | Recoded across 53 deadly events. The original `pattern` / `recurs_in` fields are kept; new fields are `original_claim`, `verdict`, `true`, `false` and `out_of`. The full per-event coding with evidence is in `media_patterns_coded.json`. |
| `settlement_language.json` | Original rows plus `warning_language_verified`. The "English/Afrikaans" claim traces to unsourced framing in The Conversation (16 Jun 2026); Afrikaans was not verified as an official warning language. |
| `warning_events.json` | Adds `affected_dominant_language`, `death_site_english_pct_median` and `warning_language_official` to each row. |

**Headline, suburb/town-level sites with at least 1 death (113 sites, 286 deaths, all 53 deadly events):**
- **182 deaths (64%)** were at places where under 10% of residents speak English as a first language.
- **149 deaths (52%)** were at places where under 10% speak English *or* Afrikaans.
- The median English first-language share at these death sites is **3.1%**.

Only about 67 of the 435–459 April 2022 deaths could be tied to specific places, because no official per-area death table was found. 49 of those 67 were at sites where 1–3% of residents speak English (Inanda, KwaNdengezi, Mzinyathi, Clermont, Lindelani).

Most English-majority death sites fall into three groups:
- **Roads and river crossings** where motorists died: the N3, the Nahoon causeway, Margate, Amanzimtoti.
- **Places victims were visiting:** the Jukskei baptism congregants came from Alexandra, where English is 2%.
- **Established English-speaking suburbs**, above all Chatsworth and Malvern in 2019.

**Method: the unit is the place, never the person.** No victim's language or ethnicity was inferred from names. A census profile describes the place where a death happened, which may not be where the victim lived (e.g. the New Hanover 2025 victim "was from Matatiele").

**Coverage:** all 53 deadly events now have death-site language data. Mpumalanga deaths in Jan 2026 and most Feb 2021 deaths are placed at municipality level only.

**Amnesty International, *Flooded and Forgotten* (Nov 2025):** `amnesty_2025_extract.json` holds the verbatim, page-cited passages relevant to warnings, language, Lamontville, Quarry Road and the relief threshold. It adds 1 event (Dec 2024 eNkanini/Cato Manor, 2 deaths), bringing the master list to 72. It confirms the World Weather Attribution figures. It corrects the Quarry Road entry: one death by electrocution in April 2022, not "no lives lost".

**Forecasting infrastructure:** `forecasting_infrastructure.json` fact-checks 12 claims (5 verified, 7 partly, 0 false), with verbatim source quotes. It lists 17 radar sites; only Irene has published coordinates. It also records that SAWS main-radar availability fell to 52% in 2022/23 and 44% in 2023/24.

**Observing network:** `observing_network.json` lists 17 radars (16 with coordinates, from the WMO Radar Database), 188 WMO-registered surface stations and 531 DWS river gauges (from WMO OSCAR/Surface), 26 lightning sensors (count only) and 17 satellites. It is built by `methods/scripts/fetch_observing_network.ps1`; see `methods/observing_network_log.md`.

**Geocoding:** `death_sites_geocoded.json` holds all 175 death-site rows (140 high, 11 medium, 24 low confidence). Method and log: `methods/geocode_log.md`.

**Global context:** `global_comparison.md` puts South Africa's failure points alongside 19 global disasters. It draws on three data files:
- `l2_comprehension_evidence.json`: second-language comprehension research
- `global_language_cases.json`: 26 language-related warning cases
- `global_lastmile_cases.json`: 19 events coded F1–F11 and S1

**Pattern conditions:** see `pattern_conditions.md` / `.json` for when each media pattern fires (scale, national declaration, which party governs the province, period). Verified presidential visits are in `president_visits.json`.

## Caveats to review before publishing

- **Not exhaustive.** Two research agents ran out of search budget. Thin spots are 2018, mid-2019, late 2021, Aug–Sep 2024, and 2026 after January. Leads not yet checked: Jul 2026 East London (KuGompo) floods, Sep 2026 Johannesburg CBD flooding.
- **Warning categories are the researchers' judgement** using your taxonomy. The reasoning is in each event's `notes`.
- **Quotes** came through a page-summary tool for some 2020 and 2024–26 items. Spot-check them against the source URL before quoting in the piece.
- **Contested figures** are kept as ranges in `deaths_text`: Apr 2022 is 435–459 (DFO says 306), Oct 2024 is 3 vs 10, May 2026 is 4 vs 10, Jan 2026 differs between national and Limpopo-only counts.
- **Borderline inclusions**, flagged in notes: 2022 Jagersfontein tailings dam (not weather), 2023 Dundee (lightning death), 2017 Cape storm (mostly fire deaths), 2026-09 KZN (road-crash deaths).
- **Corrections to earlier assumptions:** there was no Dec 2022 Boksburg flood (that was the gas tanker explosion). The SAWS impact-based warning system went public in October 2020, not ~2019 (see `forecasting_infrastructure.json`). arXiv 2602.17726 is an AI-forecasting paper, not an event compilation. Census 2022 provincial language figures could not be fetched (Stats SA blocks automated access).
- **`media_patterns.json` counts ("7 of 7 events")** were based on the original sample and have not been recomputed for 67 events.
- **Blocked sources:** EM-DAT per-event data (needs a login), ReliefWeb (403), Stats SA.
