$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # last-mile/
$ErrorActionPreference = 'Stop'
$sp = $root
$res  = "$root\data\raw"
$orig = "$root\data\raw\original_lastmile-data"
$out  = "$root\data"
New-Item -ItemType Directory -Force $out | Out-Null

function Load($p) { Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json }
function Save($obj, $name) {
  $json = ConvertTo-Json -InputObject $obj -Depth 12
  [IO.File]::WriteAllText("$out\$name", $json, (New-Object Text.UTF8Encoding($false)))
}
function ToDate($s) {
  if (-not $s) { return $null }
  if ($s -match '^\d{4}-\d{2}-\d{2}') { return [datetime]::ParseExact($s.Substring(0,10), 'yyyy-MM-dd', $null) }
  if ($s -match '^\d{4}-\d{2}$') { return [datetime]::ParseExact("$s-15", 'yyyy-MM-dd', $null) }
  return $null
}

# ---------- 1. master event list ----------
$events = @()
foreach ($f in 'floods_2016_2018','floods_2019_2021','floods_2022_2023','floods_2024_2026','floods_addendum','floods_amnesty') { $events += Load "$res\$f.json" }
$events = @($events | Sort-Object start_date)
# hazard_type: storm = thunderstorm/wind/lightning events where deaths weren't mainly flood-related (filter these out for strict flood analysis)
$storms = '2021-12-mthatha-or-tambo-storms','2026-02-or-tambo-storms-early-feb','2026-02-mthatha-or-tambo-storm','2023-12-dundee-storm'
$nonWeather = '2022-09-jagersfontein-tailings'
foreach ($e in $events) {
  $h = if ($storms -contains $e.id) { 'storm' } elseif ($nonWeather -contains $e.id) { 'non_weather' } else { 'flood' }
  $e | Add-Member -NotePropertyName hazard_type -NotePropertyValue $h -Force
}
$struct = Load "$res\structured_sources.json"

foreach ($e in $events) {
  $d = ToDate $e.start_date
  $e | Add-Member -NotePropertyName year  -NotePropertyValue ([int]$e.start_date.Substring(0,4)) -Force
  $e | Add-Member -NotePropertyName month -NotePropertyValue ([int]$e.start_date.Substring(5,2)) -Force
  $e | Add-Member -NotePropertyName source_count -NotePropertyValue (@($e.sources).Count) -Force

  # cross-reference against structured databases: start within +/-21 days and province overlap (or db has no province)
  $refs = @()
  foreach ($s in $struct.events) {
    $sd = ToDate $s.start_date
    if (-not $d -or -not $sd) { continue }
    if ([math]::Abs(($sd - $d).TotalDays) -gt 21) { continue }
    $sp_ = @($s.provinces) | Where-Object { $_ }
    $overlap = ($sp_.Count -eq 0) -or (@($sp_ | Where-Object { @($e.provinces) -contains $_ }).Count -gt 0)
    if ($overlap) { $refs += [ordered]@{ source_db = $s.source_db; source_id = $s.source_id; start_date = $s.start_date; deaths = $s.deaths; url = $s.url } }
  }
  $e | Add-Member -NotePropertyName database_matches -NotePropertyValue $refs -Force
}
Save $events 'floods_2016_2026.json'

# database events with no news-event match (coverage gaps to review)
$matchedUrls = @($events | ForEach-Object { $_.database_matches } | ForEach-Object { $_.url })
$dbOnly = @($struct.events | Where-Object { $matchedUrls -notcontains $_.url -and $_.start_date -ge '2016' })

# ---------- 2. flood_timeline.json (original schema + new fields) ----------
$origTimeline = Load "$orig\flood_timeline.json"
$carryNotes = @{ '2022-01-eastern-cape-mdantsane' = 'storm arrived without warning'; '2022-04-kzn-megaflood' = 'deadliest flood in SA recorded history' }
$timeline = @($origTimeline | Where-Object { $_.year -lt 2016 })   # keep 2013 Limpopo as pre-window context
foreach ($e in $events) {
  $row = [ordered]@{
    id = $e.id; year = $e.year; month = $e.month; event = $e.event
    deaths = $(if ($null -ne $e.deaths) { $e.deaths } elseif ($e.deaths_text) { $e.deaths_text } else { 'not reported' })
    deaths_text = $e.deaths_text
    region = (@($e.provinces) -join ' / ')
    warning_category = $e.warning_category
    hazard_type = $e.hazard_type
    confidence = $e.confidence
    source_count = $e.source_count
  }
  if ($carryNotes.ContainsKey($e.id)) { $row.note = $carryNotes[$e.id] }
  $timeline += $row
}
Save $timeline 'flood_timeline.json'

# ---------- 3. warning_events.json (originals kept verbatim + new events) ----------
$origWarn = Load "$orig\warning_events.json"
$dupes = '2022-01-eastern-cape-mdantsane','2022-04-kzn-megaflood','2022-05-kzn-repeat','2026-01-limpopo-mpumalanga-floods'
$warn = @($origWarn | ForEach-Object { $_ | Add-Member -NotePropertyName origin -NotePropertyValue 'original' -Force; $_ })
foreach ($e in $events) {
  if ($dupes -contains $e.id) { continue }
  $warn += [ordered]@{
    id = $e.id; year = $e.year; month = $e.month
    place = (@($e.provinces) -join ' / ') + $(if (@($e.named_places).Count) { ' (' + ((@($e.named_places) | Select-Object -First 3) -join ', ') + ')' } else { '' })
    deaths = $(if ($null -ne $e.deaths) { $e.deaths } else { $e.deaths_text })
    warning_issued = $e.warning_issued
    alert_level = $e.alert_level
    category = $e.warning_category
    warning_quote = $e.warning_quote
    resident_quote = $e.resident_quote_on_warning
    confidence = $e.confidence
    origin = 'research_2026-09'
  }
}
$warn = @($warn | Sort-Object { [int]$_.year * 100 + [int]$_.month })
Save $warn 'warning_events.json'

# ---------- 4. stacked_locations.json (originals + news-year evidence) ----------
$stack = Load "$orig\stacked_locations.json"
foreach ($loc in $stack) {
  $pat = [regex]::Escape($loc.location)
  $hits = @($events | Where-Object { ((@($_.named_places) + @($_.municipalities) + $_.event) -join ' ') -match $pat })
  $loc | Add-Member -NotePropertyName news_years_2016_2026 -NotePropertyValue (@($hits | ForEach-Object { $_.year } | Sort-Object -Unique)) -Force
  $loc | Add-Member -NotePropertyName news_event_ids -NotePropertyValue (@($hits | ForEach-Object { $_.id })) -Force
  if ($loc.location -eq 'Lamontville') {
    $loc.media_evidence = 'Casualty'
    $loc.repeat_years = @(2025)
    $loc | Add-Member -NotePropertyName previous_group -NotePropertyValue $loc.group -Force
    $loc.group = 'model_and_media_agree'
    $loc | Add-Member -NotePropertyName update_note -NotePropertyValue 'Feb 2025 Lamontville flash floods: 7-12+ dead (News24, The Witness, IOL, EWN). Was "Not confirmed" / high_risk_invisible in the original dataset. Amnesty (2025, p.8/50/64): 5 of the dead (2 women, 3 children) lived in a temporary relocation area eThekwini itself built on the Umlazi riverbank for 2022 flood victims; AGSA had warned in Aug 2022 that 20% of inspected temporary units were on unsuitable riverbank land.' -Force
  }
  if ($loc.location -eq 'Isipingo') {
    $loc | Add-Member -NotePropertyName update_note -NotePropertyValue 'REVIEW: named in coverage of Oct 2017 Durban supercell storm and Feb 2025 eThekwini storm (wall collapses). Group left as high_risk_invisible pending your review. Amnesty (2025, p.51/60): Dakota informal settlement in Isipingo flooded Apr 2022 and Feb 2025; residents received no official help in 2025.' -Force
  }
}
Save $stack 'stacked_locations.json'

# ---------- 5. unchanged files ----------
foreach ($f in 'model_weights.json','media_patterns.json','settlement_language.json') { Copy-Item "$orig\$f" "$out\$f" -Force }

# ---------- 6. database cross-check + sources ----------
Save $struct 'database_crosscheck.json'
Save $dbOnly 'database_only_events.json'

$src = @{}
foreach ($e in $events) { foreach ($s in $e.sources) {
  if (-not $s.url) { continue }
  if (-not $src.ContainsKey($s.url)) { $src[$s.url] = [ordered]@{ url = $s.url; title = $s.title; publisher = $s.publisher; date = $s.date; used_by = @() } }
  $src[$s.url].used_by += $e.id
} }
foreach ($r in $struct.reference_sources) { if ($r.url -and -not $src.ContainsKey($r.url)) { $src[$r.url] = [ordered]@{ url = $r.url; title = $r.title; publisher = $r.authors; date = "$($r.year)"; used_by = @('reference') } } }
Save (@($src.Values | Sort-Object { $_.publisher })) 'sources.json'

# ---------- summary ----------
"events: $($events.Count)"
"timeline rows: $($timeline.Count)"
"warning rows: $($warn.Count)"
"events with >=1 database match: $(@($events | Where-Object { @($_.database_matches).Count -gt 0 }).Count)"
"database-only events (no news match): $($dbOnly.Count)"
"unique sources: $($src.Count)"
"--- stacked locations ---"
$stack | ForEach-Object { "{0,-12} {1,-16} orig={2,-12} news={3}" -f $_.location, $_.media_evidence, ($_.repeat_years -join ','), ($_.news_years_2016_2026 -join ',') }
"--- database-only by source ---"
$dbOnly | Group-Object source_db | ForEach-Object { "$($_.Name): $($_.Count)" }
