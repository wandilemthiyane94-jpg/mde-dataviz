# How to reproduce "Same Rain, Different Words" / "Who Owns the Flood"

**Team:** Hollie and Wandile · Harvard GSD MDE

**What you need**
- Windows 10 or 11 with Windows PowerShell 5.1. No Python or Node is required.
- Internet access, for the steps marked 🌐.
- Git is optional.

**Where things are**
- Repository: https://github.com/wandilemthiyane94-jpg/mde-dataviz
- `data/DATA_MANIFEST.csv`: every data file, with size, SHA-256 fingerprint, description, the script that produces it, and its primary sources.
- `data/all_sources.json`: every URL cited in the project.
- `methods/METHODS.md`: how the earlier stages were built.
- `methods/agent_prompts.md`: every research brief given to an AI agent.
- `ALGORITHMIC_FORENSICS.md`: how AI was used and checked.

Run each script from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File methods\scripts\<script>.ps1
```

## 1. South African flood events and language (stages 1–3)
| Step | Script | Output |
|---|---|---|
| Merge flood events | `merge.ps1`, `merge2.ps1` | `data/floods_2016_2026.json` |
| Census 2011 place language 🌐 | `cen.ps1` | `data/raw/census_kml/` |
| Geocode death sites 🌐 | `geocode_sites.ps1` | `data/death_sites_geocoded.json` (log: `methods/geocode_log.md`) |
| Join language to death sites | `join.ps1` | `data/death_site_language*.json` |
| Observing network 🌐 | `fetch_observing_network.ps1` | `data/observing_network.json` |
| Media dataset (199 articles) | `export_articles.ps1` | `data/articles/*.csv` |
| Source list | `build_sources.ps1` | `data/all_sources.json` |

## 2. International comparisons
| Step | Script | Output |
|---|---|---|
| 6 flood incidents × 20 indicators | `build_incident_comparison.ps1` | `data/world_incidents_*.csv` |
| 24 cases of relocation into flood risk | `build_relocation_comparison.ps1` | `data/relocation_cases.csv` |
| 11 cases × 10 structural factors | `build_relocation_rootcause.ps1` | `data/relocation_rootcause_matrix.csv` (prints the separation shares shown in the factor chart) |

The inputs are AI-researched JSON files in `data/raw/`. Each claim in them carries a URL, a verbatim quote where available, and a confidence rating. The codes in the build scripts are the analyst's reading of those findings, and they are written in the script in plain text so they can be checked.

## 3. Relocation-site flood exposure (the "Moved into the water" maps)
| Step | Script | Output |
|---|---|---|
| Satellite water + eThekwini floodplain test + random baseline 🌐 | `build_tra_exposure.ps1` (about 10 min: roughly 1,200 map queries) | `data/tra_sites_exposure.csv`, `data/raw/durban_random_baseline.csv`, `data/raw/ethekwini_floodplain_100yr.geojson`, `prototype/story/tra-story-data.js`, `prototype/story/durban_water.png` |
| Recolour the satellite mosaic | `recolor_durban_water.ps1` (called by the script above) | `prototype/story/durban_water.png` |
| Apply the reflooding sweep | `apply_reflood_sweep.ps1` | updates `data/tra_sites_*.csv` and `tra-story-data.js` |
| Manifest | `build_manifest.ps1` | `data/DATA_MANIFEST.csv` |

**Expected results**, printed by `build_tra_exposure.ps1`:
- 84 sites, 78 with coordinates.
- Durban: 28 sites tested; 11 inside the floodplain or within 250 m; 22 within 1 km.
- Random baseline: 34% inside or within 250 m; 84% within 1 km.

The random points use a fixed seed (20260927), so the baseline is identical on every run. It changes only if eThekwini updates its floodplain layer.

**Significance check** (binomial): if camps were placed like random ground (p = 0.34), the chance of 11 or more of 28 near the floodplain is 0.34, so there is no significant difference. The within-1 km comparison gives 0.29.

## 4. Outputs
- **Interactive story:** `prototype/story/moved-into-the-water.html`. Open it in a browser; it works offline.
- **PDF brief:** `Who_Owns_the_Flood.pdf`, rendered from `prototype/story/brief-pdf.html` with Microsoft Edge:
  ```powershell
  msedge --headless=new --allow-file-access-from-files --no-pdf-header-footer --virtual-time-budget=9000 --print-to-pdf=out.pdf prototype/story/brief-pdf.html
  ```
- **Earlier prototypes:** `prototype/index.html` (scroll story), `prototype/film.html`, `prototype/game.html`.

## Known limits (also stated on the charts)
- **Location accuracy.** Most relocation-site coordinates are estimates (±1–3 km), so per-site results are indicative.
- **Minimum counts.** Reflooding counts are minimums: 30 of the 84 sites were searched one by one.
- **Case selection.** The 11-case international comparison was chosen because of how the cases turned out, so it shows a pattern, not a statistical test.
- **Place, not person.** Language data describe places (Census 2011), never individual victims.
- **Excluded files.** Copyrighted third-party PDFs and EM-DAT extracts are not included in the repository. Their URLs are in `data/raw/source_documents/` and `all_sources.json`.
- **Unfinished test.** The cross-country test of the "seven whys" was not completed (stopped by a usage limit on 27 Sep 2026).
