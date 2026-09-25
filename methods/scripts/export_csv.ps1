# Exports the main datasets in data/ to flat CSV files (one row per record).
# Arrays of values are joined with "; "; nested objects become column.subcolumn; lists of objects keep their URLs (or compact JSON).
param([string]$OutDir = "$env:USERPROFILE\Desktop\last-mile-data-csv")
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$data = "$root\data"
New-Item -ItemType Directory -Force $OutDir | Out-Null
function Load($p) { Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json }

function Cell($v) {
  if ($null -eq $v) { return '' }
  if ($v -is [string] -or $v -is [ValueType]) { return "$v" }
  if ($v -is [System.Collections.IEnumerable]) {
    $items = @($v)
    if ($items.Count -eq 0) { return '' }
    if ($items[0] -is [pscustomobject]) {
      $urls = @($items | ForEach-Object { if ($_.PSObject.Properties['url']) { $_.url } })
      if ($urls.Count) { return ($urls -join '; ') }
      return ($items | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 5 }) -join '; '
    }
    if ($items[0] -is [System.Collections.IEnumerable] -and -not ($items[0] -is [string])) { return ($items | ForEach-Object { ($_ -join ',') }) -join '; ' }
    return ($items -join '; ')
  }
  return (ConvertTo-Json $v -Compress -Depth 5)
}
function Flat($o) {
  $h = [ordered]@{}
  foreach ($p in $o.PSObject.Properties) {
    if ($p.Value -is [pscustomobject]) { foreach ($q in $p.Value.PSObject.Properties) { $h["$($p.Name).$($q.Name)"] = Cell $q.Value } }
    else { $h[$p.Name] = Cell $p.Value }
  }
  [pscustomobject]$h
}
function Export($rows, $name) {
  $rows = @($rows); if (-not $rows.Count) { return }
  $flat = @($rows | ForEach-Object { Flat $_ })
  $cols = New-Object System.Collections.ArrayList
  foreach ($r in $flat) { foreach ($n in $r.PSObject.Properties.Name) { if (-not $cols.Contains($n)) { [void]$cols.Add($n) } } }
  $flat | Select-Object -Property $cols | Export-Csv -Path "$OutDir\$name.csv" -NoTypeInformation -Encoding UTF8
  "{0,-34} {1,5} rows" -f "$name.csv", $flat.Count
}

Export (Load "$data\floods_2016_2026.json" | Select-Object * -ExcludeProperty database_matches) 'floods_2016_2026'
Export (Load "$data\death_sites_geocoded.json") 'death_sites_language_geocoded'
Export (Load "$data\warning_events.json") 'warning_events'
Export (Load "$data\media_patterns_coded.json").events 'media_patterns_coded_by_event'
Export (Load "$data\media_patterns.json") 'media_patterns_summary'
Export (Load "$data\president_visits.json") 'president_visits'
Export (Load "$data\stacked_locations.json") 'stacked_locations_ethekwini'
Export (Load "$data\settlement_language.json") 'settlement_language'
Export (Load "$data\global_lastmile_cases.json").events 'global_lastmile_cases'
Export (Load "$data\global_language_cases.json") 'global_language_cases'
Export (Load "$data\l2_comprehension_evidence.json").findings 'second_language_research'
Export (Load "$data\forecasting_infrastructure.json").claims 'forecasting_infrastructure_factcheck'
$on = Load "$data\observing_network.json"
Export (@($on.layers | ForEach-Object { $L = $_; @($L.points) | ForEach-Object { $_ | Add-Member -NotePropertyName layer -NotePropertyValue $L.id -Force -PassThru } })) 'observing_network_stations'
Export $on.satellites 'observing_network_satellites'
Export (Load "$data\all_sources.json") 'all_sources'
$js = [IO.File]::ReadAllText("$root\prototype\data\story-data.js"); $sd = $js.Substring(14).TrimEnd(';') | ConvertFrom-Json
Export $sd.composition 'death_site_language_composition'
Export @([pscustomobject]$sd.stats) 'headline_stats'
