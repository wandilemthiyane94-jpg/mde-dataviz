# World relocation test: results

**Team:** Hollie and Wandile · Harvard GSD MDE · built 2026-09-29

## Question

Our professors said we don't have enough data to show that "who owns it" is the problem. Our earlier comparison used 24 hand-picked cases, and cases chosen because we already knew how they ended can't test a cause.

So we drew a **random sample** of relocations from around the world and coded how each was organised **before** looking at how it ended. Then we asked which features of the process go with good or bad outcomes.

## Method

- **Frame.** *Leaving Place, Restoring Home* I and II (Platform on Disaster Displacement, Kaldor Centre and IOM) lists 408 planned relocations worldwide.
- **Eligible cases.** We kept 292: water and slope hazards (flood, storm or cyclone, sea-level rise, landslide, tsunami, coastal erosion), each a single community. Programme-wide rows marked "multiple" were excluded.
- **Sample.** A seeded random draw (seed 20260928) gave **64 cases** from 14 world regions (`methods/scripts/build_world_sample.ps1`).
- **Coding.** Each case was researched in 3 to 5 web searches and coded against `data/raw/world_coding_codebook.md`. Every code carries a quote, a URL and a confidence rating. Where the sources are silent, the code is "unknown"; nothing was inferred.
  - Process variables were coded separately from outcome variables.
  - The coded data are in `data/raw/world_coding_batch1..4.json`.
- **Country covariates.** World Bank income group, and the Worldwide Governance Indicators' government-effectiveness score for 2022.
- **Test.** 2×2 tables with a two-sided Fisher exact test, also split by country income (`methods/scripts/build_world_test.ps1`, output in `data/world_relocation_test.csv`).

## Coverage: most of the record is missing

| Variable | Known (of 64) | Split |
|---|---|---|
| Who led | 44 | government top-down 22 · community-initiated 12 · NGO or donor 7 · joint 3 |
| One owner, end to end | 36 | yes **1** · partial 13 · no 22 |
| Residents chose the site | 24 | yes 7 · partial 5 · no 12 |
| Hazard check binding on the site | 22 | yes 9 · partial 9 · no 4 |
| New site flooded or hazard-exposed | 28 | exposed or hit **15** · none reported 13 |
| Overall judgement | 35 | success 6 · mixed 22 · failure 7 |

45% of the 64 had no overall assessment, and the new site's safety was never reported in 56%. Most relocations are simply never followed up.

## Results

| Process feature | New site hit or exposed: with / without | p | Not a success: with / without | p |
|---|---|---|---|---|
| **Community-led or joint** | 25% / 56% | 0.21 | **43% / 92%** | **0.014** |
| **Residents helped choose the site** | 17% / 67% | 0.12 | **43% / 92%** | **0.038** |
| Government top-down | 62% / 27% | 0.12 | 94% / 62% | 0.059 |
| Hazard check binding | 33% / 100% (n=15) | 0.077 | 75% / 100% | 0.52 |
| Government effectiveness above median | 38% / 75% | 0.067 | 82% / 83% | 1.0 |
| Secure tenure at destination | 43% / 80% | 0.29 | 86% / 80% | 1.0 |
| Clear lead body (one owner, full or partial) | 44% / 54% | 1.0 | 88% / 87% | 1.0 |
| Higher-income country | 55% / 50% | 1.0 | 85% / 78% | 0.64 |

Within the richer countries alone (upper-middle and high income), the direction holds:

- **Residents chose the site:** new site hit or exposed in 20% of cases, against 71% where they didn't.
- **Binding hazard check:** 33% against 100%.

## What we found

1. **One government owner can't be tested.** Of 36 cases with a known structure, only one had a single public body running the relocation end to end. In the sample, *nobody* organises relocation like that, including the relocations that worked.
2. **Having a clear lead agency makes no difference.** Where one body led but others held pieces, the rate of bad outcomes was the same (88% vs 87% not a success; 44% vs 54% new site hit or exposed).
3. **What does separate outcomes is who holds the decision.** Relocations that the community started or co-ran, and those where residents helped choose the land, succeeded far more often: 43% were not a success, against 92% (p = 0.014 and p = 0.038). Top-down government relocations were the least successful group: 17 of 18 were mixed or failed.
4. **Two weaker signals point the same way.** A hazard check that binds the site choice, and a government that is more effective overall, both go with fewer new sites that flood. The p-values are 0.07 to 0.08, on small numbers.
5. **Money isn't the explanation.** Country income makes no difference to either outcome.

**The honest reading.** Our professors are partly right. The data don't support "one government body owning the process" as the fix, because almost nobody does that. The data do point to a sharper version of our thesis: **it matters who owns the *decision*.** Relocation goes wrong when the state decides alone and nothing binds it to safe ground. It goes better when the people being moved share the decision, and a hazard rule has a veto.

South Africa's TRAs are the textbook case:

- **Top-down:** the municipality decides.
- **No resident choice** of site.
- **No binding flood check:** camps sit on flood ground at the same rate as random land (39% vs 34%).
- **Insecure tenure:** the sites are "temporary".

## Caveats

- **Small numbers.** Each test uses 12 to 35 cases.
- **Multiple comparisons.** We ran 30 main tests. None clears a Bonferroni threshold (0.05 / 30 ≈ 0.002). The strongest result (p = 0.014) should be read as a pattern worth testing, not proof.
- **Missing data isn't random.** Well-documented cases tend to be the ones researchers studied, often because they were community-led or went badly.
- **Coder judgement.** One team coded all the cases, using public web sources; some sources are paywalled. The codes and quotes are published so anyone can recode them.
- **Frame bias.** *Leaving Place, Restoring Home* covers relocations that someone wrote about. Asia, the Americas and the Pacific dominate, and Africa has 5 of 64 cases.
- **Correlation, not cause.** Community-led cases may also be smaller, or pre-emptive rather than post-disaster.

## Next test

Add the 84 South African TRAs as a second sample, coded with the same codebook. Then double-code 20% of the world cases with a second coder to measure agreement (Cohen's κ).
