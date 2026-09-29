# Codebook: world planned-relocation test

Use exactly these variables and codes. **If the sources don't say it, code `unknown`. Never infer.** Code the PROCESS variables from descriptions of how the relocation was organised. Code the OUTCOME variables from what happened afterwards, separately, so knowing the outcome does not colour the process coding.

For every coded variable, give `{ "code": ..., "evidence": "<verbatim quote or close paraphrase marked [para]>", "url": "...", "confidence": "high|medium|low" }`. You may use one quote for several variables if it supports them.

## Case facts
- `year_start`: the year the relocation started, or `unknown`
- `households`: number of households or people moved (as stated), or `unknown`
- `trigger`: `post_disaster` (after an event) | `pre_emptive` (before, e.g. erosion or sea-level rise) | `unknown`

## Process (the governance structure)
- `lead`: who drove the relocation
  - `gov_topdown`: government decided and implemented; residents informed or consulted at most
  - `gov_community_joint`: government and community co-decided (formal committee, co-designed plan)
  - `community_initiated`: the community asked for or organised it; government supported
  - `ngo_donor_led`: an NGO, donor or church led the implementation
- `single_owner`: was ONE public body responsible end to end, holding land acquisition, budget and implementation, and answerable for the result?
  - `yes`: e.g. one council, fund or agency ran it from start to finish
  - `partial`: one body led, but key pieces (land, money, services) sat with other agencies
  - `no`: responsibility split across agencies or levels with hand-offs, or no clear owner
- `resident_site_choice`: did residents help choose the destination? `yes` | `partial` (consulted on options) | `no`
- `tenure_destination`: `secure` (title, customary ownership, permanent tenancy) | `insecure` (temporary, lease, none, disputed)
- `hazard_binding`: was the destination selected or screened by a hazard assessment or rule? `yes` | `partial` | `no`
- `funding`: `standing_programme` (an existing permanent programme or fund) | `emergency_adhoc` | `mixed`
- `distance`: `under_5km` | `5_to_50km` | `over_50km`

## Outcomes
- `hazard_at_destination`: `none_reported` | `exposed_or_hit` (the new site was affected by flooding or a hazard, or is documented as hazard-exposed)
- `return_to_origin`: `none` | `some` | `many` (people went back to the hazard zone, e.g. for livelihoods)
- `livelihoods`: `maintained_or_improved` | `mixed` | `worse`
- `overall`: the sources' overall judgement: `success` | `mixed` | `failure`

## Output
Write JSON (UTF-8) to the path given in your task:
```
{"batch": n, "cases": [ { "sample_no": .., "country": .., "place_origin": .., "place_destination": ..,
   "year_start": {...}, "households": {...}, "trigger": {...},
   "lead": {...}, "single_owner": {...}, "resident_site_choice": {...}, "tenure_destination": {...},
   "hazard_binding": {...}, "funding": {...}, "distance": {...},
   "hazard_at_destination": {...}, "return_to_origin": {...}, "livelihoods": {...}, "overall": {...},
   "sources": ["url", ...], "notes": "..." } ] }
```

Rules:
- Aim for about 3–5 searches per case; if a case is barely documented, code what you can and mark the rest `unknown`.
- Never invent URLs, numbers or quotes.
- Do not name individual victims.
