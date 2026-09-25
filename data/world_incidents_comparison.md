# Six floods, 20 factors: South Africa compared with the world

**Incidents compared:**
- South Africa, KwaZulu-Natal, Apr 2022 (the baseline)
- Germany, Ahr valley, Jul 2021
- Pakistan, Jun–Oct 2022
- Mozambique, Cyclone Idai, Mar 2019
- Spain, Valencia DANA, Oct 2024
- USA, Texas Hill Country, Jul 2025

**Files:** raw data is in `raw/world_incidents/*.json`. The tables are `world_incidents_matrix.csv` (factor × incident) and `world_incidents_long.csv` (120 rows with a source and confidence rating each). They are built by `methods/scripts/build_incident_comparison.ps1`.

## The basics
| | SA KZN 2022 | Germany 2021 | Pakistan 2022 | Mozambique 2019 | Valencia 2024 | Texas 2025 |
|---|---|---|---|---|---|---|
| Deaths | 435–459 | 134 (Ahr), ~190 national | 1,735 | 603 | 229 (province), ~237 national | ~119 (Kerr County), 135–139 statewide |
| Affected / displaced | 128,743 people affected | ~17,000 lost homes or had heavy damage | 33M affected, 7.9M displaced | 1.51M affected, 400,000 displaced | 212,533 insurance claims (proxy) | not counted |
| Damage | ~US$1bn (R17bn) | €33bn | $14.9bn damage, $15.2bn losses | $1.41bn damage, $1.39bn losses | €17.8bn | ~$1.1bn |
| Insured share | not found | ~25% | "almost nothing" | "almost nothing" | ~27% (our calculation) | ~2.5% of homeowners had flood insurance |
| Forecast | Warning issued (Orange L8) | Good, ~13h ahead | Predictable ~6 days ahead | Accurate ~3 days out | Red warning at 07:31 | Warning at 1:14am |
| Evidence quality (high-confidence factors, of 20) | **4** | 12 | 9 | 6 | 10 | 7 |

## What repeats everywhere (the constants)
1. **The forecast was good in every case, and people still died.** The failure was always in delivery:
   - Germany: 29–35% received no warning, and only 17.5% got an evacuation instruction.
   - Pakistan: "zero effective lead time".
   - Valencia: the phone alert went out at 20:11, after most people had died.
   - Texas: the county alert went out about 90 minutes after a firefighter asked for it.
   - Mozambique: radio warnings stopped when the power failed.
   - South Africa: the mayor said "we issued alerts", while residents said none reached them.
2. **People died where the warning format didn't reach them.** Each country's victims were the group its warning system wasn't built for:

   | Country | Who the warning missed |
   |---|---|
   | South Africa | People who don't speak English: 49 of 67 placed April 2022 deaths were at sites where 1–3% speak English |
   | Mozambique | People who can't read Portuguese: 41% of those in relocation sites; 44% of women couldn't understand spoken Portuguese |
   | Germany | Older and disabled people: ~80% were 60+, 16% had a disability, 12 died in one care home |
   | Valencia | Older, disabled and deaf people: nearly half were 70+, 53 had a disability, 450 deaf people got no usable alert |
   | Texas | Children asleep, and Spanish speakers: 39 children died; Latino families had no information in Spanish |
   | Pakistan | Children: 35–37% of the dead |

   South Africa's language gap is one version of a general rule: **the people who die are the people the warning was not designed for.**
3. **Most died at home or at night.**
   - Germany: 65% died indoors, peak around 01:00–02:00.
   - Valencia: in homes, garages and basements, around 19:00–20:00.
   - Texas: before dawn on a holiday.
   - South Africa: night-time accounts; people died at home in non-English-speaking places.
4. **Power and phones fail when the warning is needed:**
   - Germany: 200,000 lost power, and mobile service was down in every severely affected area.
   - Valencia: 250–300k mobile customers lost service.
   - Pakistan: 10 districts lost phone and internet.
   - Mozambique: community radio stopped when the power went.
   - South Africa: none of this has been measured.
5. **Climate is officials' first explanation:**
   - Merkel: "something to do with climate change".
   - UN Secretary-General on Pakistan: "climate carnage".
   - KZN: the Premier and Daily Maverick framed it in terms of the IPCC climate report.
   - Texas instead used "no one knew".

## Where South Africa diverges (the variables)
### Politics
| | Aftermath |
|---|---|
| Germany | Voters punished and rewarded parties: the Greens gained 0.4–1.6 points in affected areas; the CDU list vote in Ahrweiler fell from 40.6% to 28.5%; two ministers resigned; a 2,100-page state inquiry |
| Valencia | Regional and national governments blamed each other; the regional president, Mazón, resigned; the PP fell ~6 points in the polls; a criminal case over deaths caused by negligence |
| Texas | Republicans at every level of government; a 115-page legislative report; laws within 2 months; a criminal investigation |
| Pakistan | Money was routed differently to PTI-run KP (reported); the PPP was criticised but won a record 84 Sindh seats in 2024; no inquiry |
| Mozambique | The ruling party won every province 7 months later; food aid in shelters "became a political tool"; no inquiry |
| **South Africa** | Presidential visits only to ANC-run provinces; one ward changed hands over broken bridges (Molweni); **no inquiry into the warnings** |

- **The divide is accountability, not politics.** Rich democracies (Germany, Spain, the USA) produced inquiries, resignations or criminal cases within 1–2 years. South Africa, Pakistan and Mozambique produced none.
- **Flood politics favours incumbents where accountability is weak.** Mozambique's ruling party swept, and Pakistan's PPP won big. South Africa's 4 Nov 2026 local election is the next test.

### Health
| | Evidence |
|---|---|
| Pakistan | 1,460+ health facilities damaged; 540k malaria and 25,932 dengue cases |
| Mozambique | 92 facilities damaged; 6,768 cholera cases, 803k vaccinated in 3 weeks; antenatal visits fell 23% |
| Germany | 68 hospitals affected; PTSD in 28.2% one year on |
| Valencia | 57 health centres affected; PTSD diagnoses up 147% |
| **South Africa** | "Health centres" damaged, but not counted; no outbreak, birth-outcome or mental-health data found |

South Africa's health impact is essentially **unmeasured**.

### Economics
| | Evidence |
|---|---|
| Germany | Insured share ~25%; uninsured owners were paid 80–100% by the state; emergency grants paid ~2 days after application, but only ~21% of the €30bn rebuild fund was spent after 5 years |
| Valencia | ~27% insured; 92% of workers on temporary layoff schemes were back at work by mid-2025 |
| Texas | 2.5% insured; only 22% of aid applicants found eligible |
| Pakistan | Cash grants reached 2.66M families (97% of target) within weeks; only ~5% of 2.1M homes rebuilt by 2024 |
| Mozambique | ~56% of the recovery programme spent by 2024 |
| **South Africa** | 1,049 families still in temporary housing 3+ years on; relief only after a "major incident" is declared; insurance and income loss not found |

- Fast cash reaches people (Pakistan, Germany). Rebuilding stalls everywhere.
- South Africa has neither fast cash nor tracked rebuilding.

### Technology
| | Before | After |
|---|---|---|
| Germany | No phone alerts to all | Phone alerts to everyone in an area (Feb 2023), €88m for sirens, a new disaster agency |
| Texas | No sirens | Siren law and $50M for sirens and gauges; the **Jul 2026 repeat flood killed 1–2, against ~119 the year before** |
| Mozambique | No working radar | New Beira radar, local-language radio and text alerts; Cyclone Freddy 2023 killed 53–200, against 603 for Idai |
| Valencia | Phone alert system existed but was used late | Civil-protection plans now centre on phone alerts; still criticised for a late alert in Sept 2026 |
| Pakistan | Communities got "zero effective lead time" | Reforms under way |
| **South Africa** | No phone alerts to all; radar available 44–52% of the time in 2022–24 | Early-warning roadmap (Oct 2025); the Quarry Road community system is not yet expanded |

**The Texas before-and-after is the strongest natural experiment in the set:** same place, same hazard, one year apart. Once the warning chain was fixed, deaths fell from about 119 to 1–2.

## What this means for the South Africa thesis
1. **The language barrier is South Africa's version of a universal failure.** Warnings are designed for the person who issues them, and the people who die are the ones outside that design: non-English speakers, the elderly, the disabled, children asleep.
2. **What South Africa lacks is accountability.** Every richer country turned deaths into inquiries and laws within two years, and South Africa did not. Accountability is what triggers fixes: Texas passed its laws after the inquiry and cut deaths in the next flood.
3. **South Africa can't see its own damage.** It has the lowest evidence quality of the six: 4 of 20 factors at high confidence. Health, insurance, income and outage effects were never measured. An unmeasured failure can't be held to account, which ties back to the finding that only the sender ever vouches for the warning.

## Caveats
- **Small sample:** six incidents is not a statistical test.
- **Different scales:** the floods differ in size, hazard type and wealth.
- **Secondary sources:** some figures come from search excerpts where primary pages were blocked; these are marked in the JSON confidence fields.
- **Our calculations:** the dollar conversion and insured shares for Valencia and Germany are our own arithmetic.
- **Election effects:** these are associations, not causal estimates. The exception is Germany, where published studies exist.
