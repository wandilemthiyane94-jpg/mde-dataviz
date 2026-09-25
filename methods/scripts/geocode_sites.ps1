<#
.SYNOPSIS
  Geocode flood death sites in data\death_site_language_flat.json.

.DESCRIPTION
  Reproducible geocoding step for the last-mile project (Windows PowerShell 5.1,
  no Python/Node required).

  Method, in order of preference:
    1. census_place_centroid - every row's census_url points at a Census 2011 place
       on census2011.adrianfrith.com. Each place page offers the Stats SA boundary
       as KML at /place/<id>/kml. The script downloads the KML (cached on disk),
       computes the area-weighted polygon centroid (holes subtracted, longitude
       scaled by cos(latitude) before the shoelace formula), and uses it.
    2. nominatim - OpenStreetMap Nominatim search (countrycodes=za), used for
       (a) point features named in the row (bridges, hospitals, schools, roads)
           listed in the $Overrides table below,
       (b) named towns/villages whose row census_url is only a municipality or
           district,
       (c) rows without census_url, and census places whose KML cannot be read.
       A Nominatim candidate is accepted only if it lies inside, or within
       30 km of, the expected municipality polygon (from the census breadcrumb).
       Candidates further away are rejected and the census centroid is used.
    3. If neither works, lat/lon are left null with a note. Coordinates are
       never typed in by hand.

  Confidence:
    high   - census centroid of a main place / sub place, or a Nominatim result
             whose name matches the query and which lies inside the row's census
             place (or municipality when the row census is coarser).
    medium - Nominatim result with ambiguity (several candidates inside the
             area, name only partially matches, result outside the census
             place but within 30 km of the municipality, line features such as
             roads/rivers, or overrides capped at medium), or a census centroid
             that falls more than 1 km outside its own (concave) polygon.
    low    - fell back to the centroid of a municipality, district or province.
  geocode_flag = "check" when the final point is > 30 km from the expected
  municipality polygon.

  Politeness: descriptive User-Agent, >= 1.1 s between Nominatim requests,
  0.5 s between census requests, and all responses cached in
  data\raw\geocode_cache.json (Nominatim + parsed census pages) and
  data\raw\census_kml\<id>.kml (raw boundaries). Re-running uses the cache;
  delete the cache files (or pass -Refresh) to refetch.

.PARAMETER Offline
  Use cached responses only; never hit the network.
.PARAMETER Refresh
  Ignore the cache and refetch everything (cache is overwritten).
#>
[CmdletBinding()]
param(
    [string]$InputPath,    # default: <script>\..\..\data\death_site_language_flat.json
    [string]$OutputPath,   # default: <script>\..\..\data\death_sites_geocoded.json
    [string]$CachePath,    # default: <script>\..\..\data\raw\geocode_cache.json
    [string]$KmlDir,       # default: <script>\..\..\data\raw\census_kml
    [string]$LogPath,      # default: <script>\..\geocode_log.md
    [switch]$Offline,
    [switch]$Refresh
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UserAgent   = 'last-mile-research/1.0 (academic project; flood death-site geocoding)'
$CensusBase  = 'https://census2011.adrianfrith.com'
$NominatimBase = 'https://nominatim.openstreetmap.org/search'
$CheckKm     = 30.0
$Utf8NoBom   = New-Object System.Text.UTF8Encoding($false)
$Inv         = [System.Globalization.CultureInfo]::InvariantCulture

# ---------------------------------------------------------------------------
# Row-level overrides (curated, documented). Matched against the row's `place`
# text with a case-insensitive regex. Each entry lists Nominatim queries tried
# in order (first accepted wins) or an alternative census place id.
#   kind      : feature (point feature named in the row) | named_place (town or
#               village named in the row but census_url is coarse) | census_alt
#   max_conf  : optional cap on confidence (e.g. roads/rivers are lines, so a
#               Nominatim point on them is only "medium").
#   expect    : optional census id of the expected region (only needed when
#               the row has no census_url).
# Line features (rivers, highways) are NOT sent to Nominatim when the row
# already has a main/sub place polygon, because Nominatim returns an arbitrary
# point on a line that can be tens of km long.
# ---------------------------------------------------------------------------
$Overrides = @(
    @{ match='^Efata Bridge';                    kind='feature';     queries=@('Efata School for the Deaf and Blind, Mthatha','Efata, Mthatha') ; max_conf='medium'; why='bridge on R61 near Efata School; school used as point reference' }
    @{ match='^Shixini village';                 kind='named_place'; queries=@('Shixini, Eastern Cape','Shixini, Mbhashe','Shixini') }
    @{ match='^Limpopo River near Beitbridge';   kind='feature';     queries=@('Beitbridge Border Post','Beit Bridge') ; max_conf='medium'; why='river is a line; SA side of Beitbridge crossing used as reference' }
    @{ match='^Chatty, Gqeberha';                kind='named_place'; queries=@('Chatty, Gqeberha','Chatty, Nelson Mandela Bay','Chatty') }
    @{ match='^Low-lying bridge close to Hartbeespoort Dam'; kind='feature'; queries=@('Hartbeespoort Dam') ; max_conf='medium'; why='bridge not identified; dam used as reference point' }
    @{ match='^Lemenong';                        kind='named_place'; queries=@('Lemenong, North West','Lemenong') ; expect='6' }
    @{ match='^Nquthu, Umzinyathi';              kind='named_place'; queries=@('Nquthu, KwaZulu-Natal') ; max_conf='medium'; why='source may mean the municipality rather than the town' }
    @{ match='^Nquthu \(among';                  kind='named_place'; queries=@('Nquthu, KwaZulu-Natal') ; max_conf='medium'; why='source may mean the municipality rather than the town' }
    @{ match='^Prince Mshiyeni Memorial Hospital'; kind='feature';   queries=@('Prince Mshiyeni Memorial Hospital, Umlazi','Prince Mshiyeni Memorial Hospital') }
    @{ match='^Umlazi \(Hambakahle Mkhonto Road\)'; kind='feature';  queries=@('Hambakahle Mkhonto Road, Umlazi') ; max_conf='medium'; why='road is a line feature' }
    @{ match='^KwaMakhutha \(Sewula School\)';   kind='feature';     queries=@('Sewula, KwaMakhutha','Sewula High School') }
    @{ match='^Pentecostal Holiness Church, Empangeni'; kind='feature'; queries=@('Pentecostal Holiness Church, Empangeni') }
    @{ match='^Westcliff, Chatsworth';           kind='feature';     queries=@('Westcliff Secondary School, Chatsworth','Westcliff Secondary School') }
    @{ match='^Westville \(Kingsmead Drive\)';   kind='feature';     queries=@('Kingsmead Drive, Westville') ; max_conf='medium'; why='road is a line feature' }
    @{ match='^Masoyi';                          kind='named_place'; queries=@('Masoyi, Mpumalanga','Masoyi') }
    @{ match='^Coffee Bay area';                 kind='census_alt';  census_id='294453'; why='row census_url is the KSD municipality; the dataset already links Coffee Bay to census main place 294453' }
    @{ match='^AbaQulusi \(Vryheid area\)';      kind='named_place'; queries=@('Vryheid, KwaZulu-Natal') ; max_conf='medium'; why='source says "Vryheid area"; town used' }
    @{ match='^Mataffin';                        kind='named_place'; queries=@('Mataffin, Mbombela','Mataffin') }
    @{ match='^Ga-Mochemi village';              kind='named_place'; queries=@('Ga-Mochemi, Limpopo','Mochemi, Limpopo') }
    @{ match='^Shepstone Road caravan park';     kind='feature';     queries=@('Shepstone Road, Ladysmith') ; max_conf='medium'; why='road is a line feature' }
    @{ match='^Eshowe$';                         kind='named_place'; queries=@('Eshowe, KwaZulu-Natal') }
    @{ match='^KwaHlabisa$';                     kind='named_place'; queries=@('KwaHlabisa, KwaZulu-Natal','Hlabisa, KwaZulu-Natal') ; why='OSM names the town Hlabisa (KwaHlabisa = Hlabisa)' }
    @{ match='^Vastrap informal settlement';     kind='named_place'; queries=@('Vastrap, Gqeberha','Vastrap, Nelson Mandela Bay') }
    @{ match='^Malangeni, uMdoni';               kind='named_place'; queries=@('Malangeni, Umdoni','Malangeni, KwaZulu-Natal') }
    @{ match='^Stapleton Road bridge, Pinetown'; kind='feature';     queries=@('Stapleton Road, Pinetown') ; max_conf='medium'; why='road is a line feature' }
    @{ match='^Low-level bridge, Longacres Drive'; kind='feature';   queries=@('Longacres Drive, Amanzimtoti') ; max_conf='medium'; why='road is a line feature' }
    @{ match='^Mutale River, Vhembe';            kind='feature';     queries=@('Mutale River') ; max_conf='medium'; why='river is a line; exact recovery point unknown' }
    @{ match='^N2 near uMkhuze';                 kind='named_place'; queries=@('Mkuze, KwaZulu-Natal','uMkhuze, KwaZulu-Natal') ; max_conf='medium'; why='crash was on the N2 near the town; town used' }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Resolve-FullPath([string]$p) { [System.IO.Path]::GetFullPath($p) }

function ConvertTo-HashtableDeep($o) {
    if ($null -eq $o) { return $null }
    if ($o -is [System.Management.Automation.PSCustomObject]) {
        $h = [ordered]@{}
        foreach ($p in $o.PSObject.Properties) { $h[$p.Name] = ConvertTo-HashtableDeep $p.Value }
        return $h
    }
    if ($o -is [System.Collections.IEnumerable] -and -not ($o -is [string])) {
        $a = New-Object System.Collections.ArrayList
        foreach ($i in $o) { [void]$a.Add((ConvertTo-HashtableDeep $i)) }
        return ,$a.ToArray()
    }
    return $o
}

function Write-Utf8NoBom([string]$path, [string]$text) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $text, $Utf8NoBom)
}

$script:LastNominatim = [datetime]::MinValue
$script:LastCensus    = [datetime]::MinValue

function Invoke-Http([string]$url, [string]$kind) {
    if ($Offline) { throw "offline mode: no cached response for $url" }
    if ($kind -eq 'nominatim') {
        $wait = 1100 - ((Get-Date) - $script:LastNominatim).TotalMilliseconds
        if ($wait -gt 0) { Start-Sleep -Milliseconds ([int]$wait) }
    } else {
        $wait = 500 - ((Get-Date) - $script:LastCensus).TotalMilliseconds
        if ($wait -gt 0) { Start-Sleep -Milliseconds ([int]$wait) }
    }
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $url -UserAgent $UserAgent -Headers @{ 'Accept-Language' = 'en' } -TimeoutSec 60
    } finally {
        if ($kind -eq 'nominatim') { $script:LastNominatim = Get-Date } else { $script:LastCensus = Get-Date }
    }
    $bytes = $r.RawContentStream.ToArray()
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Get-UtcStamp { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }

# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $InputPath)  { $InputPath  = Join-Path $ScriptDir '..\..\data\death_site_language_flat.json' }
if (-not $OutputPath) { $OutputPath = Join-Path $ScriptDir '..\..\data\death_sites_geocoded.json' }
if (-not $CachePath)  { $CachePath  = Join-Path $ScriptDir '..\..\data\raw\geocode_cache.json' }
if (-not $KmlDir)     { $KmlDir     = Join-Path $ScriptDir '..\..\data\raw\census_kml' }
if (-not $LogPath)    { $LogPath    = Join-Path $ScriptDir '..\geocode_log.md' }
$InputPath  = Resolve-FullPath $InputPath
$OutputPath = Resolve-FullPath $OutputPath
$CachePath  = Resolve-FullPath $CachePath
$KmlDir     = Resolve-FullPath $KmlDir
$LogPath    = Resolve-FullPath $LogPath
if (-not (Test-Path $KmlDir)) { New-Item -ItemType Directory -Force $KmlDir | Out-Null }

$Cache = [ordered]@{ census = [ordered]@{}; nominatim = [ordered]@{} }
if ((Test-Path $CachePath) -and -not $Refresh) {
    $c = ConvertTo-HashtableDeep ([System.IO.File]::ReadAllText($CachePath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)
    if ($c.Contains('census') -and $c.census)       { $Cache.census = $c.census }
    if ($c.Contains('nominatim') -and $c.nominatim) { $Cache.nominatim = $c.nominatim }
}
function Save-Cache { Write-Utf8NoBom $CachePath ($Cache | ConvertTo-Json -Depth 10) }

# ---------------------------------------------------------------------------
# Census place: page (name, level, breadcrumb) + KML boundary
# ---------------------------------------------------------------------------
function Get-CensusPlace([string]$id) {
    if ($Cache.census.Contains($id)) { return $Cache.census[$id] }
    $url  = "$CensusBase/place/$id"
    $html = Invoke-Http $url 'census'
    $m = [regex]::Match($html, '<title[^>]*>Census 2011: ([^:<]+): ([^<]+)</title>')
    if (-not $m.Success) { throw "could not parse title of $url" }
    $crumbs = @()
    foreach ($b in [regex]::Matches($html, '<li class="breadcrumb-item"><a href="/place/(\d+)">([^<]+)</a></li>')) {
        $crumbs += ,([ordered]@{ id = $b.Groups[1].Value; name = [System.Net.WebUtility]::HtmlDecode($b.Groups[2].Value) })
    }
    $rec = [ordered]@{
        id         = $id
        level      = $m.Groups[1].Value.Trim()
        name       = [System.Net.WebUtility]::HtmlDecode($m.Groups[2].Value.Trim())
        breadcrumb = $crumbs
        page_url   = $url
        kml_url    = "$CensusBase/place/$id/kml"
        fetched_at = Get-UtcStamp
    }
    $Cache.census[$id] = $rec
    Save-Cache
    return $rec
}

$GeomCache = @{}
function Get-CensusGeometry([string]$id) {
    if ($GeomCache.ContainsKey($id)) { return $GeomCache[$id] }
    $kmlPath = Join-Path $KmlDir "$id.kml"
    if ($Refresh -or -not (Test-Path $kmlPath)) {
        $txt = Invoke-Http "$CensusBase/place/$id/kml" 'census'
        Write-Utf8NoBom $kmlPath $txt
    }
    $kml = [System.IO.File]::ReadAllText($kmlPath, [System.Text.Encoding]::UTF8)
    $rings = New-Object System.Collections.ArrayList
    foreach ($bm in [regex]::Matches($kml, '<(outerBoundaryIs|innerBoundaryIs)>\s*<LinearRing>\s*<coordinates>([^<]+)</coordinates>')) {
        $outer = ($bm.Groups[1].Value -eq 'outerBoundaryIs')
        $toks = $bm.Groups[2].Value.Trim() -split '\s+'
        $xs = New-Object 'double[]' $toks.Count
        $ys = New-Object 'double[]' $toks.Count
        for ($i = 0; $i -lt $toks.Count; $i++) {
            $p = $toks[$i].Split(',')
            $xs[$i] = [double]::Parse($p[0], $Inv)
            $ys[$i] = [double]::Parse($p[1], $Inv)
        }
        [void]$rings.Add(@{ outer = $outer; xs = $xs; ys = $ys })
    }
    if ($rings.Count -eq 0) { throw "no polygon coordinates in $kmlPath" }
    $g = @{ rings = $rings.ToArray(); nOuter = @($rings | Where-Object { $_.outer }).Count }
    $GeomCache[$id] = $g
    return $g
}

function Get-Centroid($g) {
    # Area-weighted centroid; longitude scaled by cos(lat0) so areas are ~equal-area locally.
    $lat0 = ($g.rings[0].ys | Measure-Object -Average).Average
    $k = [Math]::Cos($lat0 * [Math]::PI / 180.0)
    $sumA = 0.0; $sumX = 0.0; $sumY = 0.0
    foreach ($r in $g.rings) {
        $xs = $r.xs; $ys = $r.ys; $n = $xs.Length
        $a = 0.0; $cx = 0.0; $cy = 0.0
        for ($i = 0; $i -lt $n; $i++) {
            $j = ($i + 1) % $n
            $x0 = $xs[$i] * $k; $x1 = $xs[$j] * $k
            $cr = $x0 * $ys[$j] - $x1 * $ys[$i]
            $a += $cr; $cx += ($x0 + $x1) * $cr; $cy += ($ys[$i] + $ys[$j]) * $cr
        }
        if ($a -eq 0) { continue }
        $a = $a / 2.0; $cx = $cx / (6.0 * $a); $cy = $cy / (6.0 * $a)
        $w = [Math]::Abs($a); if (-not $r.outer) { $w = -$w }
        $sumA += $w; $sumX += $w * $cx; $sumY += $w * $cy
    }
    if ($sumA -eq 0) { throw 'degenerate polygon' }
    return @{ lat = $sumY / $sumA; lon = ($sumX / $sumA) / $k }
}

function Test-InRing([double]$x, [double]$y, $r) {
    $xs = $r.xs; $ys = $r.ys; $n = $xs.Length; $in = $false; $j = $n - 1
    for ($i = 0; $i -lt $n; $i++) {
        if ((($ys[$i] -gt $y) -ne ($ys[$j] -gt $y)) -and ($x -lt ($xs[$j] - $xs[$i]) * ($y - $ys[$i]) / ($ys[$j] - $ys[$i]) + $xs[$i])) { $in = -not $in }
        $j = $i
    }
    return $in
}

function Test-InGeom([double]$lat, [double]$lon, $g) {
    $c = 0
    foreach ($r in $g.rings) { if (Test-InRing $lon $lat $r) { if ($r.outer) { $c++ } else { $c-- } } }
    return ($c -gt 0)
}

function Get-DistanceKmToGeom([double]$lat, [double]$lon, $g) {
    # 0 if inside; else minimum distance to any boundary segment (local equirectangular, km).
    if (Test-InGeom $lat $lon $g) { return 0.0 }
    $kx = 111.320 * [Math]::Cos($lat * [Math]::PI / 180.0); $ky = 110.574
    $best = [double]::MaxValue
    foreach ($r in $g.rings) {
        $xs = $r.xs; $ys = $r.ys; $n = $xs.Length
        for ($i = 0; $i -lt $n - 1; $i++) {
            $ax = ($xs[$i] - $lon) * $kx; $ay = ($ys[$i] - $lat) * $ky
            $bx = ($xs[$i+1] - $lon) * $kx; $by = ($ys[$i+1] - $lat) * $ky
            $dx = $bx - $ax; $dy = $by - $ay; $L = $dx*$dx + $dy*$dy
            $t = 0.0; if ($L -gt 0) { $t = -($ax*$dx + $ay*$dy) / $L; if ($t -lt 0) { $t = 0.0 } elseif ($t -gt 1) { $t = 1.0 } }
            $px = $ax + $t*$dx; $py = $ay + $t*$dy
            $d = [Math]::Sqrt($px*$px + $py*$py)
            if ($d -lt $best) { $best = $d }
        }
    }
    return $best
}

function Get-ExpectedRegionId($censusRec) {
    # Deepest municipality/district (3-digit code) in the chain; else province (1 digit).
    $ids = @($censusRec.breadcrumb | ForEach-Object { $_.id }) + @($censusRec.id)
    $muni = @($ids | Where-Object { $_.Length -eq 3 })
    if ($muni.Count -gt 0) { return $muni[-1] }
    $prov = @($ids | Where-Object { $_.Length -eq 1 })
    if ($prov.Count -gt 0) { return $prov[-1] }
    return $null
}

function Get-RegionName([string]$id) {
    try { $r = Get-CensusPlace $id; return "$($r.name) ($($r.level) $id)" } catch { return $id }
}

# ---------------------------------------------------------------------------
# Nominatim
# ---------------------------------------------------------------------------
function Get-Nominatim([string]$q) {
    if ($Cache.nominatim.Contains($q)) { return $Cache.nominatim[$q] }
    $url = $NominatimBase + '?format=jsonv2&countrycodes=za&limit=5&q=' + [uri]::EscapeDataString($q)
    $txt = Invoke-Http $url 'nominatim'
    $res = @()
    $parsed = ConvertFrom-Json $txt
    foreach ($x in $parsed) {
        if ($null -eq $x) { continue }
        $res += ,([ordered]@{
            display_name = $x.display_name; name = $x.name
            osm_type = $x.osm_type; osm_id = $x.osm_id
            lat = [double]::Parse([string]$x.lat, $Inv); lon = [double]::Parse([string]$x.lon, $Inv)
            category = $x.category; type = $x.type; place_rank = $x.place_rank; importance = $x.importance
        })
    }
    $rec = [ordered]@{ query = $q; url = $url; fetched_at = Get-UtcStamp; results = $res }
    $Cache.nominatim[$q] = $rec
    Save-Cache
    return $rec
}

function Get-NormName([string]$s) { if ($null -eq $s) { return '' }; ($s.ToLowerInvariant() -replace '[^a-z0-9]', '') }

# Name match: 'exact' (normalised names equal), 'partial' (one contains the other), or $null.
function Get-NameMatch([string]$q, $cand) {
    $qn = Get-NormName (($q -split ',')[0])
    $cn = Get-NormName $cand.name
    if ($cn -eq '') { $cn = Get-NormName (($cand.display_name -split ',')[0]) }
    if ($qn -eq '' -or $cn -eq '') { return $null }
    if ($cn -eq $qn) { return 'exact' }
    if ($cn.Contains($qn) -or $qn.Contains($cn)) { return 'partial' }
    return $null
}

function Get-KmBetween($a, $b) {
    $kx = 111.320 * [Math]::Cos($a.lat * [Math]::PI / 180.0)
    $dx = ($a.lon - $b.lon) * $kx; $dy = ($a.lat - $b.lat) * 110.574
    return [Math]::Sqrt($dx*$dx + $dy*$dy)
}

# Try the override queries in order; return a result hashtable or $null (reasons go to $notes).
# Candidate rules:
#   - the candidate name must match the query name (exact or partial); others are rejected;
#   - for kind 'named_place' the candidate must be an OSM place/boundary/landuse object
#     (so e.g. a school or river that merely shares the name is rejected);
#   - candidates inside the expected region are preferred; the nearest outside candidate
#     is accepted only if <= $CheckKm km away (or if $allowFar, then flagged 'check').
function Resolve-ByNominatim($ov, $placeGeom, $regionGeom, [bool]$regionIsProvince, [bool]$allowFar, [System.Collections.ArrayList]$notes) {
    foreach ($q in $ov.queries) {
        try { $nr = Get-Nominatim $q } catch { [void]$notes.Add("Nominatim '$q' failed: $($_.Exception.Message)"); continue }
        if (@($nr.results).Count -eq 0) { [void]$notes.Add("Nominatim '$q': no results"); continue }
        $scored = @()
        foreach ($c in @($nr.results)) {
            $nm = Get-NameMatch $q $c
            if (-not $nm) { continue }
            if ($ov.kind -eq 'named_place' -and @('place', 'boundary', 'landuse') -notcontains $c.category) { continue }
            $dReg = $null; $dPl = $null
            if ($regionGeom) { $dReg = Get-DistanceKmToGeom $c.lat $c.lon $regionGeom }
            if ($placeGeom)  { $dPl  = Get-DistanceKmToGeom $c.lat $c.lon $placeGeom }
            $scored += ,@{ c = $c; dReg = $dReg; dPl = $dPl; nm = $nm }
        }
        if ($scored.Count -eq 0) {
            [void]$notes.Add(("Nominatim '{0}': {1} result(s) but none with matching name/type (e.g. '{2}' [{3}/{4}]); rejected" -f $q, @($nr.results).Count, @($nr.results)[0].display_name, @($nr.results)[0].category, @($nr.results)[0].type))
            continue
        }
        $inside = @($scored | Where-Object { $null -eq $_.dReg -or $_.dReg -eq 0 })
        $pool = $inside
        if ($pool.Count -eq 0) { $pool = @($scored | Sort-Object { $_.dReg }) }
        $pick = @(@($pool | Where-Object { $_.nm -eq 'exact' }) + @($pool | Where-Object { $_.nm -ne 'exact' }))[0]
        $far = ($null -ne $pick.dReg -and $pick.dReg -gt $CheckKm)
        if ($far -and -not $allowFar) {
            [void]$notes.Add(("Nominatim '{0}': nearest matching candidate '{1}' is {2:N1} km outside expected region; rejected" -f $q, $pick.c.display_name, $pick.dReg))
            continue
        }
        $conf = 'high'; $why = @()
        if ($pick.nm -ne 'exact') { $conf = 'medium'; $why += "OSM name '$($pick.c.name)' only partially matches query" }
        $others = @($inside | Where-Object { $_.nm -eq 'exact' -and $_ -ne $pick -and (Get-KmBetween $_.c $pick.c) -gt 5 })
        if ($others.Count -gt 0) { $conf = 'medium'; $why += "$($others.Count) other same-name candidate(s) > 5 km away inside expected region" }
        if ($null -ne $pick.dReg -and $pick.dReg -gt 0) { $conf = 'medium'; $why += ('{0:N1} km outside expected region polygon' -f $pick.dReg) }
        if ($null -ne $pick.dPl -and $pick.dPl -gt 0 -and $ov.kind -eq 'feature') { $conf = 'medium'; $why += ('{0:N1} km outside row census place polygon' -f $pick.dPl) }
        if ($regionIsProvince -and $conf -eq 'high') { $conf = 'medium'; $why += 'only province known, so same-name places elsewhere in the province cannot be excluded' }
        if ($ov.Contains('max_conf') -and $ov.max_conf -eq 'medium' -and $conf -eq 'high') { $conf = 'medium' }
        if ($ov.Contains('why') -and $ov.why) { $why += $ov.why }
        return @{
            lat = $pick.c.lat; lon = $pick.c.lon; query = $q; conf = $conf
            match = ('osm:{0}/{1} | {2}' -f $pick.c.osm_type, $pick.c.osm_id, $pick.c.display_name)
            note = ($why -join '; '); fetched_at = $nr.fetched_at; dReg = $pick.dReg
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$rows = ConvertFrom-Json ([System.IO.File]::ReadAllText($InputPath, [System.Text.Encoding]::UTF8))
Write-Host "Rows: $($rows.Count)"

# 1. Dedupe: site key = census id, or 'place:<text>' when census_url is null.
$sites = [ordered]@{}
for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    if ($r.census_url) { $key = ($r.census_url -replace '^.*/place/', '').Trim('/') } else { $key = 'place:' + $r.place }
    if (-not $sites.Contains($key)) { $sites[$key] = New-Object System.Collections.ArrayList }
    [void]$sites[$key].Add($i)
}
Write-Host "Unique sites (census_url / place): $($sites.Count)"

# 2. Census centroid for every unique census id.
$censusGeo = @{}
foreach ($key in $sites.Keys) {
    if ($key -like 'place:*') { continue }
    $info = @{ ok = $false; err = $null }
    try {
        $rec = Get-CensusPlace $key; $info.rec = $rec
        $g = Get-CensusGeometry $key
        $c = Get-Centroid $g
        $info.ok = $true; $info.rec = $rec; $info.geom = $g; $info.lat = $c.lat; $info.lon = $c.lon
        $info.inside = Test-InGeom $c.lat $c.lon $g
        $info.outKm = 0.0; if (-not $info.inside) { $info.outKm = Get-DistanceKmToGeom $c.lat $c.lon $g }
        $info.region = Get-ExpectedRegionId $rec
    } catch { $info.err = $_.Exception.Message; Write-Warning "census $key : $($info.err)" }
    $censusGeo[$key] = $info
}

$fineLevels = @('Main Place', 'Sub Place')
$usedOverrides = @{}
$out = New-Object System.Collections.ArrayList
$runStamp = Get-UtcStamp

for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    if ($r.census_url) { $key = ($r.census_url -replace '^.*/place/', '').Trim('/') } else { $key = 'place:' + $r.place }
    $notes = New-Object System.Collections.ArrayList
    $res = $null
    $ov = $null
    foreach ($o in $Overrides) { if ($r.place -match $o.match) { $ov = $o; $usedOverrides[$o.match] = 1; break } }

    $ci = $null; if ($censusGeo.ContainsKey($key)) { $ci = $censusGeo[$key] }
    $placeGeom = $null; $regionId = $null; $regionGeom = $null
    if ($ci -and $ci.ok) {
        if ($fineLevels -contains $ci.rec.level) { $placeGeom = $ci.geom }
        $regionId = $ci.region
    }
    if ($ov -and $ov.Contains('expect')) { $regionId = $ov.expect }
    if ($regionId) { try { $regionGeom = Get-CensusGeometry $regionId } catch { [void]$notes.Add("region $regionId geometry unavailable") } }

    # 2b. Override: alternative census place.
    if ($ov -and $ov.kind -eq 'census_alt') {
        try {
            $arec = Get-CensusPlace $ov.census_id; $ag = Get-CensusGeometry $ov.census_id; $ac = Get-Centroid $ag
            $conf = 'low'; if ($fineLevels -contains $arec.level) { $conf = 'high' }
            $res = @{ lat = $ac.lat; lon = $ac.lon; method = 'census_place_centroid'; query = $arec.kml_url; conf = $conf
                      match = "census2011:$($arec.id) | $($arec.level): $($arec.name)"; fetched_at = $arec.fetched_at
                      note = "override: $($ov.why)" }
        } catch { [void]$notes.Add("alt census $($ov.census_id) failed: $($_.Exception.Message)") }
    }

    # 3/4. Override: Nominatim for named features / named places.
    if (-not $res -and $ov -and $ov.kind -ne 'census_alt') {
        $nm = Resolve-ByNominatim $ov $placeGeom $regionGeom ($null -ne $regionId -and $regionId.Length -eq 1) (-not ($ci -and $ci.ok)) $notes
        if ($nm) {
            $res = @{ lat = $nm.lat; lon = $nm.lon; method = 'nominatim'; query = $nm.query; conf = $nm.conf; match = $nm.match
                      fetched_at = $nm.fetched_at; note = ("$($ov.kind) named in row geocoded via Nominatim" + $(if ($nm.note) { "; $($nm.note)" } else { '' })) }
        } else {
            [void]$notes.Add("$($ov.kind) not found by Nominatim (matching name/type, within $CheckKm km of expected region); used census place")
        }
    }

    # 2. Census centroid (default / fallback).
    if (-not $res -and $ci -and $ci.ok) {
        $conf = 'low'
        if ($fineLevels -contains $ci.rec.level) { $conf = 'high' }
        $n = "census $($ci.rec.level) boundary centroid"
        if (-not $ci.inside) {
            $n += ('; centroid falls {0:N2} km outside the (concave/multi-part) polygon' -f $ci.outKm)
            if ($conf -eq 'high' -and $ci.outKm -gt 1.0) { $conf = 'medium' }
        }
        if ($conf -eq 'low') { $n += '; row is located only at municipality/district/province level' }
        $res = @{ lat = $ci.lat; lon = $ci.lon; method = 'census_place_centroid'; query = $ci.rec.kml_url; conf = $conf
                  match = "census2011:$($ci.rec.id) | $($ci.rec.level): $($ci.rec.name)"; fetched_at = $ci.rec.fetched_at; note = $n }
    }

    # 3. Nominatim fallback when census page/KML failed (or no census_url and no override).
    if (-not $res) {
        $q = $null
        if ($ci -and $ci.rec) {
            $crumb = @($ci.rec.breadcrumb | Where-Object { $_.name -ne 'Home' } | ForEach-Object { $_.name })
            [array]::Reverse($crumb)
            $q = (@($ci.rec.name) + @($crumb | Select-Object -First 2)) -join ', '
        } elseif (-not $ov) {
            $q = ($r.place -split '\(')[0].Trim().TrimEnd(',', '-', ' ')
        }
        if ($q) {
            $nm = Resolve-ByNominatim @{ kind = 'named_place'; queries = @($q); max_conf = 'medium' } $null $regionGeom ($null -ne $regionId -and $regionId.Length -eq 1) $true $notes
            if ($nm) { $res = @{ lat = $nm.lat; lon = $nm.lon; method = 'nominatim'; query = $nm.query; conf = $nm.conf; match = $nm.match; fetched_at = $nm.fetched_at; note = "fallback: census geometry unavailable; $($nm.note)" } }
        }
    }

    # Distance / check flag.
    $flag = $null
    if ($res -and $regionGeom) {
        $d = Get-DistanceKmToGeom $res.lat $res.lon $regionGeom
        if ($d -gt $CheckKm) { $flag = 'check'; [void]$notes.Add(('{0:N1} km from expected region {1}' -f $d, (Get-RegionName $regionId))) }
    } elseif ($res -and -not $regionGeom) {
        [void]$notes.Add('no expected region polygon to check distance against')
    }

    $o = [ordered]@{}
    foreach ($p in $r.PSObject.Properties) { $o[$p.Name] = $p.Value }
    if ($res) {
        $o.lat = [Math]::Round([double]$res.lat, 6); $o.lon = [Math]::Round([double]$res.lon, 6)
        $o.geocode_method = $res.method; $o.geocode_query = $res.query; $o.geocode_match = $res.match
        $o.geocode_confidence = $res.conf
        $allNotes = @($res.note) + @($notes) | Where-Object { $_ }
        $o.geocode_note = ($allNotes -join ' | ')
        $o.geocoded_at = $res.fetched_at
    } else {
        $o.lat = $null; $o.lon = $null; $o.geocode_method = $null; $o.geocode_query = $null; $o.geocode_match = $null
        $o.geocode_confidence = $null
        $o.geocode_note = ((@('could not be geocoded') + @($notes)) -join ' | ')
        $o.geocoded_at = $runStamp
    }
    $o.geocode_flag = $flag
    $o.geocode_site_id = $key
    $o.geocode_expected_region = $regionId
    [void]$out.Add([pscustomobject]$o)
}

foreach ($o in $Overrides) { if (-not $usedOverrides.ContainsKey($o.match)) { Write-Warning "override matched no row: $($o.match)" } }

Write-Utf8NoBom $OutputPath (ConvertTo-Json -InputObject $out.ToArray() -Depth 6)
Save-Cache
Write-Host "Wrote $OutputPath"

# ---------------------------------------------------------------------------
# Log
# ---------------------------------------------------------------------------
$sb = New-Object System.Text.StringBuilder
function L([string]$s) { [void]$sb.AppendLine($s) }
$all = $out.ToArray()
L '# Geocoding log - flood death sites'
L ''
L "Generated by ``methods/scripts/geocode_sites.ps1`` on $runStamp (UTC)."
L ''
L "- Input: ``data/death_site_language_flat.json`` ($($all.Count) rows)"
L "- Output: ``data/death_sites_geocoded.json``"
L "- Unique sites after dedupe (census_url, else place text): $($sites.Count)"
L "- Cache: ``data/raw/geocode_cache.json`` (census page metadata + Nominatim responses) and ``data/raw/census_kml/<id>.kml`` (raw Stats SA boundaries)"
L ''
L '## Method'
L ''
L '1. **census_place_centroid** (preferred): each census2011.adrianfrith.com place page links a KML boundary (`/place/<id>/kml`). The script computes the area-weighted polygon centroid (holes subtracted; longitude scaled by cos(latitude)).'
L '2. **nominatim**: OpenStreetMap Nominatim (`countrycodes=za`, `limit=5`, User-Agent `last-mile-research/1.0`, >= 1.1 s between requests, cached) for point features named in the row (bridges, hospitals, schools, roads), for towns/villages whose census_url is only a municipality/district, and for rows with no census_url. The queries are listed in the `$Overrides` table at the top of the script. A candidate is accepted only if its OSM name matches the query (and, for towns/villages, it is an OSM place/boundary/landuse object rather than e.g. a school or river of the same name) and it lies inside, or within 30 km of, the expected municipality polygon; otherwise the census centroid is used.'
L '3. Line features (rivers, highways) are not sent to Nominatim when the row already has a main/sub place polygon, because Nominatim returns an arbitrary point on the line.'
L '4. No coordinates are typed in by hand. Rows that cannot be resolved keep lat/lon = null.'
L ''
L 'Confidence: **high** = census main/sub place centroid, or Nominatim name match inside the census place/municipality; **medium** = Nominatim result with ambiguity (partial name match, other same-name candidates > 5 km away, outside census place, only province known, roads/rivers used as reference), or census centroid > 1 km outside its own concave polygon; **low** = only a municipality/district/province centroid. `geocode_flag = "check"` = final point > 30 km from expected municipality.'
L ''
L '## Counts (rows)'
L ''
L '| method | high | medium | low | null | total |'
L '|---|---|---|---|---|---|'
foreach ($m in @('census_place_centroid', 'nominatim', $null)) {
    $sub = @($all | Where-Object { $_.geocode_method -eq $m })
    $label = $m; if ($null -eq $m) { $label = '(not geocoded)' }
    L ("| {0} | {1} | {2} | {3} | {4} | {5} |" -f $label, @($sub | ? { $_.geocode_confidence -eq 'high' }).Count, @($sub | ? { $_.geocode_confidence -eq 'medium' }).Count, @($sub | ? { $_.geocode_confidence -eq 'low' }).Count, @($sub | ? { $null -eq $_.geocode_confidence }).Count, $sub.Count)
}
L ("| **total** | {0} | {1} | {2} | {3} | {4} |" -f @($all | ? { $_.geocode_confidence -eq 'high' }).Count, @($all | ? { $_.geocode_confidence -eq 'medium' }).Count, @($all | ? { $_.geocode_confidence -eq 'low' }).Count, @($all | ? { $null -eq $_.geocode_confidence }).Count, $all.Count)
L ''
L "Rows flagged ``check``: $(@($all | ? { $_.geocode_flag -eq 'check' }).Count)"
L ''
L '## Low-confidence, check-flagged and null rows'
L ''
L '| row | event_id | place | method | conf | flag | match | note |'
L '|---|---|---|---|---|---|---|---|'
for ($i = 0; $i -lt $all.Count; $i++) {
    $a = $all[$i]
    if ($a.geocode_confidence -eq 'low' -or $a.geocode_flag -eq 'check' -or $null -eq $a.lat) {
        $pl = $a.place; if ($pl.Length -gt 70) { $pl = $pl.Substring(0, 70) + '...' }
        L ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |" -f $i, $a.event_id, ($pl -replace '\|', '/'), $a.geocode_method, $a.geocode_confidence, $a.geocode_flag, ($a.geocode_match -replace '\|', '-'), ($a.geocode_note -replace '\|', ';'))
    }
}
L ''
L '## Medium-confidence rows'
L ''
L '| row | place | method | match | note |'
L '|---|---|---|---|---|'
for ($i = 0; $i -lt $all.Count; $i++) {
    $a = $all[$i]
    if ($a.geocode_confidence -eq 'medium') {
        $pl = $a.place; if ($pl.Length -gt 70) { $pl = $pl.Substring(0, 70) + '...' }
        L ("| {0} | {1} | {2} | {3} | {4} |" -f $i, ($pl -replace '\|', '/'), $a.geocode_method, ($a.geocode_match -replace '\|', '-'), ($a.geocode_note -replace '\|', ';'))
    }
}
L ''
L '## How to re-run'
L ''
L '```powershell'
L '# from any directory (paths are resolved relative to the script folder)'
L 'powershell -ExecutionPolicy Bypass -File .\last-mile\methods\scripts\geocode_sites.ps1'
L '# cache only, no network:'
L 'powershell -ExecutionPolicy Bypass -File .\last-mile\methods\scripts\geocode_sites.ps1 -Offline'
L '# refetch everything from census2011.adrianfrith.com and Nominatim:'
L 'powershell -ExecutionPolicy Bypass -File .\last-mile\methods\scripts\geocode_sites.ps1 -Refresh'
L '```'
L ''
L 'With the cache present the run is deterministic (geocoded_at = retrieval time of the cached source). OSM data changes over time, so `-Refresh` can give slightly different Nominatim results. Nominatim usage policy: https://operations.osmfoundation.org/policies/nominatim/ . Census boundaries: Stats SA Census 2011 via census2011.adrianfrith.com.'
Write-Utf8NoBom $LogPath $sb.ToString()
Write-Host "Wrote $LogPath"
