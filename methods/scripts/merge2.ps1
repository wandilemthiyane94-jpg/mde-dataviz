$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # last-mile/
# Pass 2: language layer + recoded media patterns. Run after merge.ps1.
$ErrorActionPreference = 'Stop'
$sp = $root
$res = "$root\data\raw"
$out = "$root\data"
function Load($p) { Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json }
function Save($obj, $name) { [IO.File]::WriteAllText("$out\$name", (ConvertTo-Json -InputObject $obj -Depth 12), (New-Object Text.UTF8Encoding($false))) }

# ---------- death-site language ----------
$ds = @()
foreach ($f in 'death_site_language_rest','death_site_language_kzn_a','death_site_language_kzn_a2','death_site_language_kzn_b') {
  if (Test-Path "$res\$f.json") { $ds += Load "$res\$f.json" } else { "MISSING $f" }
}
Save $ds 'death_site_language.json'

$master = Load "$out\floods_2016_2026.json"
$byId = @{}; foreach ($e in $master) { $byId[$e.id] = $e }

# flat rows, one per death site (for charts). NOTE: district/municipality rows overlap named-site rows - don't sum deaths.
$flat = @()
foreach ($ev in $ds) {
  $m = $byId[$ev.id]
  foreach ($s in @($ev.death_sites)) {
    $top = @($s.top_languages)
    $flat += [pscustomobject][ordered]@{
      event_id = $ev.id; year = $(if ($m) { $m.year } else { $null }); month = $(if ($m) { $m.month } else { $null })
      hazard_type = $(if ($m) { $m.hazard_type } else { $null })
      place = $s.place; deaths_at_place = $s.deaths_at_place; settlement_type = $s.settlement_type
      geo_level = $s.geo_level; census_year = $s.census_year
      top_language = $(if ($top.Count) { $top[0].language } else { $null })
      top_language_pct = $(if ($top.Count) { $top[0].pct } else { $null })
      english_pct = $s.english_pct; afrikaans_pct = $s.afrikaans_pct
      english_or_afrikaans_pct = $(if ($null -ne $s.english_pct -and $null -ne $s.afrikaans_pct) { [math]::Round([double]$s.english_pct + [double]$s.afrikaans_pct, 2) } else { $null })
      warning_language_official = 'English'
      census_url = $s.census_url; death_source_url = $s.death_source_url
      precision = $ev.death_site_precision
    }
  }
}
Save $flat 'death_site_language_flat.json'

# ---------- warning language ----------
Copy-Item "$res\warning_language.json" "$out\warning_language.json" -Force

# ---------- media patterns (original schema kept: pattern, recurs_in; new fields added) ----------
$mp = Load "$res\media_patterns_coded.json"
$origClaims = @{
  'P1' = @('Death toll reported rising, never final','7 of 7 events sampled','conditional on scale: 0/25 small (1-4 deaths), 17/21 mid (5-19), 5/7 mass (20+)')
  'P2' = @('"Informal settlement" as default causal explanation','7 of 7 events, 2013-2026, near-identical phrasing','conditional on scale and national declaration (28% small -> 52% mid -> 86% mass; 67% if nationally declared). Voiced mostly by officials (16/24) as "don''t build near rivers"')
  'P3' = @('Presidential site visit as ritual story beat','5 of 7 events','conditional: mass-casualty or national-disaster events in provinces governed by the President''s party - see pattern_conditions.md')
  'P3b'= @('Premier/Minister/MEC site visit','(not in original)','new')
  'P4' = @('Officials quoted almost exclusively over residents','7 of 7 events; 1 academic causal quote in whole sample','holds at every scale (residents quoted in 48% small, 38% mid, 57% mass events); academic-quote claim breaks')
  'P5' = @('Climate change framing only after mass-casualty events','1 of 7 events (April 2022) explicitly; absent from smaller/frequent events','conditional on scale (12% small -> 33% mid -> 71% mass) and period (17% 2016-19, 13% 2020-22, 42% 2023-26); present in every weather-disaster presidential visit (6/6)')
  'P6' = @('Warning mentioned at all','(not in original)','new')
}
$patterns = @()
foreach ($s in $mp.summary) {
  $k = ($s.pattern -split ' ')[0]
  $c = $origClaims[$k]
  $patterns += [ordered]@{
    pattern = $c[0]
    recurs_in = "$($s.true) of $($s.out_of) deadly events, 2016-2026"
    code = $k; true = $s.true; false = $s.false; not_determinable = $s.not_determinable; out_of = $s.out_of
    original_claim = $c[1]; verdict = $c[2]; note = $s.note
  }
}
Save $patterns 'media_patterns.json'
Save $mp 'media_patterns_coded.json'

# ---------- settlement_language.json: keep originals, add verified warning-language field ----------
$sl = Load "$root\data\raw\original_lastmile-data\settlement_language.json"
foreach ($row in $sl) {
  $v = switch -Wildcard ($row.province) {
    'KwaZulu-Natal' { 'English (SAWS/NDMC); eThekwini has issued isiZulu newsflashes ad hoc (e.g. 27 Jun 2023) but recent alerts English-only' }
    'Western Cape'  { 'English verified; Cape Town policy commits to Eng/Afr/isiXhosa but no trilingual warning found' }
    default         { 'English (SAWS/NDMC/municipality); no official Afrikaans or African-language warning found' }
  }
  $row | Add-Member -NotePropertyName warning_language_verified -NotePropertyValue $v -Force
  if ($row.location -match 'Quarry Road') {
    $row | Add-Member -NotePropertyName ews_detail -NotePropertyValue 'Amnesty 2025 (p.50, 67-68): community EWS since 2016 (eThekwini + UKZN); SAWS data + community reports; WhatsApp groups, whistles, ropes, evacuation map; ~30 min lead time; triggered 5 times by May 2025. April 2022: all residents evacuated, one death by electrocution (no drownings). Not yet replicated to the 180 high-risk settlements; nearest shelter 5km away.' -Force
  }
  $row | Add-Member -NotePropertyName warning_language_note -NotePropertyValue 'Original "English/Afrikaans" value traced to unsourced framing in The Conversation (16 Jun 2026); Afrikaans not verified as an official warning language. See warning_language.json.' -Force
}
Save $sl 'settlement_language.json'

# ---------- attach language layer to warning_events.json ----------
$we = Load "$out\warning_events.json"
$dsById = @{}; foreach ($ev in $ds) { $dsById[$ev.id] = $ev }
$origMap = @{ '2022-1' = '2022-01-eastern-cape-mdantsane'; '2022-4' = '2022-04-kzn-megaflood'; '2022-5' = '2022-05-kzn-repeat'; '2026-1' = '2026-01-limpopo-mpumalanga-floods' }
foreach ($w in $we) {
  $id = $w.id
  if (-not $id -and $w.origin -eq 'original') { $id = $origMap["$($w.year)-$($w.month)"] }
  $ev = if ($id) { $dsById[$id] } else { $null }
  $eng = @(); if ($ev) { $eng = @($ev.death_sites | Where-Object { $null -ne $_.english_pct -and $_.geo_level -match 'sub place|main place' } | ForEach-Object { [double]$_.english_pct }) }
  $w | Add-Member -NotePropertyName affected_dominant_language -NotePropertyValue $(if ($ev) { $ev.dominant_language_across_sites } else { $null }) -Force
  $w | Add-Member -NotePropertyName death_site_english_pct_median -NotePropertyValue $(if ($eng.Count) { $s = $eng | Sort-Object; $s[[int][math]::Floor(($s.Count-1)/2)] } else { $null }) -Force
  $w | Add-Member -NotePropertyName warning_language_official -NotePropertyValue 'English' -Force
}
Save $we 'warning_events.json'

# ---------- summary ----------
$loc = @($flat | Where-Object { $_.geo_level -match 'sub place|main place' -and $null -ne $_.english_pct })
"death-site events: $(@($ds).Count); site rows: $($flat.Count); local-level rows with English%: $($loc.Count)"
"  English <10%: $(@($loc | Where-Object { $_.english_pct -lt 10 }).Count)"
"  English <5%:  $(@($loc | Where-Object { $_.english_pct -lt 5 }).Count)"
"  English+Afrikaans <10%: $(@($loc | Where-Object { $_.english_or_afrikaans_pct -lt 10 }).Count)"
"--- top language at local death sites ---"
$loc | Group-Object top_language | Sort-Object Count -Descending | ForEach-Object { "{0,-14} {1}" -f $_.Name, $_.Count }
