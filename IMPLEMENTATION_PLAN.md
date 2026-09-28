# Implementation plan: "Who Owns the Flood" (to 7 Oct 2026)

**Tools**
- **Data and code:** Windows PowerShell 5.1 scripts (no Python needed), Git and GitHub (`mde-dataviz`).
- **Visuals:** D3.js v7 and TopoJSON (maps, charts, scroll-driven "scrollytelling"), HTML and CSS, headless Microsoft Edge (PDF export and screenshots).
- **AI:** Claude Code as coding and research agent. Web sub-agents work to rules: verbatim quotes with URLs, confidence ratings, no invented figures.
- **Data:** Census 2011 (language by place); JRC Global Surface Water (Landsat, 1984–2021); eThekwini 1-in-100-year floodplain (ArcGIS open data); WMO OSCAR (observing network); a list of 84 temporary relocation sites; 199 coded news articles; 24 + 11 international relocation cases.

**Technical skills and workflows**
- **Spatial analysis:**
  - Point-in-polygon and buffer queries against the city floodplain.
  - Pixel sampling of satellite tiles.
  - A random-point baseline, generated with a fixed seed so it comes out the same every run.
- **Coding and statistics:** qualitative coding of cases into structured tables; a binomial significance test.
- **Evidence handling:** a claim-by-claim evidence ledger (JSON with URL, quote and confidence); verification by a second agent; a SHA-256 data manifest.
- **Storytelling:** a 7-state storyboard (water, then people, the return, comparison, control group, systems, reveal), built as a scroll story and a PDF brief.

**Still to build**
1. **Finish the "seven whys" test across the 5 failure and 5 success cases.** It was stopped by a usage limit.
2. **Search the remaining 54 of 84 relocation sites for reflooding.** Confirm the February 2025 camp name from the full IOL article.
3. **Source why 7:** apartheid-era siting of Durban townships.
4. **Join the two halves of the thesis:** the language spoken at each camp site (Census), plus whether warnings reached the camps.
5. **Final presentation deck and audio.** Recordings for the warning slots (isiZulu, English, Tshivenda).
6. **Accessibility pass:** screen reader, contrast, and captions in isiZulu and Afrikaans.

**Technical problems before 7 Oct**
- **Rough coordinates.** Most relocation-site coordinates are only accurate to ±1–3 km, so each site needs checking on satellite imagery.
- **Durban-only floodplain.** Only Durban has an open floodplain layer. Cape Town and Nelson Mandela Bay need floodline data, or a national JRC flood-hazard layer instead.
- **Windows-only scripts.** The image step uses a Windows-only graphics library (System.Drawing), so a professor on a Mac needs PowerShell 7 or a Python port.
- **Blocked sources.** Some sources (IOL, ReliefWeb, SAFLII) blocked automated fetching, so they need manual checks.
- **Unchecked outputs.** The rendered PDF and the live pages haven't yet been checked on a phone or by eye.
- **Sharing.** The web pages must be shared manually (organisation or "anyone with the link").

**Next 9 days** *(rename the owners as agreed)*
| Days | Wandile | Partner |
|---|---|---|
| 28–29 Sep | Finish the seven-whys test and source why 7 | Verify site coordinates on satellite imagery (Durban first) |
| 30 Sep–1 Oct | Reflooding search of the remaining 54 sites; IOL check | Find Cape Town and Nelson Mandela Bay floodline data; extend the floodplain test |
| 2–3 Oct | Add the seven-whys page and the camp-language layer to the brief | Accessibility and mobile test; record warning audio |
| 4–5 Oct | Build the presentation deck; rehearse | Reproducibility dry run on a clean machine using REPRODUCE.md |
| 6 Oct | Final edits; export PDF and share the links | Final check of sources and captions |
| **7 Oct** | **Present** | |
