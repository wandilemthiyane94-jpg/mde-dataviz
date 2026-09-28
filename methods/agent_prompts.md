# Research briefs given to AI research agents

Each research task was delegated to a Claude Code sub-agent that had web search and page-fetch tools. The briefs below are reproduced from the session, 24–25 September 2026. Long schema blocks are shortened with "…" only where the full schema appears in the output file itself.

**Rules common to every brief:**
- use only real sources, with URLs;
- use verbatim quotes;
- never invent numbers, quotes or URLs;
- leave unknown fields `null`;
- write valid UTF-8 JSON;
- report gaps in the final reply.

---

## Stage A: flood events (4 agents, one per time slice)

**Slices:** 2016–2018 · 2019–2021 (special attention to the April 2019 Easter floods) · 2022–2023 (special attention to Jan 2022 Mdantsane, Apr 2022 KZN, May 2022, Dec 2022 Gauteng, Feb 2023 national disaster, Mar 2023 Port St Johns, Jun 2023 KZN, Sep 2023 Western Cape) · 2024–24 Sep 2026 (special attention to Jun 2024, Feb 2025 eThekwini, Jun 2025 Mthatha, Jan 2026 Limpopo; multiple sources for 2026).

> Task: find EVERY notable flood event in South Africa in your date slice using web search and fetching pages. Cast a wide net: FloodList, ReliefWeb, Wikipedia, SAnews.gov.za, SABC, News24, IOL, Daily Maverick, GroundUp, TimesLive, AllAfrica, eNCA, SAWS media releases, NDMC Government Gazette disaster declarations, municipal press statements. Include flash floods, riverine floods, coastal/storm-surge floods, cut-off-low events and severe storms where flooding caused deaths, displacement or a disaster declaration. Include all 9 provinces.
>
> For EACH event capture (null when not found; never guess): id, start_date, end_date, event, provinces, municipalities, named_places, deaths, deaths_text, missing, displaced_or_affected, homes_damaged, economic_loss, disaster_declared, warning_issued, alert_level, warning_lead_time, warning_quote (verbatim), resident_quote_on_warning (verbatim), warning_category (one of: Denial of warning, Accountability ambiguity, Warning worked, Comprehension gap, Warning fatigue, Last-mile failure, Forecast validated, Misinformation pushback, Recurrence-based urgency, Casualty-dominant no warning detail, No warning language, Ritual/formulaic), settlement_type_mentioned, sources[{title,publisher,url,date}], confidence (high = 2+ independent sources; medium = 1 solid source; low), notes.
>
> HARD RULES: Only include events you found in an actual source with a URL. Do not invent events, numbers, quotes or URLs. If a figure is contested, give the range and explain in notes.

**Output:** `data/raw/floods_2016_2018.json`, `floods_2019_2021.json`, `floods_2022_2023.json`, `floods_2024_2026.json`

## Stage A: structured-database cross-check (1 agent)

> Gather South African flood records for 2016 to 24 September 2026 from STRUCTURED disaster databases and official sources: EM-DAT, ReliefWeb/GLIDE, Dartmouth Flood Observatory, GDACS, FloodList index, NDMC/Government Gazette declarations; document the SAWS impact-based warning scheme; academic datasets/papers; Stats SA Census 2022 language by province. Never invent numbers, IDs or URLs. Note which databases were blocked or login-only.

**Output:** `data/raw/structured_sources.json`, `data/raw/gdacs_raw.json`

## Stage B: gap-filling (1 agent)

> Fill specific gaps… do NOT duplicate existing ids. Leads: Dec 2021 Mthatha (GLIDE 6 deaths); late July 2026 East London/KuGompo; Sep 2026 Johannesburg CBD; Aug–Sep 2024; 2018 deadly floods; May–Oct 2019 and Jun–Dec 2021; Feb–Apr 2026 outside Limpopo/Mpumalanga; Aug–Sep 2026. Same schema. Include only if real and it caused deaths, displacement or a disaster declaration.

**Output:** `data/raw/floods_addendum.json`

## Stage C: death-site language (4 agents: other provinces; KZN/FS part A, rerun as A + A2 after the first attempt stalled and was stopped; KZN/FS part B)

> Goal: for each deadly flood event in the input file, identify the specific places where people died and document the HOME LANGUAGE profile of those places from Census 2011.
>
> ETHICS: Do NOT infer the ethnicity or language of individual victims from names, photos or anything else. The unit of analysis is the PLACE. Only record a victim's language/community if a source explicitly states it, quoted.
>
> Per event: (1) places where deaths occurred with per-place counts (precision: per_place_counts | places_named_no_counts | affected_area_only); (2) Census 2011 first-language top 3 (sub place / main place preferred; else local municipality — say so) from census2011.adrianfrith.com via cen.ps1; (3) settlement type as sources describe it; (4) any verbatim statement on the language of warnings. Write the output file incrementally after each event. Never invent percentages, counts or URLs.

**Inputs:** `data/raw/deadly_events_rest.json`, `deadly_kzn_a.json`, `deadly_kzn_a2.json`, `deadly_kzn_b.json`
**Output:** `data/raw/death_site_language_{rest,kzn_a,kzn_a2,kzn_b}.json`

## Stage D: media patterns (1 agent)

> Re-test five media-framing patterns across 53 deadly events. Code each true / false / "not_determinable" with a verbatim evidence snippet + URL: P1 death toll reported rising, never final; P2 "informal settlement" as default causal explanation; P3 presidential site visit (code Premier/Minister separately); P4 officials quoted almost exclusively over residents (give counts); P5 climate change framing; P6 warning mentioned at all. Read 2–4 source URLs per event; record articles_read. "not_determinable" is fine.

**Output:** `data/raw/media_patterns_coded.json`

## Stage E: warning language (1 agent)

> In what LANGUAGES are flood/severe-weather warnings actually issued in South Africa, by whom, through which channels? Verify, correct or nuance the claim "warnings are issued almost entirely in English and Afrikaans". Cover SAWS; NDMC and provincial centres; municipalities (eThekwini, Buffalo City, OR Tambo/KSD, NMB, Cape Town, Johannesburg, Tshwane, Vhembe); cell broadcast status; SABC African-language and community radio; Use of Official Languages Act 12 of 2012 and the Disaster Management Act; academic evidence; event-specific language evidence.

**Output:** `data/raw/warning_language.json`

## Stage F: verification & international context

**Presidential visits (1 agent)**

> Verify which SA flood disasters 2016–2026 the President personally visited… check each "no visit" event carefully… record provincial governing party and nearest election. "No report found" is not proof of absence.

**Output:** `data/president_visits.json`

**Second-language comprehension (1 agent)**

> What does peer-reviewed evidence say about how receiving a warning in a second language affects comprehension, encoding, risk perception and protective action, especially under stress, time pressure, at night? Psycholinguistics (L2 processing cost, stress × L2, foreign-language effect incl. replication status, emotional resonance, jargon/numeracy); warning-response models (Mileti & Sorensen; Lindell & Perry PADM); disaster studies of language minorities; Africa/SA evidence. Only real, verifiable publications; say if contested.

**Output:** `data/l2_comprehension_evidence.json`

**Global language cases (1 agent)**

> Around the world, where have disaster warnings failed or succeeded because of the language they were issued in? Concrete sourced cases 2000–2026 with languages, what went wrong/right, quantified evidence, policy change after, sources.

**Output:** `data/global_language_cases.json`

**Global last-mile comparison (1 agent)**

> Build a comparison set of ~15–20 major disasters 2010–2026 with documented warning outcomes; code failure points F1 alert meaning not understood · F2 language mismatch · F3 channel failure · F4 timing/overnight · F5 officials say sent vs residents not received · F6 warning fatigue · F7 no clear action/destination · F8 distrust · F9 response only above a scale threshold · F10 blame shifted to location/climate · F11 accurate forecast, last mile failed · S1 community intermediaries (success). Prefer official inquiries and peer-reviewed studies; mark unclear when not found.

**Output:** `data/global_lastmile_cases.json`

**Forecasting infrastructure fact-check (1 agent)**

> Fact-check claims about SA's forecasting infrastructure (SAWS radar network count/sites/outages; Meteosat reception; lightning detection network; Unified Model NWP; SA Flash Flood Guidance; WMO SWFP regional centre; impact-based warning introduction date; Google Flood Hub, GloFAS/GDACS coverage; DWS gauging network; dissemination channels incl. cell broadcast; warning statistics; statements on forecast accuracy for Apr 2022, Jun 2025, Jan 2026). Status per claim (verified/partly/not verified/false) with publishable wording and verbatim source quotes.

**Output:** `data/forecasting_infrastructure.json`

**Geocoding (1 agent)**

> Geocode every death site in death_site_language_flat.json. Prefer census place geometry (centroid); fall back to OpenStreetMap Nominatim (descriptive User-Agent, ≤1 req/s, cached). Record method, query, match, confidence (high/medium/low), and flag sites >30 km from the expected municipality. Deliver a re-runnable PowerShell script and a log. Never invent coordinates.

**Output:** `data/death_sites_geocoded.json`, `methods/scripts/geocode_sites.ps1`, `methods/geocode_log.md`

---

## Later briefs (26–27 September 2026)

Every brief below carried the same hard rules: verbatim quotes with URLs, no invented numbers, quotes or URLs, `not_found` for gaps, a confidence rating (high / medium / low) on every claim, and no victims named. Each is summarised here by its purpose and key instructions, and the full output file is listed.

| # | Purpose | Key instructions | Output |
|---|---|---|---|
| 1 | Five international flood incidents compared across 20 natural-experiment indicators (Germany 2021, Pakistan 2022, Mozambique 2019, Valencia 2024, Texas 2025) | Fill each of 20 indicators with a finding, value, URL and confidence; include `who_died`, `blame_framing` and `inquiries` | `data/raw/world_incidents/*.json` |
| 2 | Governments relocating displaced people into flood-prone areas: Africa | 8–15 cases; later extended with 8 fields for comparison with Durban (risk known before, temporary vs permanent, position, blame, warning at site, resident voice, who was moved at place level, accountability) | `data/raw/relocation_into_floodzones_africa.json` |
| 3 | The same, rest of the world | 12–18 cases; the same 8 comparison fields; a literature list | `data/raw/relocation_into_floodzones_world.json` |
| 4 | In-depth review of 5 relocations into risk (Kasiglahan, Chennai, Corail, Lower Zambezi, Beledweyne) | Structural variables: land, decision-maker, residents' legal status, funding, flood-risk information, liability, political voice, livelihoods, blame, outcome, scholarship; find the 14-case comparative study | `data/raw/relocation_deep_does.json` |
| 5 | In-depth review of 5 relocations out of risk (Grantham, Overdiepse, Gramalote, Iwanuma, Vunidogoloa) | The same variables; "success with caveats"; for whom success held | `data/raw/relocation_deep_doesnt.json` |
| 6 | The structural reasons in South Africa (eThekwini) | Land, funding stream (Housing Code emergency rules, grants, AGSA/SIU), floodlines, residents' legal status, liability (Grootboom etc.), political voice, governance, scholarship, backlog | `data/raw/relocation_deep_sa_baseline.json` |
| 7 | Reflooding sweep of the 84 temporary relocation sites | Count only floods at the site after people moved in; not the displacing flood; one quote and URL per finding | `data/raw/tra_reflood_sweep.json` (30 of 84 searched) |
| 8 | Sourcing the constitutional and legal steps of the "seven whys" | Constitution Ch. 3, Schedule 4A/4B, s156; Disaster Management Act s23/26/40/54; Housing Act s3/7/9/10; IGR Framework Act; metro housing assignment; 1993–96 negotiations; AGSA audit structure | `data/raw/sa_governance_constitution.json` |
| 9 | Testing the seven whys across the 5 failure and 5 success cases | Verdict per case and step: holds / partly / does_not_hold / not_found | **Not completed: stopped by a usage limit on 27 Sep 2026** |

**Verification passes by the analyst (the AI in the main session, with the student's review):**
- **Figures in write-ups:** checked against the source JSON by text search (e.g. the checks recorded for `world_incidents_comparison.md`).
- **Reflood flags:** revised after brief 7. Sondela, Delft TRA 5 and "Barcelona 2" were removed, and the February 2025 deaths were re-attributed to Gwala St (`methods/scripts/apply_reflood_sweep.ps1`).
- **Constitutional citations:** corrected after brief 8 ("distinctive"; Schedule 4B; DMA s26/40/54).
- **Floodplain claim:** reframed after the random-point baseline and a binomial test (p = 0.34).
