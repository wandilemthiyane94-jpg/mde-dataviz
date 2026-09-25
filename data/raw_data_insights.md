# What the raw data shows beyond the obvious

**Data:** 199 articles coded across 53 deadly events (`media_patterns_coded.json`), plus 286 deaths located at 113 suburb or village sites (`death_site_language.json`). The site-level findings were computed on 25 Sep 2026 from those files.

## 1. Language predicts how people die, not just whether they die
We sorted placed deaths by the Census 2011 share of residents at each site who speak English as a first language. How people died was classified from the death notes by keyword.

| Site | Road / crossing | Home collapse / mudslide | Swept away | Electrocution | Unspecified | Total |
|---|---|---|---|---|---|---|
| <10% English | 26 | **32** | **20** | **13** | 91 | 182 |
| 10–50% English | 15 | 6 | 0 | 0 | 23 | 44 |
| >50% English | **28** | 3 | 0 | 0 | 29 | 60 |

- **English-speaking places:** people died *passing through*. At >50% English sites, 28 of the 31 deaths with a known cause were on roads and river crossings.
- **Everywhere else:** people died *at home*. Houses and walls collapsed, people were swept from the riverbank, and informal electricity connections electrocuted residents. All 13 electrocution deaths were at sites where <10% speak English.
- **Why it matters:** a warning works best at home, where people can still leave. The homes where people died are the ones the English warning speaks to least.

## 2. The "informal settlement" explanation doesn't fit where the deaths happened
- Coverage names informal settlements as the cause in **86%** of mass-casualty events.
- Only **65 of 286** placed deaths (**23%**) happened at sites that sources describe as informal settlements.
- Most deaths were in formal townships and peri-urban areas: Inanda, KwaNdengezi, Umlazi, Mthatha's edges, and Limpopo villages.
- **Lamontville, Feb 2025:** 5 people died in a relocation camp the city itself had placed on the riverbank. Even so, the explanation given was that residents build in the wrong place.

## 3. Only the sender vouches for the warning
- Warnings are mentioned in coverage of **33 of 53** deadly events. In **19** of those, *no resident is quoted at all*.
- Only **3 of 72** events contain any resident speaking about the warning. None of the three say whether a warning reached them; they talk about floodplains, the speed of the water, and housing.
- The typical warning line comes from the issuer:
  - "When the South African Weather Service alerted us… we issued alerts to the public" (eThekwini, Apr 2022);
  - "early warnings were issued to disaster management teams and the public" (Mthatha, Jun 2025).
- Only once did the sender admit a gap: "the warnings were issued but the vast majority of ordinary citizens did not receive this critical life saving info" (SAWS, Durban 2017).
- **So:** whether a warning worked is judged by the people who sent it. No one measures whether it arrived. This is failure point F5 in the global comparison, and it appeared in 11 of 19 disasters worldwide.

## 4. The same places keep losing people
Some census places recur across events:

| Place | Deaths | Events |
|---|---|---|
| **Inanda** | 26 | 2019 and 2022 |
| **KwaNdengezi** | 16 | 2019 and 2022 |
| Tongaat | 11 | 2022 and 2024 |
| Area around Prince Mshiyeni hospital, Umlazi | 5 | 2017, 2020 and 2022 |
| Klip River, Ladysmith | 2 | 2022 and 2023 |
| KwaQoloqolo | 3 | twice in 2025 |

A repeat death site is a known risk, yet the next warning to the same place came in the same language and format.

## 5. Children
**75** placed deaths (26%) were at sites where the sources mention children, pupils or a school. Examples are the Mthatha scholar-transport bus (2025) and children drowned in rivers in Limpopo (2026). The share of child victims needs a proper count; this figure is an upper-bound flag.

## 6. The whole system switches on only above a threshold
- **Coverage:** 0 of 25 small events (1–4 deaths) get the rising-toll follow-up.
- **Relief:** municipal relief starts only once a "major incident" is declared (Amnesty 2025).
- **Politics:** presidential visits happen only for mass-casualty events in provinces governed by his party.
- **So:** small, repeated floods (most of the 67) fall below every radar: media, relief and political.

## 7. The forecasting system was itself degraded after 2022
SAWS main-radar availability was **52% (2022/23)** and **44% (2023/24)**, recovering to 80% in 2024/25 (`forecasting_infrastructure.json`). "The science worked" holds for specific events such as Jan 2026 (Red Level 10, accurate), but not for the whole period.

## Caveats
- How people died was assigned by keyword; 143 of 286 deaths are "unspecified".
- Settlement type is taken from how sources describe the site, so informal settlements may be undercounted.
- Census 2011 place profiles describe the place, not the victim.
