# Builds prototype/data/story-data.js from the audited data files.
# The prototype reads ONLY this file, so every number on screen traces back to data/.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$data = "$root\data"
function Load($p) { Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json }

$master = Load "$data\floods_2016_2026.json"
$floods = @($master | Where-Object { $_.hazard_type -eq 'flood' } | Sort-Object start_date | ForEach-Object {
  [pscustomobject][ordered]@{
    id = $_.id; date = $_.start_date; year = $_.year; month = $_.month; event = $_.event
    deaths = $(if ($null -ne $_.deaths) { [double]$_.deaths } else { 0 }); deaths_text = $_.deaths_text
    warned = ($_.warning_issued -eq $true); warning_issued = "$($_.warning_issued)"; alert_level = $_.alert_level
    provinces = @($_.provinces); category = $_.warning_category
    source = $(if (@($_.sources).Count) { @($_.sources)[0].url } else { $null })
  }
})

# Death sites: prefer geocoded file; the headline uses sub-place/main-place rows with >=1 death.
$geoPath = "$data\death_sites_geocoded.json"
$rows = if (Test-Path $geoPath) { Load $geoPath } else { Write-Warning 'death_sites_geocoded.json not found - sites will have no coordinates'; Load "$data\death_site_language_flat.json" }
$local = @($rows | Where-Object { $_.geo_level -match 'sub place|main place' -and $_.deaths_at_place -ge 1 -and $null -ne $_.english_pct })
$sites = @($local | ForEach-Object {
  [pscustomobject][ordered]@{
    event_id = $_.event_id; year = $_.year; month = $_.month; place = $_.place
    deaths = [double]$_.deaths_at_place; english_pct = [double]$_.english_pct
    top_language = $_.top_language; top_language_pct = $_.top_language_pct
    lat = $_.lat; lon = $_.lon; geocode_confidence = $_.geocode_confidence
    census_url = $_.census_url; death_source_url = $_.death_source_url
  }
})

$tot = ($sites | Measure-Object deaths -Sum).Sum
$lt10 = ($sites | Where-Object { $_.english_pct -lt 10 } | Measure-Object deaths -Sum).Sum
$eng = @($sites | ForEach-Object { $_.english_pct } | Sort-Object)
$median = $eng[[int][math]::Floor(($eng.Count - 1) / 2)]
$warnedFloods = @($floods | Where-Object { $_.warned })
$stats = [ordered]@{
  floods = $floods.Count
  deadly_floods = @($floods | Where-Object { $_.deaths -ge 1 }).Count
  warned_floods = $warnedFloods.Count
  warned_deadly_floods = @($warnedFloods | Where-Object { $_.deaths -ge 1 }).Count
  with_alert_level = @($floods | Where-Object { $_.alert_level }).Count
  placed_deaths = $tot; placed_sites = $sites.Count
  placed_sites_with_coords = @($sites | Where-Object { $null -ne $_.lat }).Count
  deaths_lt10_english = $lt10; pct_deaths_lt10_english = [math]::Round(100 * $lt10 / $tot)
  median_english_pct = $median
}

# Verified forecasting facts only (status verified or partly).
$sky = @(); $radars = @()
if (Test-Path "$data\forecasting_infrastructure.json") {
  $fi = Load "$data\forecasting_infrastructure.json"
  # Short on-screen captions, each condensed from that claim's verified_wording (full text + quotes stay in the JSON).
  $captions = [ordered]@{
    '6' = "Pretoria is the WMO's regional severe-weather forecasting centre for 16 southern African countries."
    '2' = "EUMETSAT's Meteosat satellites scan Africa every 10 minutes."
    '1' = 'A national network of 11 weather radars.'
    '3' = 'A lightning detection network, running since 2005.'
    '4' = "The UK Met Office's Unified Model, run locally at 1.5 km over South Africa, four times a day."
    '8' = 'Global flood models (Google Flood Hub, Copernicus GloFAS) cover South African rivers.'
    '7' = 'Colour-coded, impact-based warnings (Yellow/Orange/Red, levels 1-10), public since October 2020, built with the NDMC.'
  }
  $byId = @{}; foreach ($c in $fi.claims) { $byId["$($c.id)"] = $c }
  $sky = @($captions.Keys | Where-Object { $byId[$_] -and $byId[$_].status -in 'verified', 'partly' } | ForEach-Object {
    $c = $byId[$_]
    [pscustomobject][ordered]@{ id = $c.id; status = $c.status; text = $captions[$_]; source = $(if (@($c.sources).Count) { @($c.sources)[0].url } else { $null }) }
  })
  $radarCaveat = if ($byId['1']) { [ordered]@{ text = "It isn't perfect. SAWS's main-radar availability fell to 52% in 2022/23 and 44% in 2023/24, before recovering to 80% in 2024/25; the Durban radar broke down during the October 2017 storm."; source = $(if (@($byId['1'].sources).Count) { @($byId['1'].sources)[0].url } else { $null }) } } else { $null }
  $radars = @($fi.radar_sites | Where-Object { $null -ne $_.lat -and $null -ne $_.lon })
}

# ---- Film (film.html) additions ----
# 1. Expected first-language mix of residents at the death sites: each site's deaths apportioned by its Census 2011
#    top-3 language shares (remainder = "Other"), summed, then rounded to integers by largest remainder.
$dsl = Load "$data\death_site_language.json"
$acc = [ordered]@{}; $accTot = 0
foreach ($e in $dsl) { foreach ($s in @($e.death_sites)) {
  if ($s.geo_level -notmatch 'sub place|main place' -or -not ($s.deaths_at_place -ge 1) -or $null -eq $s.english_pct) { continue }
  $n = [double]$s.deaths_at_place; $accTot += $n; $sum = 0
  foreach ($l in @($s.top_languages)) {
    $k = if ($l.language -match 'Sign') { 'Other' } else { $l.language }
    if (-not $acc.Contains($k)) { $acc[$k] = 0.0 }; $acc[$k] += $n * [double]$l.pct / 100; $sum += [double]$l.pct }
  if (-not $acc.Contains('Other')) { $acc['Other'] = 0.0 }; $acc['Other'] += [math]::Max(0, 100 - $sum) * $n / 100
} }
$parts = @($acc.Keys | ForEach-Object { [pscustomobject]@{ language = $_; exact = [double]$acc[$_]; n = [math]::Floor([double]$acc[$_]) } })
$short = [int]$accTot - ($parts | Measure-Object n -Sum).Sum
$parts | Sort-Object { $_.exact - $_.n } -Descending | Select-Object -First $short | ForEach-Object { $_.n++ }
$composition = @($parts | Sort-Object n -Descending | ForEach-Object { [pscustomobject][ordered]@{ language = $_.language; n = [int]$_.n; exact = [math]::Round($_.exact, 1) } })

# 2. Hook: a real official isiZulu warning (eThekwini newsflash), quoted in data/warning_language.json.
$wl = Load "$data\warning_language.json"
$hq = @($wl.event_specific_language_evidence | Where-Object { $_.event -match 'isiZulu newsflash' })[0]
$hook = [ordered]@{
  language = 'isiZulu'; title = 'Isexwayiso Ngesimo Sezulu'; text = $hq.quote; date = $hq.date; url = $hq.url
  issuer = 'eThekwini Municipality (Durban) newsflash relaying a SAWS warning'
  translation = 'The public is urged to heed the weather warning issued by the South African Weather Service (SAWS), which forecast heavy rain in various parts of eThekwini.'
  translation_note = 'English translation by the project team; to be confirmed by a native isiZulu speaker. Swap in a Tshivenda warning here once one is sourced and verified.'
}

# 3. International before/after pairs (figures and URLs from data/global_language_cases.json and global_lastmile_cases.json).
$world = @(
  [ordered]@{ place = 'Bangladesh'; before = [ordered]@{ label = 'Bhola cyclone, 1970'; deaths = 300000; text = '~300,000' }; after = [ordered]@{ label = 'Cyclone Amphan, 2020'; deaths = 26; text = '26' }
    how = 'About 76,000 village volunteers turn forecasts into spoken Bangla, with megaphones and a flag code that needs no literacy.'
    sources = @('https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9657222/', 'https://reliefweb.int/report/bangladesh/bangladesh-cyclone-amphan-final-report-n-mdrbd024') },
  [ordered]@{ place = 'Odisha, India'; before = [ordered]@{ label = 'Super cyclone, 1999'; deaths = 10000; text = '>10,000' }; after = [ordered]@{ label = 'Cyclone Fani, 2019'; deaths = 42; text = 'several dozen' }
    how = 'Loudspeakers in the local language, 43,000 volunteers, 1.2 million+ evacuated.'
    sources = @('https://www.unescap.org/blog/storm-strength-odishas-zero-casualty-model-community-centered-disaster-resilience', 'https://www.preventionweb.net/news/un-praises-almost-pinpoint-accuracy-forecast-based-warnings-clean-underway-india-and') },
  [ordered]@{ place = 'Mozambique'; before = [ordered]@{ label = 'Cyclone Idai, 2019'; deaths = 600; text = '>600' }; after = [ordered]@{ label = 'Cyclone Freddy, 2023'; deaths = 200; text = '<200' }
    how = 'After Idai (warnings mostly in Portuguese, which only half the population speaks), community radio broadcast warnings in local languages.'
    sources = @('https://translatorswithoutborders.org/in-need-of-words-using-local-languages-improves-comprehension-for-people-affected-by-cyclone-idai-in-beira-mozambique/', 'https://wmo.int/site/science-action/weather-forecasts-and-early-warnings/mozambiques-life-saving-early-warning-systems') }
)
$worldCaveat = 'Different storms, and many changes besides language (shelters, volunteers, evacuation). Not a controlled comparison. What the successes share: warnings carried by local people, in local languages.'

# 4. Observing network (film "watched sky" scene): real station coordinates only, from data/observing_network.json.
$network = $null
if (Test-Path "$data\observing_network.json") {
  $on = Load "$data\observing_network.json"
  $network = [ordered]@{
    layers = @($on.layers | ForEach-Object {
      $pts = @($_.points | Where-Object { $null -ne $_.lat -and $null -ne $_.lon } | ForEach-Object { ,@([math]::Round([double]$_.lon, 3), [math]::Round([double]$_.lat, 3)) })
      [pscustomobject][ordered]@{ id = $_.id; label = $_.label; count_total = $_.count_total; count_with_coords = $pts.Count; source = $_.source.url; points = $pts }
    })
    satellites = @($on.satellites | ForEach-Object { [pscustomobject][ordered]@{ name = $_.name; orbit = $_.orbit; position = $_.position; saws_receives = $_.saws_receives; what = $_.what_it_sees; source = $_.source } })
    coverage = @($on.coverage_notes)
    radar_km = $null
  }
  # Radar range rings deliberately NOT drawn: the 200/300 km figure (Becker 2014) came from a search snippet and
  # is flagged for verification in methods/observing_network_log.md. Set radar_km here once confirmed.
  $network.radar_km = $null
  $network.saws_documented_sats = @($on.satellites | Where-Object { "$($_.saws_receives)" -match '^yes' }).Count
}

# 5. Game content (prototype/game.html)
. (Join-Path $PSScriptRoot 'game_content.ps1')

$weightedEng =($local | ForEach-Object { [double]$_.deaths_at_place * [double]$_.english_pct } | Measure-Object -Sum).Sum / $tot
$stats['weighted_english_pct'] = [math]::Round($weightedEng, 1)

$meta = [ordered]@{
  generated_at = (Get-Date).ToString('s')
  generated_by = 'methods/scripts/build_prototype_data.ps1'
  inputs = @('data/floods_2016_2026.json', 'data/death_sites_geocoded.json (or death_site_language_flat.json)', 'data/forecasting_infrastructure.json')
  notes = @(
    'Sites = sub-place/main-place rows with >=1 death; district rows excluded to avoid double counting.',
    'Brightness in the beam scene = Census 2011 share of residents with English as first language at the death site.',
    'Provincial capital coordinates used only for the decorative warning-chain lines (approximate).'
  )
}

$obj = [ordered]@{ meta = $meta; stats = $stats; floods = $floods; sites = $sites; sky_facts = $sky; radar_caveat = $radarCaveat; radars = $radars
  composition = $composition; hook = $hook; world = $world; world_caveat = $worldCaveat; network = $network; game = $game }
New-Item -ItemType Directory -Force "$root\prototype\data" | Out-Null
$js = 'window.STORY = ' + (ConvertTo-Json -InputObject $obj -Depth 8 -Compress) + ';'
[IO.File]::WriteAllText("$root\prototype\data\story-data.js", $js, (New-Object Text.UTF8Encoding($false)))
$stats | ConvertTo-Json
"sky facts: $($sky.Count); radar sites: $($radars.Count)"
