# Builds the 6-incident comparison (SA KZN 2022 + 5 international floods) across the 20 natural-experiment indicators.
# Inputs: data/raw/world_incidents/*.json   Outputs: data/world_incidents_long.csv, data/world_incidents_matrix.csv
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$dir = "$root\data\raw\world_incidents"
$order = 'south_africa_kzn_2022', 'germany_ahr_2021', 'pakistan_2022', 'mozambique_idai_2019', 'spain_valencia_2024', 'usa_texas_2025'
$inc = [ordered]@{}
foreach ($k in $order) { $inc[$k] = Get-Content "$dir\$k.json" -Raw -Encoding UTF8 | ConvertFrom-Json }

$long = foreach ($k in $order) { $j = $inc[$k]
  foreach ($p in $j.indicators.PSObject.Properties) {
    [pscustomobject][ordered]@{ incident = $k; country = $j.country; indicator = $p.Name; value = $p.Value.value; finding = $p.Value.finding; confidence = $p.Value.confidence; url = $p.Value.url } } }
$long | Export-Csv "$root\data\world_incidents_long.csv" -NoTypeInformation -Encoding UTF8

$inds = @($inc[$order[0]].indicators.PSObject.Properties.Name)
$matrix = foreach ($i in $inds) { $row = [ordered]@{ indicator = $i }
  foreach ($k in $order) { $v = $inc[$k].indicators.$i; $row[$k] = if ($v) { ("[{0}] {1}" -f $v.confidence, $(if ($v.value) { $v.value } else { $v.finding })) } else { '' } }
  [pscustomobject]$row }
$basics = foreach ($f in 'deaths', 'affected', 'displaced', 'damage_usd', 'insured_share') { $row = [ordered]@{ indicator = "basics.$f" }
  foreach ($k in $order) { $row[$k] = "$($inc[$k].basics.$f)" }; [pscustomobject]$row }
@($basics) + @($matrix) | Export-Csv "$root\data\world_incidents_matrix.csv" -NoTypeInformation -Encoding UTF8

"incidents: $($order.Count)  indicators: $($inds.Count)  rows(long): $(@($long).Count)"
$long | Group-Object incident | ForEach-Object { "{0,-24} high={1} medium={2} low={3} not_found={4}" -f $_.Name, @($_.Group | ? confidence -eq 'high').Count, @($_.Group | ? confidence -eq 'medium').Count, @($_.Group | ? confidence -eq 'low').Count, @($_.Group | ? confidence -eq 'not_found').Count }
