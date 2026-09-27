# Applies the site-by-site reflooding sweep (data/raw/tra_reflood_sweep.json) to the site list and story data.
# Decisions (from the sweep): high/medium = "yes"; low-confidence = "low" (shown, not counted); removed flags = "".
#   yes : 1 Blikkiesdorp, 9 Kampies, 26 Isipingo, 29 Madamfana, 32 Gwala St (incl. Feb 2025 deaths), 59 Denver, 74 Motherwell NU30
#   low : 27 KwaDabeka (rain damage, not inundation), 67 Mamelodi Hostel TRUs
#   removed: 2 Delft TRA 5 (no source names the site), 13 Sondela (wetland was the old settlement), 33 Barcelona 2 (deaths were at Gwala St)
# Only 30 of 84 sites were searched individually, so counts are minimums.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$sweep = Get-Content "$root\data\raw\tra_reflood_sweep.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$yes = 1, 9, 26, 29, 32, 59, 74; $low = 27, 67
function Basis($id) { (@($sweep.found | Where-Object { [int]$_.id -eq $id }) | ForEach-Object { "$($_.flood_date): $($_.what) [$($_.confidence)] $($_.url)" }) -join ' || ' }
function Flag($id) { if ($yes -contains $id) { 'yes' } elseif ($low -contains $id) { 'low' } else { '' } }
foreach ($f in 'tra_sites_2022_2026.csv', 'tra_sites_exposure.csv') {
  $rows = Import-Csv "$root\data\$f"
  foreach ($r in $rows) { $id = [int]$r.id; $r.reflood_documented = Flag $id; $r.reflood_basis = if ($r.reflood_documented) { Basis $id } else { '' } }
  $rows | Export-Csv "$root\data\$f" -NoTypeInformation -Encoding UTF8 }
$js = [IO.File]::ReadAllText("$root\prototype\story\tra-story-data.js")
$i = $js.IndexOf(";`nwindow.FLOODPLAIN="); $tra = $js.Substring(11, $i - 11) | ConvertFrom-Json
foreach ($s in $tra.sites) { $s.reflood = Flag ([int]$s.id); $s.reflood_basis = if ($s.reflood) { Basis ([int]$s.id) } else { '' } }
$tra.summary | Add-Member -Force NoteProperty reflood_searched $sweep.searched_sites
$js = "window.TRA=" + ($tra | ConvertTo-Json -Depth 6 -Compress) + $js.Substring($i)
[IO.File]::WriteAllText("$root\prototype\story\tra-story-data.js", $js, (New-Object Text.UTF8Encoding($false)))
"yes: $($yes.Count)  low: $($low.Count)  searched: $($sweep.searched_sites)"
