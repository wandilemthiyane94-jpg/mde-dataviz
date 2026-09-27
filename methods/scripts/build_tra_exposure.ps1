# Flood exposure of South Africa's temporary relocation sites (TRAs / TEAs / TRUs / transit camps), 2022-2026 list.
# Inputs : data/tra_sites_2022_2026.csv (84 sites, transcribed from the user's "South_Africa_TRAs_2022-2026" sheet)
# Layers : (1) eThekwini Flood Plain 100yr (city open data, ArcGIS FeatureServer) - Durban sites only
#          (2) JRC Global Surface Water occurrence 1984-2021 (Landsat; Pekel et al. 2016, Nature) - all sites
# Baseline: 300 random points across Durban's urban area (seeded, land side of the coast) run through both layers.
# Outputs: data/tra_sites_exposure.csv, data/raw/ethekwini_floodplain_100yr.geojson,
#          prototype/story/durban_water.png (+ bounds), prototype/story/tra-story-data.js
# Caveat : most site coordinates are estimates (+/-1-3 km per the source sheet), so site-level results are indicative.
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Drawing
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$raw = "$root\data\raw"; $tiles = "$raw\gsw_tiles"; $story = "$root\prototype\story"
New-Item -ItemType Directory -Force $tiles, $story | Out-Null
$FS = 'https://services3.arcgis.com/HO0zfySJshlD6Twu/arcgis/rest/services/Flood_Plain_100yr/FeatureServer/0'
$GSW = 'https://storage.googleapis.com/global-surface-water/tiles2021/occurrence'
$inv = [Globalization.CultureInfo]::InvariantCulture

# ---------- helpers ----------
function TileXY([double]$lat, [double]$lon, [int]$z) {
  $n = [math]::Pow(2, $z); $lr = $lat * [math]::PI / 180
  $tx = ($lon + 180) / 360 * $n; $ty = (1 - [math]::Log([math]::Tan($lr) + 1 / [math]::Cos($lr)) / [math]::PI) / 2 * $n
  return @($tx, $ty) }
$bmpCache = @{}
function GetTile([int]$z, [int]$x, [int]$y) {
  $k = "$z-$x-$y"; if ($bmpCache.ContainsKey($k)) { return $bmpCache[$k] }
  $f = "$tiles\$k.png"
  if (-not (Test-Path $f)) { try { Invoke-WebRequest "$GSW/$z/$x/$y.png" -OutFile $f -UseBasicParsing -TimeoutSec 60 } catch { $null = New-Item $f -ItemType File } }
  $b = $null; if ((Get-Item $f).Length -gt 0) { $b = [System.Drawing.Bitmap]::FromFile($f) }
  $bmpCache[$k] = $b; return $b }
# Share of pixels within r metres that Landsat saw as water at any time, and share seen as intermittent (<50% occurrence).
function WaterAround([double]$lat, [double]$lon, [double]$r, [int]$z = 14) {
  $xy = TileXY $lat $lon $z; $cx = $xy[0] * 256; $cy = $xy[1] * 256
  $mpp = 156543.03392 * [math]::Cos($lat * [math]::PI / 180) / [math]::Pow(2, $z); $rp = [int][math]::Ceiling($r / $mpp)
  $tot = 0; $any = 0; $inter = 0; $step = 2
  for ($dy = -$rp; $dy -le $rp; $dy += $step) { for ($dx = -$rp; $dx -le $rp; $dx += $step) {
    if ($dx * $dx + $dy * $dy -gt $rp * $rp) { continue }
    $px = [int]($cx + $dx); $py = [int]($cy + $dy); $b = GetTile $z ([math]::Floor($px / 256)) ([math]::Floor($py / 256)); $tot++
    if ($null -eq $b) { continue }
    $c = $b.GetPixel($px % 256, $py % 256); if ($c.A -gt 0) { $any++; if ($c.B -lt 128) { $inter++ } } } }
  @([math]::Round(100 * $any / $tot, 2), [math]::Round(100 * $inter / $tot, 2)) }
function FpCount([double]$lat, [double]$lon, [int]$d) {
  $u = "$FS/query?geometry=$($lon.ToString($inv)),$($lat.ToString($inv))&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&returnCountOnly=true&f=json"
  if ($d -gt 0) { $u += "&distance=$d&units=esriSRUnit_Meter" }
  for ($i = 0; $i -lt 3; $i++) { try { return (Invoke-RestMethod $u -TimeoutSec 60).count } catch { Start-Sleep 2 } }; return $null }
function FpBand($lat, $lon) { if ((FpCount $lat $lon 0) -gt 0) { 'inside' } elseif ((FpCount $lat $lon 250) -gt 0) { 'within_250m' } elseif ((FpCount $lat $lon 1000) -gt 0) { 'within_1km' } else { 'beyond_1km' } }

# ---------- sites ----------
$sites = Import-Csv "$root\data\tra_sites_2022_2026.csv"
$out = foreach ($s in $sites) {
  $has = $s.lat -ne ''; $lat = if ($has) { [double]::Parse($s.lat, $inv) } else { 0 }; $lon = if ($has) { [double]::Parse($s.lon, $inv) } else { 0 }
  $w = if ($has) { WaterAround $lat $lon 1000 } else { @('', '') }
  $fp = if ($has -and $s.municipality -eq 'eThekwini') { FpBand $lat $lon } else { '' }
  $s | Select-Object *, @{n = 'gsw_any_1km_pct'; e = { $w[0] } }, @{n = 'gsw_intermittent_1km_pct'; e = { $w[1] } }, @{n = 'ethekwini_floodplain'; e = { $fp } }
}
$out | Export-Csv "$root\data\tra_sites_exposure.csv" -NoTypeInformation -Encoding UTF8

# ---------- Durban random baseline (seeded) ----------
$rng = New-Object System.Random 20260927; $base = @()
while ($base.Count -lt 300) {
  $lat = -30.05 + $rng.NextDouble() * 0.50; $lon = 30.75 + $rng.NextDouble() * 0.40
  $coast = 31.04 + ($lat + 29.85) * 0.5 - 0.02; if ($lon -gt $coast) { continue }
  $w = WaterAround $lat $lon 1000; $base += [pscustomobject]@{ lat = [math]::Round($lat, 4); lon = [math]::Round($lon, 4); fp = (FpBand $lat $lon); gsw_any = $w[0]; gsw_int = $w[1] } }
$base | Export-Csv "$raw\durban_random_baseline.csv" -NoTypeInformation -Encoding UTF8

# ---------- floodplain polygons for the map ----------
$gj = Invoke-WebRequest "$FS/query?where=1%3D1&outFields=OBJECTID&outSR=4326&maxAllowableOffset=0.0004&geometryPrecision=5&f=geojson" -UseBasicParsing -TimeoutSec 120
[IO.File]::WriteAllText("$raw\ethekwini_floodplain_100yr.geojson", $gj.Content, (New-Object Text.UTF8Encoding($false)))

# ---------- Durban satellite-water mosaic (z=12) ----------
$z = 12; $W = 30.70; $E = 31.16; $N = -29.50; $S = -30.10
$a = TileXY $N $W $z; $b2 = TileXY $S $E $z
$x0 = [math]::Floor($a[0]); $x1 = [math]::Floor($b2[0]); $y0 = [math]::Floor($a[1]); $y1 = [math]::Floor($b2[1])
$mos = New-Object System.Drawing.Bitmap([int](($x1 - $x0 + 1) * 256), [int](($y1 - $y0 + 1) * 256)); $g = [System.Drawing.Graphics]::FromImage($mos)
for ($x = $x0; $x -le $x1; $x++) { for ($y = $y0; $y -le $y1; $y++) { $t = GetTile $z $x $y; if ($t) { $g.DrawImage($t, ($x - $x0) * 256, ($y - $y0) * 256, 256, 256) } } }
$mos.Save("$story\durban_water.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $mos.Dispose()
function T2LL($tx, $ty, $z) { $n = [math]::Pow(2, $z); @(($tx / $n * 360 - 180), ([math]::Atan([math]::Sinh([math]::PI * (1 - 2 * $ty / $n))) * 180 / [math]::PI)) }
$nw = T2LL $x0 $y0 $z; $se = T2LL ($x1 + 1) ($y1 + 1) $z
Remove-Item "$raw\durban_water_raw.png" -ErrorAction SilentlyContinue; & "$PSScriptRoot\recolor_durban_water.ps1"
foreach ($k in @($bmpCache.Keys)) { if ($bmpCache[$k]) { $bmpCache[$k].Dispose() } }

# ---------- summary + story data ----------
$d = @($out | Where-Object { $_.municipality -eq 'eThekwini' -and $_.ethekwini_floodplain })
function Share($arr, $test) { if (-not $arr.Count) { return 0 }; [math]::Round(100 * @($arr | Where-Object $test).Count / $arr.Count) }
$sum = [ordered]@{
  sites = @($out).Count; with_coords = @($out | Where-Object { $_.lat }).Count
  durban_sites_tested = $d.Count
  durban_sites_inside_or_250m = @($d | Where-Object { $_.ethekwini_floodplain -in 'inside', 'within_250m' }).Count
  durban_sites_within_1km = @($d | Where-Object { $_.ethekwini_floodplain -ne 'beyond_1km' }).Count
  baseline_inside_or_250m_pct = Share $base { $_.fp -in 'inside', 'within_250m' }
  baseline_within_1km_pct = Share $base { $_.fp -ne 'beyond_1km' }
  durban_sites_median_gsw_int = ($d | ForEach-Object { [double]$_.gsw_intermittent_1km_pct } | Sort-Object)[[int]($d.Count / 2)]
  baseline_median_gsw_int = ($base | ForEach-Object { [double]$_.gsw_int } | Sort-Object)[150]
  mosaic = [ordered]@{ west = $nw[0]; north = $nw[1]; east = $se[0]; south = $se[1] }
}
$js = "window.TRA=" + (@{ summary = $sum; sites = @($out | ForEach-Object { [ordered]@{ id = [int]$_.id; site = $_.site; muni = $_.municipality; prov = $_.province; type = $_.type; est = $_.est_year; status = $_.status; size = $_.size; lat = $_.lat; lon = $_.lon; conf = $_.coord_confidence; origin = $_.origin; reflood = $_.reflood_documented; reflood_basis = $_.reflood_basis; fp = $_.ethekwini_floodplain; gsw = $_.gsw_intermittent_1km_pct } }) } | ConvertTo-Json -Depth 5 -Compress) + ";`nwindow.FLOODPLAIN=" + $gj.Content + ";"
[IO.File]::WriteAllText("$story\tra-story-data.js", $js, (New-Object Text.UTF8Encoding($false)))
$sum | ConvertTo-Json -Depth 3
