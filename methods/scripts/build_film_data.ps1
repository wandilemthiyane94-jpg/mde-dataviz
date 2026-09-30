# Builds prototype/story/film-data.js for the "Who Owns the Flood" film (film.html).
# Everything here is re-shaped from files the project already has; nothing new is measured.
#   frame    : the 408 LPRH relocations (country, eligible for the world test, sample number if drawn)
#   baseline : the 300 seeded random Durban points and their floodplain band (build_tra_exposure.ps1)
#   pts      : fallback coordinates for small territories that are missing from the 1:50m world map
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$frame = Import-Csv "$root\data\raw\world_relocation_frame.csv" -Encoding UTF8
$sample = Import-Csv "$root\data\world_relocation_sample.csv" -Encoding UTF8
$base = Import-Csv "$root\data\raw\durban_random_baseline.csv" -Encoding UTF8
$sampled = @{}; foreach ($s in $sample) { $sampled[$s.id] = [int]$s.sample_no }
# same eligibility rule as build_world_sample.ps1
function Elig($r) { ($r.hazard -in 'flood', 'cyclone/storm', 'sea-level rise', 'landslide' -or $r.hazard_original -match 'tsunami|coast|erosion') -and $r.place_origin -and $r.place_origin -notmatch '^(multiple|various|unknown)' }
$fr = foreach ($r in $frame) { [ordered]@{ c = $r.country; e = [int][bool](Elig $r); s = $(if ($sampled.ContainsKey($r.id)) { $sampled[$r.id] } else { 0 }) } }
$bl = New-Object System.Collections.ArrayList; foreach ($b in $base) { [void]$bl.Add(@([double]$b.lat, [double]$b.lon, $b.fp)) }
# approximate island / territory centroids (lat, lon) for names absent from world-50m
$pts = [ordered]@{ 'Wallis and Futuna (French overseas collectivity)' = @(-13.3, -176.2); 'Guadeloupe (French overseas department)' = @(16.25, -61.55)
  'Antigua and Barbuda' = @(17.08, -61.8); 'Martinique (French overseas collectivity)' = @(14.64, -61.02); 'United Kingdom (Territory of)' = @(16.74, -62.19); 'Saint Kitts and Nevis' = @(17.3, -62.72) }
# water occurrence raster: crop the cached JRC GSW occurrence mosaic (data/raw/durban_water_raw.png, blue = occurrence %)
# to the story's Durban bounds and store occurrence as grey (0-255), so the film can reveal water from always-wet to rarely-wet.
Add-Type -AssemblyName System.Drawing
$inv = [Globalization.CultureInfo]::InvariantCulture
$src = [Drawing.Bitmap]::FromFile("$root\data\raw\durban_water_raw.png")
$W0 = 30.673828125; $E0 = 31.201171875; $N0 = -29.45873118535533; $S0 = -30.145127183376118   # mosaic bounds (tra-story-data.js summary.mosaic)
function MY([double]$lat) { [math]::Log([math]::Tan([math]::PI / 4 + $lat * [math]::PI / 360)) }
function IMY([double]$m) { (2 * [math]::Atan([math]::Exp($m)) - [math]::PI / 2) * 180 / [math]::PI }
$mN = MY $N0; $mS = MY $S0
$x0 = [int][math]::Floor((30.74 - $W0) / ($E0 - $W0) * $src.Width); $x1 = [int][math]::Ceiling((31.14 - $W0) / ($E0 - $W0) * $src.Width)
$y0 = [int][math]::Floor(($mN - (MY -29.53)) / ($mN - $mS) * $src.Height); $y1 = [int][math]::Ceiling(($mN - (MY -30.06)) / ($mN - $mS) * $src.Height)
$cw = $x1 - $x0; $ch = $y1 - $y0; $fmt = [Drawing.Imaging.PixelFormat]::Format32bppArgb
$out = $src.Clone((New-Object Drawing.Rectangle $x0, $y0, $cw, $ch), $fmt); $src.Dispose()
$od = $out.LockBits((New-Object Drawing.Rectangle 0, 0, $cw, $ch), [Drawing.Imaging.ImageLockMode]::ReadWrite, $fmt)
$buf = [byte[]]::new($od.Stride * $ch); [Runtime.InteropServices.Marshal]::Copy([IntPtr]$od.Scan0, $buf, [int]0, [int]$buf.Length)
for ($i = 0; $i -lt $buf.Length; $i += 4) { if ($buf[$i + 3] -lt 128) { $buf[$i] = 0; $buf[$i + 1] = 0; $buf[$i + 2] = 0; $buf[$i + 3] = 0 } else { $v = $buf[$i]; $buf[$i + 1] = $v; $buf[$i + 2] = $v; $buf[$i + 3] = 255 } }
[Runtime.InteropServices.Marshal]::Copy($buf, [int]0, [IntPtr]$od.Scan0, [int]$buf.Length); $out.UnlockBits($od)
$stream = New-Object IO.MemoryStream; $out.Save($stream, [Drawing.Imaging.ImageFormat]::Png); $out.Dispose()
$water = [ordered]@{ png = 'data:image/png;base64,' + [Convert]::ToBase64String($stream.ToArray())
  west = $W0 + ($E0 - $W0) * $x0 / 1536; east = $W0 + ($E0 - $W0) * $x1 / 1536; north = IMY ($mN - ($mN - $mS) * $y0 / 2304); south = IMY ($mN - ($mN - $mS) * $y1 / 2304) }
$js = "window.FILM=" + (@{ frame = @($fr); baseline = @($bl); pts = $pts; eligible = @($fr | Where-Object { $_.e -eq 1 }).Count; water = $water } | ConvertTo-Json -Depth 4 -Compress) + ";"
[IO.File]::WriteAllText("$root\prototype\story\film-data.js", $js, (New-Object Text.UTF8Encoding($false)))
"frame $(@($fr).Count)  eligible $(@($fr | Where-Object { $_.e -eq 1 }).Count)  sampled $(@($fr | Where-Object { $_.s -gt 0 }).Count)  baseline $(@($bl).Count)"
