# When do the media patterns fire? Conditions behind the counts

These patterns are conditional, not weakened. Each one switches on under specific conditions, and together they describe what happens as pressure to account for a disaster builds.

**Sample:** 53 deadly SA flood/storm events, 2016–2026, 199 articles coded (`media_patterns_coded.json`), joined to death toll, province, declaration, death mechanism and death-site settlement type (`pattern_join` in the scratchpad; the tables below are reproduced in `pattern_conditions.json`).

**Scale bands:** small = 1–4 deaths (25 events), mid = 5–19 (21), mass = 20+ (7).

**Labels:** **Finding** = what the counts show. **Reading** = interpretation/speculation from the pattern. Treat these as hypotheses to test, not conclusions.

---

## P1 — "Death toll rising, never final": a scale threshold

| Scale | Rising toll |
|---|---|
| small (1–4) | **0 / 25** |
| mid (5–19) | 17 / 21 (81%) |
| mass (20+) | 5 / 7 (71%) |

**Finding.** This is close to an on/off switch at about 5 deaths. Below it, a toll is reported once and never moves. Above it, the toll almost always climbs across reports.

**Reading.**
- **Missing persons drive the climb.** Small events are usually one moment: a car swept off a bridge, bodies found the same day. Mid and mass events involve missing people and multi-day searches, and the toll climbs as bodies are recovered.
- **Rolling coverage runs on the number.** Each new figure is a new headline, so the toll keeps the story alive for days.
- **Mass events never get one final figure.** The municipality, the province, the national government and the databases each publish their own count, and they never settle on one. April 2022 is reported as anything from 435 to 459 (the Dartmouth Flood Observatory says 306).

So the "never final" part is a symptom of fragmented official counting, not just media habit.

**The same threshold exists inside government.**
- Amnesty (2025, p.68): municipal emergency relief "is deployed only when the mayor declares a 'major incident'".
- Residents said they got attention "only in large-scale disasters" (p.62).
- One resident put the media link directly: "It feels like they are responding more to the media than to people's needs" (Kenneth, Barcelona informal settlement, Cape Town, p.55).

So the scale threshold in coverage and the scale threshold in the state response appear to reinforce each other.

---

## P2 — "Informal settlement" as the cause: fires with scale and national money, and is voiced by officials

| Condition | Causal framing |
|---|---|
| small / mid / mass | 7/25 (28%) → 11/21 (52%) → **6/7 (86%)** |
| National disaster declared vs not | **10/15 (67%)** vs 14/38 (37%) |
| Someone died *in* an informal settlement vs not | 10/17 (59%) vs 9/26 (35%) |
| Metro vs non-metro | 16/35 (46%) vs 8/18 (44%) — *no effect* |
| Deaths were motorists / low bridges | 9/20 (45%) vs 15/33 (45%) — *no effect* |
| Western Cape vs elsewhere | 4/8 (50%) vs 20/45 (44%) — *no effect* |
| 2016–19 / 2020–22 / 2023–26 | 42% / 33% / 54% |

**Who says it (24 causal events):**
- **16 by officials:** premiers, mayors, MECs, ministers, the President, a parliamentary committee chair, a SAWS forecaster.
- **4 by journalists.**
- **3 by academics or experts:** The Conversation, Cathy Sutherland, and experts in a Daily Maverick follow-up.
- **1 by a resident.**

The two groups phrase it differently. Officials mostly give a warning to residents:
- "avoid building their homes near river banks" — Premier Zikalala, 2022
- "people have built in areas which they are not supposed to build on" — MEC Buthelezi, 2025
- "we have 590 informal settlements which keep growing" — Mayor Xaba, 2025

Experts and residents describe the structure instead:
- "Vulnerable populations are often pushed into these high-risk zones because of their proximity to employment" — Daily Maverick, 2025
- "As shack-dwellers… it's us who get affected the most" — a resident, 2017

**Finding.** The frame isn't a default. It switches on with the death toll and with a national declaration, which brings national money and oversight. It is *not* explained by geography (metro vs rural, Western Cape vs elsewhere). It is only partly explained by where people actually died: 9 events got the causal frame even though no death occurred in an informal settlement. Ladysmith 2023 was framed as "a town on a floodplain", and the 2025 eThekwini wall collapses were framed as "informal settlements… lack adequate planning".

**Where informal settlements were hit but *not* blamed (7 events), the cause was assigned elsewhere:**
- **The hazard itself was treated as freak:** the 2024 Tongaat tornado, the 2017 Cape storm (deaths from lightning fires), the 2023 storm surge.
- **The deaths were tied to a specific activity:** the 2022 Jukskei baptism.
- **The story became a warning failure instead:** Mdantsane 2022, where coverage said the storm "arrived without warning".

**Reading.** "Informal settlement / built in the wrong place" works as the official answer to the accountability question.
- **It appears when that question has to be answered.** The toll is high, a declaration has been made, and national money is flowing.
- **It puts the cause in residents' choices** of where to live, not in drainage, bridge maintenance, housing backlogs or warning systems.
- **It rarely appears when the hazard can be called an act of God** (tornado, lightning) or when a different failure has already become the story (no warning).
- **It rose in 2023–26**, which lines up with the long post-April-2022 relocation and "transit camp" politics in eThekwini.

**The clearest test case: Lamontville, Feb 2025** (Amnesty International, *Flooded and Forgotten*, 2025, pp. 8, 50, 64).
- **Who died:** five of the dead (two women aged 56 and 60, three children aged 5, 11 and 16) lived in a temporary relocation area.
- **Who put them there:** the City of eThekwini itself built it for 2022 flood victims, on the Umlazi riverbank.
- **They had been warned:** in August 2022 the Auditor-General had reported that 20% of inspected temporary units were "built on unsuitable land as they were close to the riverbank".
- **What officials said anyway:** "people in these settlements often build on high-risk areas such as wetlands" (Mayor Xaba).
- **What it shows:** here the state chose the site, so the frame can't be describing residents' choices. It is doing accountability work: the "wrong place" frame is used even when the government chose the place.

---

## P3 — Presidential site visit: large toll + a province governed by the President's party

Verified separately (`president_visits.json`). There are **9 confirmed presidential flood-site visits, 2016–2026**, and all 9 were to ANC-governed provinces.

| Visit | Deaths | Province government | Context |
|---|---|---|---|
| Nov 2016 Alexandra (Zuma) | 6 | ANC | 3 months after the ANC lost the Johannesburg metro in the Aug 2016 local elections |
| Apr 2019 Durban/EC Easter floods | 87 | ANC | **2 weeks before** the 8 May 2019 general election |
| Apr 2022 KZN mega-flood | 435+ | ANC | Mass casualty; national disaster |
| Sep 2022 Jagersfontein | 3 | ANC | Mine tailings dam, a corporate-liability event rather than an "act of God" |
| Mar 2023 Port St Johns | 3 | ANC | National disaster already in force; 1,000+ displaced |
| Jun 2024 Kariega (NMB) | 11 | ANC | **9 days after** the 29 May 2024 election, during coalition talks |
| Jun 2025 Mthatha | 103 | ANC | Mass casualty; national disaster |
| Jan 2026 Limpopo | 37 | ANC | Mass casualty; ~10 months before the 2026 local elections |
| Jan 2026 Nkomazi (Mpumalanga) | (same event) | ANC | Same trip |

**No visit found:**
- **Western Cape (DA-governed), four events, three of them national disasters:** Sep 2023, Jul 2024, May 2026, Jun 2026. In July 2024 he was physically in Cape Town for the Opening of Parliament and mentioned the storms in the speech, but made no site visit.
- **KZN under the IFP-led coalition (from Jun 2024):** Feb 2025 eThekwini and Mar 2025 KZN. The DA publicly called on him to visit eThekwini.
- **ANC provinces skipped:**
  - Ladysmith Dec 2023 (21–25 dead, Christmas Eve)
  - Jan 2024 KZN/Free State (a toll that built up across weeks)
  - Mdantsane Jan 2022
  - Jukskei Dec 2022
  - the Feb 2023 national disaster, which he declared but did not visit

**Finding.**
- **Scale matters.** Mass-casualty (20+) events: 4/7 visited, against 1/21 mid and 2/25 small.
- **Party control shapes it more.** Every confirmed visit was to an ANC province. None went to a DA or IFP-led province, including three Western Cape national disasters.
- **Being an ANC province doesn't guarantee a visit.** Five ANC-province disasters got none.

**Reading.** Showing up seems to follow four conditions, roughly in this order.
1. **A province the President's party governs.** There, provincial success or failure reflects on the ANC, and the visit shows care from the party's own leader. In a DA- or IFP-led province, the national response goes through statements and ministers instead.
2. **A single, sudden, mass-casualty shock** with national headlines. Tolls that build up over weeks (Jan 2024) or events over a holiday (Ladysmith, Christmas Eve) don't trigger visits.
3. **Election proximity**, as a tie-breaker. The 2019 and 2024 visits sit within two weeks of general elections. The two small-event visits that remain are Jagersfontein (a company to blame, so a visit carries no risk of blame landing on government) and Port St Johns (a national disaster already declared).
4. **Scale itself.**

*Caveat:* n = 9 visits, and a "no visit" means no report of one was found. No source states the reasons for any decision to visit or not.

---

## P5 — Climate change framing: grows with scale, jumped after 2022, and comes with the President

| Condition | Climate framing |
|---|---|
| small / mid / mass | 3/25 (12%) → 7/21 (33%) → **5/7 (71%)** |
| 2016–19 / 2020–22 / 2023–26 | 2/12 (17%) / 2/15 (13%) / **11/26 (42%)** |
| National disaster declared vs not | 7/15 (47%) vs 8/38 (21%) |
| Presidential weather-disaster visit | **6 / 6 visits** (Jagersfontein, not weather, excluded) |
| KZN events | 7 of the 15 climate-framed events |

**Who says it (15 events):**
- **9 by officials.** Ramaphosa personally in 2019, 2023 and 2024; for example, "These are the effects of climate change – we should not be having 230mm of rain in two hours" (Kariega, 2024). The others are KZN CoGTA statements, including for a 1-death Dundee storm ("an alarming indication of the impact of global warming"), the national CoGTA department, eThekwini's mayor, the Human Settlements minister, and a parliamentary committee.
- **6 by journalists or experts:**
  - Mail & Guardian, 2017
  - Daily Maverick's IPCC framing, 2022
  - an environmentalist, 2023
  - an urban-planning academic, 2025
  - TimesLIVE background line, 2025
  - a Daily Maverick follow-up, 2026

**Finding.**
- **Scale.** Climate framing rises steeply with the death toll.
- **Timing.** It roughly **tripled after 2022**.
- **The President.** It appears in every weather-disaster visit he made.
- **Where it shows up in small events, it's official.** It is not confined to mass-casualty events: when it appears in small ones, it comes from **official provincial statements**, mostly KZN. Before 2022 it was mainly a journalist and activist frame (M&G 2017; Desmond D'Sa's open letter, 2019).

**Reading.** Climate change moved from an activist frame to part of the official script. Likely drivers:
- **April 2022 itself**, and the attribution work that followed it (World Weather Attribution, Pinto et al., 13 May 2022: probability "approximately doubled due to human-induced climate change", intensity up 4–8%, return time ~20 years now vs ~40 years in a 1.2°C cooler world. Verified via Amnesty 2025 p.72).
- **The IPCC Working Group II report** (Feb 2022), which Daily Maverick explicitly tied to the floods.
- **COP27's loss-and-damage fund** (Nov 2022) and South Africa's climate-finance diplomacy, which make climate a basis for money. See Minister Simelane in 2026: "Climate change loss and damage funding must kick in."
- **KZN's provincial communications** made it standard phrasing after 2023, which is why even a 1-death storm gets "global warming".

Like the informal-settlement frame, climate framing names a cause outside the local state. Here it is outside everyone: "unprecedented rainfall". It rises under the same pressure (scale, declaration, presidential attention).

---

## P4 — Officials over residents: holds at every scale (the one structural constant)

| Scale | Events quoting ≥1 resident |
|---|---|
| small | 12/25 (48%) |
| mid | 8/21 (38%) |
| mass | 4/7 (57%) |

Overall 187 officials vs 58 residents quoted; 29/53 events quote no resident at all. No scale or period effect.

---

## The pressure gradient

Put together, these patterns look like one mechanism, not five separate habits:

| Pressure level | What happens in coverage |
|---|---|
| Small (1–4 deaths) | One toll, reported once. Few officials, no President, rarely any causal explanation. The event is an accident. |
| Mid (5–19) | The toll climbs; MECs and Premiers visit; informal-settlement framing is at 50/50. |
| Mass (20+) / national declaration | The toll is contested; the President visits *if the province is ANC-governed*; officials explain the deaths through two causes outside government's control: **where residents built** (86%) and **climate change** (71%). |

Across every level, two things stay constant:
- **Residents are barely heard** (P4).
- **The warning chain is rarely the explanation.**
  - Coverage of 33/53 deadly events mentions a warning (P6).
  - Yet only **3 of 71** events are framed as a last-mile failure.
  - **32 of 71** have no warning discussion at all ("casualty-dominant" 18, "no warning language" 14).
  - The official warning language is English. At the 113 town- and suburb-level death sites, the **median share of residents speaking English as a first language is 3.1%** (`death_site_language_flat.json`).

**The story:** the higher the stakes, the more the official explanation moves away from the one link the state controls, getting the warning to people in a language and form they act on.
