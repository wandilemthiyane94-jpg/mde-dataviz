# Why states relocate people into floods, and why some don't

**Data:** South Africa (eThekwini) as the baseline, 5 cases that relocated people into risk, and 5 that relocated people out of it.
- **Evidence:** `raw/relocation_deep_sa_baseline.json` (62 sourced findings), `raw/relocation_deep_does.json` and `raw/relocation_deep_doesnt.json`.
- **Scores:** `relocation_rootcause_matrix.csv`, built by `methods/scripts/build_relocation_rootcause.ps1`. The codes are our reading of the sourced findings.

## The cases
| Relocated into risk | Relocated out of risk (all with caveats) |
|---|---|
| **ZA: eThekwini TEAs** (Lamontville, Gwala St, Isipingo) | **AU: Grantham, 2011.** The council bought a hilltop farm and swapped title for title with flooded owners; families moved in after about 11 months. Only 3 homes in Grantham were damaged in the 2013 flood. |
| **PH: Kasiglahan.** Built on a reclaimed stream and rice field, "the absence of affordable land". Flooded in 2009, 2012, 2014 and 2020. | **NL: Overdiepse polder.** Farmers wrote the plan themselves; farms were rebuilt on 6 m mounds under a permanent national programme. |
| **IN: Chennai.** Built on marsh classed as "worthless". The flats were built first, then evictions filled them. Flooded in 2015 and 2023. | **CO: Gramalote.** A national fund bought the site, a community working group chose it with geology weighted highest, and **renters became owners**. |
| **HT: Corail/Canaan.** The land was expropriated from a company led by the government's own relocation adviser. The UN migration agency (IOM) said it "should not be used" after people had moved in. | **JP: Iwanuma.** Building on the coast was banned; a residents' committee (elders, women and youth) met 28 times to design the new district; public rental covered non-owners. |
| **MZ: Lower Zambezi.** Safe from floods but no way to make a living, so people returned to the floodplain. | **FJ: Vunidogoloa.** The village asked to move; it moved to its own clan land with traditional leaders deciding. No flooding at the new site in research from 2015 to 2023. |
| **SO: Beledweyne.** Evidence suggests people moved back into the floodplain (a submitted manuscript that may not yet be peer-reviewed). | |

## What separates the two groups
| Factor | Into risk (6) | Out of risk (5) | Separates them? |
|---|---|---|---|
| Site is the cheapest or leftover land | 90% | 0% | **Yes** |
| Flood-risk information was *binding* in choosing the site | 8% | 100% | **Yes** |
| Residents co-decided the site | **0%** | 90% | **Yes** |
| Residents got permanent ownership or tenancy when they moved | 17% | **100%** | **Yes** |
| One body owned both the land and the outcome | **0%** | 90% | **Yes** |
| Blame shifted after the flood | 100% | 0% | Yes, but it is a symptom |
| Emergency or "temporary" route | 58% | 20% | Weakly: Grantham was a fast post-disaster move and worked |
| Corruption or conflict of interest documented | 75% (n=4) | not researched | Can't tell, and it appears to make things worse rather than cause them |
| A court forced action | 0% | 0% | **No**: courts didn't drive the successes either |
| Livelihoods were planned | 0% | 40% | Partly: explains Mozambique |

**What doesn't separate them:**
- **Wealth:** Fiji and Colombia succeeded, while India, and Haiti with large amounts of international money, failed.
- **Courts:** no case in either group was forced by a court.
- **A standing housing programme:** Kasiglahan and Chennai *were* permanent housing programmes, and they still failed.
- **Corruption:** it doesn't explain the pattern on its own, because Mozambique and Somalia show no corruption findings and failed anyway.

## Testing each explanation
| Explanation | Verdict | Why |
|---|---|---|
| **Departments that don't talk to each other** | **Core, but only part of it** | Every failure splits the job. SA: the province funds and owns the shelters, the city finds land, SAWS warns, and eThekwini lists "coordination across line departments and spheres" as a constraint. Philippines: the town and the housing agency contradict each other. Haiti: the government, the UN and NGOs each blame another. Somalia: there is no river authority. Every success had one body that owned both the land and the result: the Grantham council, a Dutch province acting as broker, Colombia's reconstruction fund, Iwanuma city with its residents' committee. |
| **Corruption** | Makes it worse, but isn't the cause | SA: an R32m probe found "not a single house was built", and patronage in housing allocation. Haiti: a conflict of interest over the land. But Mozambique and Somalia failed without corruption findings. |
| **Incompetence** | Not the cause | Someone knew in every failure: the Auditor-General in SA, the national audit office in India, a 2004 study in the Philippines, the IOM in Haiti. The information existed; what was missing was any rule that made it **binding**. |
| **Elections** | Real, but backwards | The displaced aren't a voting bloc that can punish anyone; the research found neglect, not vote-buying. The voters who *do* count are the neighbours: Umhlanga and Shallcross ratepayers blocked sites. The successes had real political pressure *from the people being moved* (Grantham: "The whole of Australia is watching"). |
| **How the organisations are designed** | **Core** | SA's Emergency Housing Programme is *written* to be temporary: permanent-structure norms "will not apply", planning and environmental rules can be fast-tracked, and it provides for "permanent temporary settlement areas". Success is counted in units delivered, not in whether people are safe three years later. |

## The root cause: the risk lands on whoever has no say
Relocation goes into the flood when the people being moved have **no standing** in the decision: no seat at the table, no ownership, no leverage. It also needs **no single body answerable for the outcome.** When both hold, the site is set by whoever *does* have standing, and the flood-prone land is simply the land nobody with a voice defends.

**The less obvious evidence** is that even the successes reproduced the failure for their own residents who had no standing:
- **Grantham:** only owners got land swaps. Businesses were excluded, and people without money or insurance stayed on the floodplain.
- **Overdiepse:** landowning farmers got priority. Tenant farmers and a pig farmer were pushed out; only 8 of 17 families stayed.
- **Gramalote** is the exception that proves the rule: it **deliberately turned renters into owners**, and it worked for them.

So a rich, well-run system still sends risk to whoever has no standing. What decides safe versus unsafe relocation is **who is at the table and who holds title**, not wealth or competence.

**How the pattern plays out:**
1. **Safe land goes to whoever can defend it.** Ratepayers veto sites, landowners get compensated, and what's left is the riverbank.
2. **The emergency label speeds up the move, and the temporary label slows down rights.** "Emergency" suspends the checks (fast-tracked environmental rules, tender waivers, sites bulldozed in days). "Temporary" then suspends rights (leases instead of title, danger-zone status that blocks ownership, 14–15-year transit camps).
3. **Split responsibility means no one owns the result.** The department that picks the site never pays when it floods.
4. **Blaming the rain works because no one can contest it.** None of the 11 cases had a resident lawsuit that changed anything.

## South Africa scores as a failure on every factor
| Factor | eThekwini |
|---|---|
| Cheapest or leftover land | Riverbanks and canal edges. Ratepayers blocked other sites; 41% of land is private and 18% is Ingonyama Trust. |
| Flood-risk information binding | No. The city has 1:50 and 1:100 floodline maps and knows at least 164 settlements sit on floodplains, but the emergency route has no floodline check. The Auditor-General flagged the siting in 2022, and nothing changed before the fatal 2025 flood. |
| Residents co-decide | No. A councillor allegedly sent flood victims back to the flood-prone camp. |
| Permanent tenure | No. Residents get leases; the shelters belong to the province; the city calls moving them up the list "que-jumping" (sic) against a backlog of 469,500 households; 71 transit camps have been built since 2009. |
| One body owns the outcome | No. The province funds and owns the shelters, and the city has to find the land. R360m went unspent and none of 2,224 planned units were built in 2022/23. |
| Blame shifted | Flooding "is related mainly to the size of the storm event" (Mayor Xaba). |

## What the successes suggest for South Africa
1. **A land bank before the next flood (Grantham).** Pre-identify safe land, on the flood map and away from floodlines, so "no land" can't be the excuse.
2. **Make floodline checks binding on emergency sites.** Close the gap in the Housing Code: no temporary unit should go inside the 1:100 line, even under emergency rules.
3. **Residents' committees choose sites (Iwanuma, Gramalote).** Give the displaced a formal say in siting, with sites scored on hazard first (Gramalote weighted geology 30 of 100 points).
4. **Tenure from day one (Gramalote).** Turn temporary leases into a guaranteed path to permanent housing with a time limit, so "temporary" can't last 15 years.
5. **One accountable owner.** One body gets the land, the money *and* the outcome, measured by whether residents are safe years later, not by units delivered.
6. **Warnings that reach relocated sites, in residents' languages.** This is the link back to the project's thesis: the same lack of standing that puts people on the riverbank means no one checks whether the warning reached them.

## Caveats
- **Small, outcome-selected sample.** Cases were chosen because of how they turned out, so the clean separation in the table overstates how predictive these factors are. Read it as a pattern, not a statistical test.
- **Our coding.** The factor codes are our reading of sourced findings, and several variables (land cost, and corruption in the success cases) weren't found.
- **Imperfect successes.** Grantham excluded non-owners, Gramalote took 6 years, Vunidogoloa's promised infrastructure was never built, and Overdiepse lost 9 of 17 families.
- **Beledweyne rests on a submitted manuscript** that may not yet be peer-reviewed, and Gramalote was a landslide, not a flood.
- **Unverified quotes.** Several quotes come from search snippets or web-page extraction and are tagged in the JSON; check them before publishing.
- **Consistent with other research.** The *Nature Climate Change* comparison of 14 flood relocations (Bower et al. 2023) found community-driven relocations did better, which fits this result.
