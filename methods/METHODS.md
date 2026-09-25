# Methods & provenance: *Same Rain, Different Words*

This document explains how every dataset in `data/` was produced, so a reviewer can check any figure, trace it to a source, and re-run the processing.

**Research period:** 24–25 September 2026 · **Author:** Wandile Mthiyane (Harvard GSD/MDE) · **Research assistance:** Claude (Anthropic) coding agents, as described in §2.

---

## 1. What is claimed, and how it can be checked

| Headline claim | Where it comes from | How to check it |
|---|---|---|
| 67 floods (72 events incl. storms) in SA, Jan 2016 – Sep 2026 | `data/floods_2016_2026.json` | Every event carries `sources[]` with URLs; `confidence` = high (2+ independent sources) / medium / low |
| 34 of 67 floods had a warning issued beforehand; 23 of those were deadly | same file, field `warning_issued` | Filter `hazard_type == "flood"` |
| 286 deaths located at 113 suburb/village-level sites | `data/death_site_language_flat.json` | Rows with `geo_level` = sub place / main place and `deaths_at_place >= 1`; each row has a `death_source_url` |
| 64% of those deaths were at places where <10% speak English as a first language; median English share 3.1% | same | Each row's `census_url` links to the Census 2011 page with the language table |
| Official warnings are issued in English; no official Afrikaans or African-language warnings were verified (eThekwini isiZulu newsflashes are ad hoc) | `data/warning_language.json` | `issuers[].evidence_urls` |
| Media patterns (e.g. "informal settlement" as cause: 28% → 52% → 86% by scale) | `data/media_patterns_coded.json`, `data/pattern_conditions.json` | Per event: `urls_read`, verbatim `evidence`, coder `note`; cross-tabs reproduced by `methods/scripts/join.ps1` |
| All 9 presidential flood visits were to ANC-governed provinces | `data/president_visits.json` | Evidence quote + URL per event; "no visit" = no report found, not proof of absence |
| Global comparison (19 disasters, failure points F1–F11) | `data/global_lastmile_cases.json` | Evidence + URL per code; `unclear` = no source found |
| Second-language comprehension research | `data/l2_comprehension_evidence.json` | DOI per finding |

**Recommended spot-check for reviewers.** Pick 10 random events and 10 random death sites. Open each `sources[].url` / `death_source_url` and `census_url`, and confirm the death count, place and language figures.

---

## 2. How the research was done (including AI assistance)

The desk research was carried out with **Claude Code research sub-agents**. Each was given a written brief (reproduced in `methods/agent_prompts.md`) and had web search and page-fetch tools. Every brief contained the same rules:

- include only events or claims found in a real source, with its URL;
- never invent numbers, quotes or URLs;
- use verbatim quotes;
- leave unknown fields `null`, and record contested figures as ranges with an explanation.

**What this means for a reviewer**
- The agents gathered and structured the evidence. They were not the final authority on any claim.
- The main risk is a source being misread, not a source being fabricated. Some pages (News24, IOL, ReliefWeb) blocked automated access, and some quotes were taken from a page-summary tool. Where either happened, the record's `notes` says so. **Spot-check quotes against the source before citing them.**
- Coding decisions (warning category, media patterns P1–P6, failure points F1–F11) are the agents' judgement on the cited evidence. The reasoning is in each record's `notes`.
- Agents hit a 200-searches-per-session limit in places. So the event list is **not exhaustive**, particularly for 2018, mid-2019 and late 2021.

---

## 3. Pipeline

```
original_lastmile-data (the project's first 6 JSON files)
            │
 Stage A: event research (5 agents)  ──► raw/floods_2016_2018 … floods_2024_2026.json
            │                              raw/structured_sources.json (GDACS, FloodList, DFO, GLIDE, NDMC)
 Stage B: gap-filling                ──► raw/floods_addendum.json, raw/floods_amnesty.json
            │
 merge.ps1 ─────────────────────────► floods_2016_2026.json (master), flood_timeline.json,
            │                          warning_events.json, stacked_locations.json, sources.json,
            │                          database_crosscheck.json, database_only_events.json
 Stage C: death-site language (4 agents) ► raw/death_site_language_*.json   (Census 2011 via cen.ps1)
 Stage D: media-pattern coding (1 agent) ► raw/media_patterns_coded.json
 Stage E: warning-language research      ► raw/warning_language.json
            │
 merge2.ps1 ────────────────────────► death_site_language(.json|_flat.json), media_patterns.json,
            │                          settlement_language.json (+verified warning language), warning_events.json (+language)
 join.ps1 ──────────────────────────► raw/pattern_join.json → cross-tabs in pattern_conditions.json/.md
 Stage F: verification & context        ► president_visits.json, amnesty_2025_extract.json,
            │                          l2_comprehension_evidence.json, global_language_cases.json,
            │                          global_lastmile_cases.json, forecasting_infrastructure.json
 geocode_sites.ps1 ─────────────────► death_sites_geocoded.json
 build_sources.ps1 ─────────────────► all_sources.json, methods/SOURCES.md
```

### Stage A: flood events (Jan 2016 – Sep 2026)
- **Slicing:** four agents each covered one period: 2016–18, 2019–21, 2022–23, 2024–26.
- **Sources searched:** FloodList, ReliefWeb, Wikipedia, SAnews, SABC, News24, IOL, Daily Maverick, GroundUp, TimesLIVE, AllAfrica, eNCA, SAWS releases, NDMC gazettes and municipal statements.
- **Schema:** every event has 24 fields (see §5).
- **Inclusion rule:** deaths, displacement or a disaster declaration.
- **Cross-check:** a fifth agent pulled structured databases.
  - Fully accessible: GDACS (API) and GLIDE.
  - Read from public pages: FloodList, the Dartmouth Flood Observatory country page, and NDMC classifications.
  - **Not accessible:** EM-DAT per-event data (needs a login; only yearly aggregates were used) and the ReliefWeb API.

### Stage B: gap-filling
- **Leads chased:** Dec 2021 Mthatha (added), Jul 2026 East London and Sep 2026 Johannesburg CBD (real, but no deaths or displacement, so excluded), and the thin years 2018 / 2019 / 2021 (nothing further found).
- **Amnesty International, *Flooded and Forgotten*** (Nov 2025, index AFR 53/0369/2025): read in full and added 1 event (Dec 2024 eNkanini). Page-cited extracts are in `amnesty_2025_extract.json`.

### merge.ps1
- Concatenates the event files, sorts them by date and adds `year`, `month` and `source_count`.
- Tags `hazard_type`:
  - `storm` for 4 events where deaths were not mainly flood-related;
  - `non_weather` for the 2022 Jagersfontein tailings-dam failure.
- **Cross-reference rule:** a structured-database record matches an event if its start date is within ±21 days and at least one province overlaps.
- Keeps the 6 original `warning_events` rows verbatim (`origin:"original"`) and skips 4 research events that duplicate them.
- `stacked_locations.json`:
  - Adds `news_years_2016_2026` by matching each location name against `named_places`, `municipalities` and `event`.
  - Moves Lamontville from `high_risk_invisible` to `model_and_media_agree`, justified in `update_note`.
  - Flags Isipingo for review; its group is **not** changed.

### Stage C: death-site language
- **Unit of analysis: the place, never the person.** No victim's ethnicity or language was inferred from names or photos.
- **Per deadly event:** the agents found the places where deaths occurred (with per-place counts where reported) and looked up each place's **Census 2011 first-language** profile at census2011.adrianfrith.com, using `methods/scripts/cen.ps1`.
  - Sub place or main place was preferred.
  - Otherwise the agent fell back to the local municipality and recorded `geo_level`.
- **Census year:** 2022 place-level language data could not be retrieved, because Stats SA blocks automated access.
- **Double counting:** district and municipality rows can overlap the named-site rows, so **never sum `deaths_at_place` across all rows**. The headline uses only sub-place and main-place rows.

### Stage D: media patterns
- **Scope:** 53 deadly events, 199 articles read (1–8 per event).
- **Coding:** P1–P6 coded true / false / not_determinable, with verbatim evidence. "false" means not found in the articles read.
- **Cross-tabs:** `join.ps1` joins the coding to event features (scale band, metro, declaration, death mechanism by keyword, informal death site). Its output is summarised in `pattern_conditions.md`.

### Stage E / F: verification and context
- **Presidential visits:** checked event by event (14 checked), which found 2 visits the coding had missed.
- **Global comparisons:** coded against the failure points identified in the SA data.
- **Second-language research:** DOIs checked against Crossref or the publisher where possible. Exceptions are listed in the file's `caveats`.

### Geocoding
See `methods/geocode_log.md` for the method (census place centroid, falling back to OpenStreetMap Nominatim) and a confidence rating per site. Re-run with `methods/scripts/geocode_sites.ps1`; results are cached.

---

## 4. How to reproduce

**Requirements:** Windows PowerShell 5.1 (the scripts avoid Python and Node on purpose), and internet access for `cen.ps1` and geocoding only.

```powershell
cd last-mile\methods\scripts
.\merge.ps1          # rebuilds master + timeline + warning_events + stacked_locations from data\raw
.\merge2.ps1         # adds language layer + recoded media patterns
.\join.ps1           # rebuilds the pattern cross-tab input (data\raw\pattern_join.json)
.\geocode_sites.ps1  # re-geocodes death sites (uses cache)
.\build_sources.ps1  # regenerates all_sources.json and SOURCES.md
.\build_prototype_data.ps1  # regenerates prototype\data\story-data.js (all numbers shown in the prototype)
.\cen.ps1 -ids 294037    # example: print Census 2011 language profile for one place
```

**Reproducibility test (25 Sep 2026):** re-running `merge.ps1`, `merge2.ps1` and `join.ps1` from `methods/scripts/` reproduced all 12 output files byte-for-byte (SHA-256 identical). Re-running `geocode_sites.ps1 -Offline` reproduces `death_sites_geocoded.json` byte-for-byte from the cache.

The research stages (A–F) were done by the agents and are **not** scripted. Their raw outputs are preserved in `data/raw/`, and their briefs in `methods/agent_prompts.md`, so they can be re-run or audited. `data/raw/agent_working_files/` holds intermediate per-event drafts written by one agent. They are kept only for transparency, and their content is already in the final files.

---

## 5. Key field definitions (`floods_2016_2026.json`)

| Field | Meaning |
|---|---|
| `deaths` / `deaths_text` | Number used for counting / the figure as reported (ranges kept) |
| `warning_issued` | true / false / "disputed" / "unknown", covering *before* the event |
| `alert_level` | SAWS colour and level as reported (e.g. "Orange Level 9") |
| `warning_category` | One of 12 framing categories (e.g. "Last-mile failure", "Accountability ambiguity") |
| `disaster_declared` | national / provincial / local / classified_not_declared / none_found |
| `hazard_type` | flood / storm / non_weather |
| `confidence` | high = 2+ independent sources; medium = 1 solid source; low |
| `database_matches` | Structured-database records within ±21 days and overlapping a province |

## 6. Known limitations

1. **The event list is not exhaustive.** Search limits were reached; small local floods are under-represented.
2. **Census 2011, not 2022**, for place-level language. A place's profile describes the *place*, not necessarily the victims: some were motorists or visitors (e.g. the New Hanover 2025 victim "was from Matatiele").
3. **No source states the language of a specific event's warning**, and none quotes a resident who could not understand an English warning. The claim is a documented **pattern**: English-only warnings set against the Census language of places where deaths occurred. It is not a causal attribution for any death.
4. **Media coding** reads 2–4 articles per event. Sites that blocked access (News24, IOL) are under-represented.
5. **Presidential-visit pattern:** n = 9 visits. "No visit" means no report was found.
6. **Figures to verify before publication** are tagged `[verify]` in `storyboard-same-rain.md` and resolved in `data/forecasting_infrastructure.json`.
7. **Unverified details:** the Walmer Airport Valley survey figures come from The Conversation (16 Jun 2026) and secondary summaries; confirm them against the IJDRR full text (doi:10.1016/j.ijdrr.2025.105573).

## 7. File index

**Data files** (`data/`; see `data/README.md` for per-file change notes)

| File | Contents |
|---|---|
| `floods_2016_2026.json` | Master event list, 72 events |
| `flood_timeline.json`, `warning_events.json`, `stacked_locations.json`, `settlement_language.json`, `media_patterns.json`, `model_weights.json` | The files the visual story reads (schemas compatible with the original project) |
| `death_site_language.json`, `death_site_language_flat.json`, `death_sites_geocoded.json` | Language layer |
| `warning_language.json`, `amnesty_2025_extract.json`, `president_visits.json`, `forecasting_infrastructure.json` | Verification files |
| `pattern_conditions.md`, `pattern_conditions.json` | Conditional analysis of the media patterns |
| `global_comparison.md`, `global_lastmile_cases.json`, `global_language_cases.json`, `l2_comprehension_evidence.json` | International context |
| `all_sources.json` | Every URL cited, with the files that cite it |
| `raw/` | Unmodified agent outputs and original inputs |
| `raw/source_documents/` | Downloaded PDFs/XLSX, e.g. the Use of Official Languages Act gazette and the EM-DAT profile |

**Methods files** (`methods/`)

| File | Contents |
|---|---|
| `METHODS.md` | This document |
| `agent_prompts.md` | The research briefs given to each agent |
| `SOURCES.md` | Human-readable bibliography |
| `geocode_log.md` | Geocoding method and results |
| `scripts/` | All processing scripts |
