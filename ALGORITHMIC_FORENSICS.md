# Algorithmic Forensics Appendix

**Hollie and Wandile** · Same Rain, Different Words · Harvard GSD MDE

**How we use AI.** We used Claude Code, Anthropic's coding agent, as a research assistant and programmer. It did three jobs:
- **Search:** separate AI sub-agents searched the web for flood events, media coverage, relocation sites and governance evidence.
- **Code:** it wrote PowerShell scripts that turn that evidence into datasets.
- **Build:** it built the maps and charts.

We set the questions, the framing and the thesis. Every number in the project comes from a script in `methods/scripts/`, not from AI prose.

**Workflow and prompts.** Each research prompt, logged in `methods/agent_prompts.md`, carried the same hard rules:
- record verbatim quotes with URLs;
- never invent a number, quote or link;
- give every claim a confidence rating (high, medium or low);
- mark gaps as "not_found".

Agents wrote structured JSON to `data/raw/`. Scripts then merge, geocode and score those files into the published datasets. External data come from official sources: Census 2011 language by place, JRC Global Surface Water (Landsat, 1984–2021), eThekwini's 1-in-100-year floodplain, and WMO station records.

**Checking for error and bias.** We checked in four ways:
1. **Figures against sources.** Every figure in the write-ups was checked against its source file by text search.
2. **Second agents.** Separate agents re-verified the claims of earlier ones.
3. **Baselines.** Each spatial claim was compared with random locations.
4. **Counterexamples.** We asked for cases where our thesis fails: relocations that worked, and places where warnings in the local language still failed.

To limit bias:
- **Language:** analysed at the place level only, never by inferring any individual's ethnicity.
- **Victims:** not named.
- **Case selection:** we label the international comparison as outcome-selected, meaning a pattern rather than a test.

**One example where we caught the AI.** An early dataset flagged six relocation sites as flooded after people moved in. A second verification agent re-checked every source and three flags failed:
- **Sondela:** the "flood-prone wetland" described the old settlement, not the new site.
- **Delft TRA 5:** no source named the site.
- **Lamontville:** the February 2025 deaths were at the Gwala Street camp, not the camp the list called "Barcelona 2".

We corrected the data (`methods/scripts/apply_reflood_sweep.ps1`). We also fixed the AI's constitutional citations: "distinctive", not "distinct"; Schedule 4B, not Schedule 5; Disaster Management Act s26/40/54, not s41/55.

**How the visual metrics are calculated.**
- **Floodplain exposure:** each Durban site is queried against the city's floodplain as inside, within 250 m, or within 1 km. The share is the count divided by 28 sites.
- **Baseline:** 300 random points, generated with a fixed seed (20260927) so the same points come out on every run, across Durban's urban land, run through the same test.
- **Satellite water:** the share of 30 m Landsat pixels within 1 km that were wet less than 50% of the time.
- **Factor chart:** 11 cases coded yes, partial or no on 10 factors. The share is (yes + ½ partial) ÷ the number of cases with evidence.
- **Years "temporary":** 2026 minus the year the site was established.

**Is it statistically defensible?** The visuals are descriptive, and we present them that way.

The key spatial claim changed because of a test. We expected the camps to cluster in the floodplain. They don't:

| Measure | Camps | Random ground |
|---|---|---|
| Inside or within 250 m | 39% | 34% |
| Chance of 11 or more of 28 if camps were placed at random (binomial) | p = 0.34 | |

So the text says the flood map "made no difference to siting", not that sites were targeted.

Known limits, stated on the charts:
- Site coordinates are accurate only to ±1–3 km.
- Reflood counts are minimums: only 30 of 84 sites were searched individually.
- The 11-case comparison is small and outcome-selected.

The whole pipeline can be rerun from `REPRODUCE.md`.

*(About 490 words)*
