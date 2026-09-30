# Builds the area-of-interest KML requested by SANSA Earth Observation (customers-eo@sansa.org.za).
#   1. eThekwini study area  - the same bounds as the story map (30.74-31.14 E, 29.53-30.06 S)
#   2. Priority area         - Lamontville / Gwala St camp (#32) to the Umbilo residence (#54), plus a 1.5 km margin
#   3. Camp locations        - the 28 eThekwini temporary sites with coordinates (public site list)
# Output: data/aoi/ethekwini_flood_aoi.kml
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$inv = [Globalization.CultureInfo]::InvariantCulture
$sites = Import-Csv "$root\data\tra_sites_exposure.csv" -Encoding UTF8 | Where-Object { $_.municipality -eq 'eThekwini' -and $_.lat -and $_.lon }
function F([double]$v) { $v.ToString('0.#####', $inv) }
function Box($w, $s, $e, $n) { "$(F $w),$(F $n),0 $(F $e),$(F $n),0 $(F $e),$(F $s),0 $(F $w),$(F $s),0 $(F $w),$(F $n),0" }
function Esc($t) { [Security.SecurityElement]::Escape($t) }
$g = $sites | Where-Object { $_.id -in '32', '54' }
$m = 0.015   # ~1.5 km
$lats = $g | ForEach-Object { [double]::Parse($_.lat, $inv) }; $lons = $g | ForEach-Object { [double]::Parse($_.lon, $inv) }
$pri = Box (($lons | Measure-Object -Minimum).Minimum - $m) (($lats | Measure-Object -Minimum).Minimum - $m) (($lons | Measure-Object -Maximum).Maximum + $m) (($lats | Measure-Object -Maximum).Maximum + $m)
$poly = { param($name, $desc, $coords, $style) "<Placemark><name>$name</name><description>$desc</description><styleUrl>#$style</styleUrl><Polygon><outerBoundaryIs><LinearRing><coordinates>$coords</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>" }
$pts = ($sites | ForEach-Object { "<Placemark><name>$(Esc $_.site)</name><description>Temporary site #$($_.id), established $($_.est_year) (public site list; location approximate)</description><styleUrl>#camp</styleUrl><Point><coordinates>$(F ([double]::Parse($_.lon,$inv))),$(F ([double]::Parse($_.lat,$inv))),0</coordinates></Point></Placemark>" }) -join "`n"
$kml = @"
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document>
<name>eThekwini flood AOI - Mthiyane (Harvard GSD)</name>
<Style id="aoi"><LineStyle><color>ff2f79ad</color><width>2</width></LineStyle><PolyStyle><color>332f79ad</color></PolyStyle></Style>
<Style id="pri"><LineStyle><color>ff4f5bff</color><width>3</width></LineStyle><PolyStyle><color>404f5bff</color></PolyStyle></Style>
<Style id="camp"><IconStyle><color>ff42b9f4</color><scale>0.8</scale></IconStyle></Style>
$(& $poly '1. eThekwini study area' 'Primary AOI: eThekwini Municipality core (Tongaat/Verulam to Amanzimtoti, coast to KwaNdengezi/Molweni).' (Box 30.74 -30.06 31.14 -29.53) 'aoi')
$(& $poly '2. Priority: Lamontville / Gwala St to Umbilo' 'Highest priority for sub-metre imagery: Gwala St camp (flooded Feb 2025) and the Umbilo residence.' $pri 'pri')
<Folder><name>3. Temporary relocation sites ($(@($sites).Count))</name>
$pts
</Folder>
</Document></kml>
"@
New-Item -ItemType Directory -Force "$root\data\aoi" | Out-Null
[IO.File]::WriteAllText("$root\data\aoi\ethekwini_flood_aoi.kml", $kml, (New-Object Text.UTF8Encoding($false)))
"sites: $(@($sites).Count)  priority box: $pri"
