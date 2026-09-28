# Writes data/DATA_MANIFEST.csv: every data file with size, SHA-256, what it is, the script that produces it, and its primary sources.
# Tile/boundary caches (census_kml, gsw_tiles, observing_network) are listed as one row per folder.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$S = 'methods/scripts/'
$info = [ordered]@{
  'data/floods_2016_2026.json'            = @('72 SA flood events 2016-2026 (deaths, provinces, warnings)', "${S}merge.ps1 / merge2.ps1", 'EM-DAT, SAWS, news (see all_sources.json)')
  'data/death_site_language.json'         = @('Deaths placed at suburb/village sites with Census 2011 first-language shares', "${S}join.ps1, cen.ps1", 'Census 2011 via census2011.adrianfrith.com; news reports')
  'data/death_sites_geocoded.json'        = @('175 death-site rows geocoded with confidence', "${S}geocode_sites.ps1", 'Census 2011 place centroids; OSM Nominatim')
  'data/warning_language.json'            = @('Language of official flood warnings', 'research agent', 'SAWS, municipal notices, news')
  'data/media_patterns_coded.json'        = @('Media framing codes P1-P6 for 53 deadly events (199 articles)', 'research agents', 'SA news outlets (urls in file)')
  'data/articles/articles.csv'            = @('One row per article read (199)', "${S}export_articles.ps1", 'media_patterns_coded.json')
  'data/observing_network.json'           = @('SAWS radars, stations, gauges, satellites', "${S}fetch_observing_network.ps1", 'WMO OSCAR/Surface, WMO Radar Database')
  'data/forecasting_infrastructure.json'  = @('Fact-check of 12 forecasting claims (radar availability etc.)', 'research agent', 'SAWS annual reports')
  'data/president_visits.json'            = @('Presidential flood visits 2016-2026', 'research agent', 'thepresidency.gov.za, news')
  'data/world_incidents_long.csv'         = @('6 incidents x 20 natural-experiment indicators (long form)', "${S}build_incident_comparison.ps1", 'data/raw/world_incidents/*.json')
  'data/world_incidents_matrix.csv'       = @('6 incidents x 20 indicators (matrix)', "${S}build_incident_comparison.ps1", 'data/raw/world_incidents/*.json')
  'data/relocation_cases.csv'             = @('24 relocation-into-flood-risk cases with comparison codes', "${S}build_relocation_comparison.ps1", 'data/raw/relocation_into_floodzones_*.json')
  'data/relocation_rootcause_matrix.csv'  = @('11 cases x 10 structural factors (Y/P/N/nf)', "${S}build_relocation_rootcause.ps1", 'data/raw/relocation_deep_*.json')
  'data/tra_sites_2022_2026.csv'          = @('84 SA temporary relocation sites (TRA/TEA/TRU/transit camps) + origin + reflood flags', "transcribed; ${S}apply_reflood_sweep.ps1", 'User-supplied "South Africa TRAs 2022-2026" list (per-site sources); tra_reflood_sweep.json')
  'data/tra_sites_exposure.csv'           = @('84 sites + satellite water within 1 km + eThekwini floodplain band', "${S}build_tra_exposure.ps1", 'JRC Global Surface Water 1984-2021; eThekwini Flood Plain 100yr')
  'data/raw/durban_random_baseline.csv'   = @('300 seeded random Durban points run through the same tests (seed 20260927)', "${S}build_tra_exposure.ps1", 'JRC GSW; eThekwini Flood Plain 100yr')
  'data/raw/ethekwini_floodplain_100yr.geojson' = @('eThekwini 1:100 floodplain polygons (simplified)', "${S}build_tra_exposure.ps1", 'services3.arcgis.com/HO0zfySJshlD6Twu/.../Flood_Plain_100yr/FeatureServer/0')
  'data/raw/tra_reflood_sweep.json'       = @('Documented post-move flooding at TRAs (30 of 84 searched)', 'research agent', 'GroundUp, IOL, Sowetan, Daily Maverick, M&G (urls in file)')
  'data/raw/sa_governance_constitution.json' = @('Constitution, DMA, Housing Act, IGR Act, 1993-96 negotiations, AGSA audit structure (verbatim)', 'research agents', 'justice.gov.za, gov.za, pmg.org.za, agsa.co.za, treasury.gov.za, Haysom 2005, HRW 1995')
  'data/raw/relocation_deep_sa_baseline.json' = @('62 sourced findings on why eThekwini sites camps where it does', 'research agent', 'Housing Code Vol 4, AGSA, PMG, GroundUp, IOL, M&G')
  'data/raw/relocation_deep_does.json'    = @('5 relocation-into-risk cases, structural variables', 'research agent', 'academic + news (urls in file); Bower et al. 2023')
  'data/raw/relocation_deep_doesnt.json'  = @('5 relocation-out-of-risk cases, structural variables', 'research agent', 'Okada 2014; Roth & Winnubst 2015; McMichael 2019; Reconstruction Agency; NHC')
  'data/all_sources.json'                 = @('Every URL cited across the project', "${S}build_sources.ps1", 'all data files')
}
$folders = 'data/raw/census_kml', 'data/raw/gsw_tiles', 'data/raw/observing_network'
$rows = New-Object System.Collections.Generic.List[object]
foreach ($f in $folders) { $fs = Get-ChildItem "$root\$f" -Recurse -File -ErrorAction SilentlyContinue
  $rows.Add([pscustomobject][ordered]@{ path = "$f/ (folder)"; bytes = ($fs | Measure-Object Length -Sum).Sum; sha256 = "$($fs.Count) files"; description = 'cache of downloaded source files; re-fetched by the producing script'; produced_by = @{ 'data/raw/census_kml' = "${S}cen.ps1"; 'data/raw/gsw_tiles' = "${S}build_tra_exposure.ps1"; 'data/raw/observing_network' = "${S}fetch_observing_network.ps1" }[$f]; primary_sources = @{ 'data/raw/census_kml' = 'Census 2011 (adrianfrith.com)'; 'data/raw/gsw_tiles' = 'JRC Global Surface Water tiles (storage.googleapis.com/global-surface-water)'; 'data/raw/observing_network' = 'WMO OSCAR, WMO Radar DB' }[$f] }) }
Get-ChildItem "$root\data" -Recurse -File | Where-Object { $p = $_.FullName.Substring($root.Length + 1).Replace('\', '/'); -not ($folders | Where-Object { $p.StartsWith($_) }) -and $_.Name -ne 'DATA_MANIFEST.csv' } | Sort-Object FullName | ForEach-Object {
  $p = $_.FullName.Substring($root.Length + 1).Replace('\', '/'); $i = $info[$p]
  $rows.Add([pscustomobject][ordered]@{ path = $p; bytes = $_.Length; sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    description = if ($i) { $i[0] } else { 'supporting / raw research output (see methods/METHODS.md)' }; produced_by = if ($i) { $i[1] } else { '' }; primary_sources = if ($i) { $i[2] } else { '' } }) }
$rows | Export-Csv "$root\data\DATA_MANIFEST.csv" -NoTypeInformation -Encoding UTF8
"manifest rows: $($rows.Count)"
