# VS Code workflow

**Team:** Hollie and Wandile · Harvard GSD MDE

This is how we build the project, and how a reviewer can open it and run it in about 5 minutes.

| # | Step | In VS Code |
|---|---|---|
| 1 | **Open** | Clone `github.com/wandilemthiyane94-jpg/mde-dataviz`, then File > Open Folder. Accept "Install recommended extensions" (listed in `.vscode/extensions.json`). |
| 2 | **Preview** | Click **Go Live** in the status bar (Live Server). The story opens at `/prototype/story/moved-into-the-water.html` and reloads on every save. |
| 3 | **Data** | Python + pandas in Jupyter notebooks, or the PowerShell scripts in `methods/scripts/`, write `.geojson` and `.csv` files to `data/`. Large layers are simplified with mapshaper. |
| 4 | **Inspect data** | Geo Data Viewer shows any `.geojson` on a map. Rainbow CSV makes the tables readable, e.g. `data/tra_sites_exposure.csv`. |
| 5 | **Rebuild** | Terminal > Run Task > **Data: …**. There are one-click tasks for the exposure analysis, the reflooding sweep, the root-cause matrix and the manifest (`.vscode/tasks.json`). |
| 6 | **Debug** | Press F5: **Debug story (Edge)** gives breakpoints and the console for the page scripts. A second launch option jumps straight to the displacement moment (state 5). |
| 7 | **Check** | Run Task > **Check: layout audit**, or add `?audit` to the URL. It reports text overflow and label collisions; all four lists should be empty. Also check phone (390 px) and desktop (1280 px) widths in DevTools device mode. |
| 8 | **Pair** | **Live Share** for co-editing between Hollie and Wandile. **Claude Code** is the AI pair programmer; every change it makes is reviewed and checked (see `ALGORITHMIC_FORENSICS.md`). **GitLens** shows who changed what. |
| 9 | **Ship** | Source Control panel: commit each feature and push to `main`. GitHub Pages or the shared web link is republished from the same files. |

**File map**

| Path | Contents |
|---|---|
| `prototype/story/` | Site: HTML, `lib/textfit.js` (measured text layout), `vendor/` (d3, topojson, rough.js) |
| `data/` | Datasets, plus `DATA_MANIFEST.csv` (source and SHA-256 of every file) |
| `methods/` | Scripts, research prompts, method notes |
| `REPRODUCE.md` | The full rebuild, with the expected numbers |
