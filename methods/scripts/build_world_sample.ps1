# Draws the random world sample for the relocation test.
# Frame: data/raw/world_relocation_frame.csv (408 cases, PDD/Kaldor/IOM "Leaving Place, Restoring Home" I & II).
# Eligible: water / slope hazards (flood, cyclone/storm, sea-level rise, landslide, tsunami, coastal erosion),
#           single-community rows (programme-level "Multiple" origins excluded so the unit is one relocation).
# Sampling: seeded shuffle (seed 20260928), first 64 eligible cases, split into 4 coding batches of 16.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$frame = Import-Csv "$root\data\raw\world_relocation_frame.csv" -Encoding UTF8
$elig = @($frame | Where-Object {
  ($_.hazard -in 'flood', 'cyclone/storm', 'sea-level rise', 'landslide' -or $_.hazard_original -match 'tsunami|coast|erosion') -and
  $_.place_origin -and $_.place_origin -notmatch '^(multiple|various|unknown)' })
$rnd = New-Object System.Random 20260928
$shuffled = $elig | Sort-Object { $rnd.Next() }
$i = 0
$sample = $shuffled | Select-Object -First 64 | ForEach-Object { $i++; $_ | Select-Object @{n = 'sample_no'; e = { $i } }, @{n = 'batch'; e = { [math]::Ceiling($i / 16) } }, * }
$sample | Export-Csv "$root\data\world_relocation_sample.csv" -NoTypeInformation -Encoding UTF8
"frame: $(@($frame).Count)  eligible: $($elig.Count)  sampled: $(@($sample).Count)"
$sample | Group-Object region | Sort-Object Count -Descending | ForEach-Object { "  $($_.Name): $($_.Count)" }
$sample | Group-Object hazard | Sort-Object Count -Descending | ForEach-Object { "  hazard $($_.Name): $($_.Count)" }
