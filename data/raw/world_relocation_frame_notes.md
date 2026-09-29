# World planned relocation sampling frame: notes

Built 2026-09-28. File: `world_relocation_frame.csv` (UTF-8 with BOM, header row, 408 rows).

## Source
The frame reproduces the official case dataset behind the primary source. No fallback inventories were needed, and no cases were added, dropped or filtered.

- **Global Dataset of Planned Relocation Cases** (PDD / Kaldor Centre / IOM), Google Sheet, "Global Dataset of Cases" tab, downloaded 2026-09-28:
  https://docs.google.com/spreadsheets/d/1pDR-t1hVApqJiVk6E5DJ7TN0cOtXJiKvS1w8QIP149o/edit#gid=1611800107
  - The sheet is linked from https://disasterdisplacement.org/resource/global-dataset-leaving-place-restoring-home/
  - Raw copy saved as `world_relocation_frame_source_LPRH_dataset.xlsx`.
- The sheet combines two inventories:
  - Bower, E. & Weerasinghe, S. (2021), *Leaving Place, Restoring Home* (PDD & Kaldor Centre), covering English-language literature: 307 rows.
  - Mokhnacheva, D. (2021), *Leaving Place, Restoring Home II* (IOM), covering French, Spanish and Portuguese literature: 101 rows. These are the rows highlighted yellow in the sheet, identified here from the cell fill.
- The report is at https://disasterdisplacement.org/news-events/leaving-place-restoring-home-enhancing-the-evidence-base-on-planned-relocation-cases-in-the-context-of-hazards-disasters-and-climate-change-2/ (PDF mirror: https://environmentalmigration.iom.int/sites/g/files/tmzbdl1411/files/documents/pdd-leaving_place_restoring_home-2021-screen_compressed.pdf). The PDF could not be text-extracted because no PDF tools are available, so its annex was not read directly.
- Context was checked against https://www.fmreview.org/climate-crisis/bower-weerasinghe-mokhnacheva/ ("over 400 cases", 78 countries).

## Completeness
- **Full inventory obtained.** The report's 308 cases, less 1 removed, match the 307 LPRH I rows. The sheet's Metadata tab (last edited 9 June 2021) says the Nigeria Kuramo Beach case was removed because it was reclassified as a forced eviction. Adding the 101 LPRH II cases gives 408 rows across 78 countries.
- No later "living document" update after June 2021 was found. The metadata says it will be updated, but the last edit is dated 9 June 2021.

## Fields and coding
- `id`: WPR-001 to WPR-408, in sheet order. `source_sheet_row` gives the original row number.
- `hazard`: mapped from the dataset's "Primary Hazard" column onto the requested categories. The original value is kept in `hazard_original`.
  - Flood, Riverine flood, Coastal flood and Lake flood → flood.
  - Storm → cyclone/storm.
  - Volcanic eruption and Lahars → volcano.
  - Water scarcity → drought.
  - Tsunami (64), Earthquake (32), Coastal erosion (33) and Land subsidence (1) → other.
  - The dataset has no riverbank-erosion category.
- `status`: taken as given (completed / ongoing / suspended / unknown). The dataset has no "planned" category.
- **`year_start` and `scale` are "unknown" for every row.** The dataset does not record them. Filling them in would mean coding each case from its citations, which are kept in `case_citations`.
- Missing text fields are marked "unknown".
- `spatial_pattern` uses the dataset's codes for origin-to-destination patterns (A to D); see the LPRH report for definitions.

## Counts
- By hazard: other 130, flood 120, cyclone/storm 63, landslide 39, volcano 24, unknown 14, drought 9, sea-level rise 9.
- By region: Asia 162, Americas 156, Africa 39, Pacific 37, Europe 11, Middle East 3.

## Known biases and caveats
- **Literature-based frame.** Cases enter the frame only if they are documented in published academic or grey literature. This favours cases that were studied, which tend to be well-known, larger, NGO- or donor-involved, or controversial ones. Frequently studied cases include Vunidogoloa, Isle de Jean Charles, Tacloban and Newtok. The frame is not a census of relocations.
- **Language.** Only English, French, Spanish and Portuguese literature was reviewed. Chinese, Japanese, Russian, Arabic, Indonesian and Hindi/Bengali literature is missing, so East Asia and South Asia are probably under-counted relative to actual practice.
  - Most Americas and Africa cases come from LPRH II: 75 of 156 Americas cases and 21 of 39 Africa cases.
- **Over- and under-representation.**
  - The Pacific (37 cases) is heavily over-represented per head of population.
  - The USA has the most cases of any country (36).
  - Tacloban, Philippines appears as many rows (17 rows mention Tacloban City).
  - Europe, the Middle East and Africa are thin.
- **Unit of analysis is inconsistent.** Some rows are single villages. Others are "Multiple" or programme-level entries, such as Bangladesh "Multiple" (6 rows) and Indonesia "Multiple" (5 rows). Repeated origin names usually mean different destination sites or phases. They were kept as-is, not merged, following the source. Consider weighting or stratifying by unit type before sampling.
- **Temporal skew.** The frame is weighted towards post-2000 cases and towards completed ones (312 completed, 92 ongoing). Proposed relocations not yet started are largely absent.
- Hazard is the dataset's single "primary" hazard. Many cases involve multiple hazards.
