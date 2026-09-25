# fetch_observing_network.ps1
# Builds data\observing_network.json: South Africa's weather / hydrological observing
# network (radars, surface stations, river gauges, lightning sensors) plus the
# weather satellites that view the country.
#
# Windows PowerShell 5.1. No Python/Node. Raw downloads are saved to
#   data\raw\observing_network\
# Run:            powershell -ExecutionPolicy Bypass -File fetch_observing_network.ps1
# Rebuild only:   powershell -ExecutionPolicy Bypass -File fetch_observing_network.ps1 -Offline
#   (-Offline re-uses the raw files already on disk and makes no web requests)
#
# Sources (all public, no login):
#   WMO Radar Database (WRD)        https://wrd.mgm.gov.tr/Radar/List  (POST Radar/Search)
#   WMO OSCAR/Surface station list  https://oscar.wmo.int/surface/rest/api/search/station?territoryName=ZAF
#   NOAA NCEI ISD station history   https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv
#   WMO OSCAR/Space satellite pages https://space.oscar.wmo.int/satellites/view/<id>
#   EUMETSAT Meteosat series page   https://www.eumetsat.int/our-satellites/meteosat-series
#   DWS real-time flow page (Wayback snapshot, Vaal WMA only)
# Counts that have no machine-readable source (SAWS AWS / lightning sensor totals) are
# taken from the SAWS EW4All Roadmap 2025-2029 as already cited in
# data\forecasting_infrastructure.json.

param([switch]$Offline)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # ...\last-mile
$rawDir  = Join-Path $root 'data\raw\observing_network'
$outFile = Join-Path $root 'data\observing_network.json'
New-Item -ItemType Directory -Force $rawDir | Out-Null

$RETRIEVED = (Get-Date).ToString('yyyy-MM-dd')
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

# South Africa bounding box used as a sanity filter (task spec)
$LATMIN = -35.5; $LATMAX = -22.0; $LONMIN = 16.0; $LONMAX = 33.5
function In-SA($lat, $lon) {
    if ($null -eq $lat -or $null -eq $lon) { return $false }
    $a = [double]$lat; $o = [double]$lon
    return ($a -ge $LATMIN -and $a -le $LATMAX -and $o -ge $LONMIN -and $o -le $LONMAX)
}
function Km($lat1, $lon1, $lat2, $lon2) {
    $r = 6371.0; $d = [Math]::PI / 180
    $dl = ($lat2 - $lat1) * $d; $dn = ($lon2 - $lon1) * $d
    $h = [Math]::Sin($dl/2)*[Math]::Sin($dl/2) + [Math]::Cos($lat1*$d)*[Math]::Cos($lat2*$d)*[Math]::Sin($dn/2)*[Math]::Sin($dn/2)
    return [Math]::Round(2 * $r * [Math]::Asin([Math]::Sqrt($h)), 1)
}
function Get-Raw($url, $file) {
    $path = Join-Path $rawDir $file
    if (-not $Offline) {
        Write-Host "GET $url"
        Invoke-WebRequest $url -UseBasicParsing -UserAgent $UA -TimeoutSec 180 -OutFile $path
    }
    if (-not (Test-Path $path)) { throw "Missing raw file $path (run without -Offline)" }
    return $path
}
function Read-Text($path) { return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) }
function Strip-Html($html) {
    $t = $html -replace '<script[\s\S]*?</script>','' -replace '<style[\s\S]*?</style>',''
    $t = $t -replace '<[^>]+>','|' -replace '&nbsp;',' ' -replace '&deg;','deg' -replace '&amp;','&' -replace '&ge;','>=' -replace '&quot;','"'
    return ($t -replace '\s+',' ' -replace '(\| ?)+','|')
}

# ---------------------------------------------------------------- 1. WMO Radar Database
$wrdFile = Join-Path $rawDir 'wrd_radars_search_southafrica.json'
if (-not $Offline) {
    Write-Host 'GET WMO Radar Database (search "South Africa")'
    $page = Invoke-WebRequest 'https://wrd.mgm.gov.tr/Radar/List' -UseBasicParsing -UserAgent $UA -SessionVariable wrd -TimeoutSec 120
    $tn = [regex]::Match($page.Content,'name="csrf-token-name" content="([^"]+)"').Groups[1].Value
    $th = [regex]::Match($page.Content,'name="csrf-hash" content="([^"]+)"').Groups[1].Value
    $body = @{ draw='1'; start='0'; length='500'; 'search[value]'='South Africa'; 'search[regex]'='false';
               INSTALL_YEAR_MIN='1900'; INSTALL_YEAR_MAX='2100'; 'order[0][column]'='1'; 'order[0][dir]'='asc' }
    if ($tn) { $body[$tn] = $th }
    $cols = 'WSI','RADAR_NAME','COUNTRY_NAME','BAND','TX_TYPE','RX_TYPE','POLARIZATION','CONTINENT_NAME','REGION_ID','INSTALL_DATE'
    for ($k = 0; $k -lt $cols.Count; $k++) {
        $body["columns[$k][data]"] = $cols[$k]; $body["columns[$k][searchable]"] = 'true'
        $body["columns[$k][orderable]"] = 'true'; $body["columns[$k][search][value]"] = ''
    }
    $resp = Invoke-WebRequest 'https://wrd.mgm.gov.tr/Radar/Search' -Method Post -Body $body -WebSession $wrd -UseBasicParsing -UserAgent $UA `
            -Headers @{ 'X-Requested-With'='XMLHttpRequest'; 'Referer'='https://wrd.mgm.gov.tr/Radar/List' } -TimeoutSec 120
    [IO.File]::WriteAllText($wrdFile, $resp.Content, (New-Object Text.UTF8Encoding $false))
}
$wrd = ((Read-Text $wrdFile) | ConvertFrom-Json).data | Where-Object { $_.COUNTRY_NAME -eq 'South Africa' }

# ---------------------------------------------------------------- 2. OSCAR/Surface list
$oscarFile = Get-Raw 'https://oscar.wmo.int/surface/rest/api/search/station?territoryName=ZAF' 'oscar_zaf_stations.json'
$oscar = ((Read-Text $oscarFile) | ConvertFrom-Json).stationSearchResults

# ---------------------------------------------------------------- 3. NOAA ISD history
$isdFile = Get-Raw 'https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv' 'isd-history.csv'
$isdAll = Import-Csv $isdFile
$isdMaxEnd = ($isdAll | Measure-Object -Property END -Maximum).Maximum
$isdSF = $isdAll | Where-Object { $_.CTRY -eq 'SF' -and $_.LAT -ne '' -and (In-SA $_.LAT $_.LON) }
$isdByWmo = @{}
foreach ($r in $isdSF) { if ($r.USAF -match '^(68\d{3})0$') { $w = $matches[1]; if (-not $isdByWmo.ContainsKey($w) -or $r.END -gt $isdByWmo[$w].END) { $isdByWmo[$w] = $r } } }

# ---------------------------------------------------------------- 4. DWS real-time snapshot (context only)
$dwsSnap = 'dws_unverified_vaal_wayback_20230601.html'
$dwsPath = Join-Path $rawDir $dwsSnap
if (-not $Offline) {
    try { Get-Raw 'http://web.archive.org/web/20230601021928/https://www.dws.gov.za/Hydrology/Unverified/UnverifiedDataFlowInfo.aspx' $dwsSnap | Out-Null }
    catch { Write-Warning "Wayback DWS snapshot not fetched: $($_.Exception.Message)" }
}
$dwsRows = @()
if (Test-Path $dwsPath) {
    $t = (Read-Text $dwsPath) -replace '<script[\s\S]*?</script>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '\s+',' '
    $dwsRows = [regex]::Matches($t,'\b([A-X]\d[HR]\d{3})\b (.*?)(?= [A-X]\d[HR]\d{3}\b|$)') | ForEach-Object {
        [pscustomobject]@{ code = $_.Groups[1].Value; nodata = ($_.Groups[2].Value -match 'no data') } }
}

# ---------------------------------------------------------------- 5. Satellite pages
$satIds = 'meteosat_12','meteosat_10','meteosat_11','meteosat_9_iodc','mtg_s1','mtg_i2','fy_2h',
          'metop_b','metop_c','noaa_20','noaa_21','snpp','fy_3d','fy_3e','fy_3f','meteor_m_n2_3','meteor_m_n2_4'
$sat = @{}
foreach ($s in $satIds) {
    $p = Get-Raw "https://space.oscar.wmo.int/satellites/view/$s" "oscar_space_$s.html"
    $t = Strip-Html (Read-Text $p)
    $instr = ''
    $m = [regex]::Match($t, '\|All known Instruments flying on [^|]+\|Acronym\|Full name\|(.*?)\|Show instrument status')
    if ($m.Success) {
        $parts = $m.Groups[1].Value.Split('|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -ne ',' }
        $acr = @(); for ($i = 0; $i -lt $parts.Count; $i += 2) { $acr += $parts[$i] }
        $instr = ($acr -join ', ')
    }
    $sat[$s] = [ordered]@{
        status = [regex]::Match($t,'\|Status\|([^|]+)\|').Groups[1].Value.Trim()
        lon    = [regex]::Match($t,'\|Longitude\|([^|]+)\|').Groups[1].Value.Trim()
        ect    = [regex]::Match($t,'\|ECT\|([^|]+)\|').Groups[1].Value.Trim()
        alt    = [regex]::Match($t,'\|Altitude\|([^|]+)\|').Groups[1].Value.Trim()
        instr  = $instr
        url    = "https://space.oscar.wmo.int/satellites/view/$s"
    }
}
try { Get-Raw 'https://www.eumetsat.int/our-satellites/meteosat-series' 'eumetsat_meteosat_series.html' | Out-Null }
catch { Write-Warning "EUMETSAT page not fetched: $($_.Exception.Message)" }

# ================================================================ BUILD LAYERS
$layers = @()

# ---- Radars ------------------------------------------------------------------
$oscarRadar = $oscar | Where-Object { $_.name -like 'RADAR *' }
$radarPts = @(); $radarNoCoord = @()
foreach ($r in ($wrd | Sort-Object RADAR_NAME)) {
    $lat = [double]$r.RADAR_LAT; $lon = [double]$r.RADAR_LON
    $note = ''; $coordSrc = 'WMO Radar Database'
    # explicit WRD name -> OSCAR/Surface dedicated radar record name
    $map = @{ 'Bloemfontein'='RADAR Bloemfontein'; 'Cape town'='RADAR Cape town'; 'Durban'='RADAR Durban';
              'Mthatha'='RADAR Mthatha'; 'O.R Tambo Int. Airport'='RADAR Ort'; 'Port Elizaberth'='RADAR Port Elizabeth' }
    $osc = $null
    if ($map.ContainsKey($r.RADAR_NAME)) { $osc = $oscarRadar | Where-Object { $_.name -eq $map[$r.RADAR_NAME] } | Select-Object -First 1 }
    if (-not (In-SA $lat $lon)) {
        # WRD coordinates invalid (e.g. OR Tambo stored as 25N 54E). Fall back to OSCAR record if one exists.
        if ($osc) {
            $note = "WRD coordinates ($($r.RADAR_LAT), $($r.RADAR_LON)) are outside South Africa and treated as an error; position taken from OSCAR/Surface record '$($osc.name)' ($($osc.wigosId), declared $($osc.declaredStatus); these are the same coordinates as the OR Tambo airport synoptic station 68368)."
            $lat = [double]$osc.latitude; $lon = [double]$osc.longitude; $coordSrc = 'WMO OSCAR/Surface'
        } else { $radarNoCoord += $r.RADAR_NAME; continue }
    } elseif ($osc) {
        $d = Km $lat $lon ([double]$osc.latitude) ([double]$osc.longitude)
        $note = "OSCAR/Surface record '$($osc.name)' ($($osc.wigosId)) lies $d km from the WRD position."
    }
    $pol = switch ($r.POLARIZATION) { 'D' {'dual-pol'} 'S' {'single-pol'} default {$r.POLARIZATION} }
    $radarPts += [ordered]@{
        name = ($r.RADAR_NAME -replace 'Elizaberth','Elizabeth' -replace '^Cape town$','Cape Town' -replace '^De aar$','De Aar' -replace '^East london$','East London')
        lat = [Math]::Round($lat, 5); lon = [Math]::Round($lon, 5)
        type = "$($r.BAND)-band weather radar ($pol)"
        status = $r.STATUS_NAME
        id = $r.WSI
        band = $r.BAND
        manufacturer = $r.MANUFACTURER_NAME
        elevation_m = $r.ELEVATION
        wrd_last_update = $r.LAST_UPDATE
        coord_source = $coordSrc
        note = $note
    }
}
$opCount = @($radarPts | Where-Object { $_.status -eq 'Operational' }).Count
$layers += [ordered]@{
    id = 'radars'
    label = 'SAWS weather radars'
    count_total = $radarPts.Count + $radarNoCoord.Count + 1   # +1 = Venetia Mine (see notes)
    count_with_coords = $radarPts.Count
    count_operational_per_wrd = $opCount
    source = [ordered]@{ title = 'WMO Radar Database (WRD), search "South Africa"'; url = 'https://wrd.mgm.gov.tr/Radar/List'; accessed = $RETRIEVED }
    cross_check_source = [ordered]@{ title = 'WMO OSCAR/Surface, territory ZAF (RADAR records and stations with WRO affiliation)'; url = 'https://oscar.wmo.int/surface/rest/api/search/station?territoryName=ZAF'; accessed = $RETRIEVED }
    notes = "WRD lists $($wrd.Count) SAWS radars: $opCount 'Operational', the rest 'Closed'. Operational entries were last updated in WRD in Jan 2020; the Closed flags were set in Mar 2026. SAWS's EW4All Roadmap 2025-2029 gives 11 radar systems (10 S-band, 1 C-band). WRD has $opCount operational (9 S-band + Cape Town C-band), so the 11th is probably Venetia Mine (Limpopo), which is on SAWS's 2024/25 Tier-1 list but is in neither WRD nor OSCAR. No coordinates were found for Venetia Mine, so it is counted in count_total but not plotted. Status is WRD's declared status, not live uptime: SAWS reported Tier-1 radar data availability of 44-80% in 2020-2025, and the Durban radar was being decommissioned for replacement from 15 Sep 2026 (see data/forecasting_infrastructure.json). WRD calls Bethlehem dual-pol, Irene single-pol (EEC) and Cape Town C-band dual-pol. These attributes come from WRD as published and may not match Becker (2014) Table 2-1. Unplotted: " + ((@($radarNoCoord) + 'Venetia Mine (not in WRD/OSCAR)') -join '; ')
    points = $radarPts
}

# ---- Surface stations (SAWS synoptic/AWS registered in OSCAR, WMO block 68) ---
$surf = $oscar | Where-Object { $_.stationTypeName -eq 'Land (fixed)' -and $_.wigosId -match '^0-(20000|710)-0-68\d{3}$' -and (In-SA $_.latitude $_.longitude) }
$surfPts = @()
foreach ($s in ($surf | Sort-Object name)) {
    $wmo = ($s.wigosId -split '-')[-1]
    $isd = $isdByWmo[$wmo]
    $surfPts += [ordered]@{
        name = $s.name; lat = [double]$s.latitude; lon = [double]$s.longitude
        type = 'surface land station (synoptic/AWS, WMO-registered)'
        status = $s.declaredStatus
        id = $s.wigosId
        wmo_index = $wmo
        programmes = $s.stationProgramsDeclaredStatuses
        isd_last_obs = $(if ($isd) { $isd.END } else { $null })
    }
}
$surfOp = @($surfPts | Where-Object { $_.status -eq 'Operational' }).Count
$isdMatched = @($surfPts | Where-Object { $_.isd_last_obs }).Count
$isd2025 = @($isdSF | Where-Object { $_.END -ge '20250101' }).Count
$excludedLand = @($oscar | Where-Object { $_.stationTypeName -eq 'Land (fixed)' -and $_.stationProgramsDeclaredStatuses -notmatch 'WHYCOS' -and $_.wigosId -notmatch '^0-(20000|710)-0-68\d{3}$' }).Count
$layers += [ordered]@{
    id = 'surface_stations'
    label = 'Surface weather stations (WMO-registered, mainly SAWS)'
    count_total = $surfPts.Count
    count_with_coords = $surfPts.Count
    count_declared_operational = $surfOp
    source = [ordered]@{ title = 'WMO OSCAR/Surface station search, territory ZAF'; url = 'https://oscar.wmo.int/surface/rest/api/search/station?territoryName=ZAF'; accessed = $RETRIEVED }
    cross_check_source = [ordered]@{ title = 'NOAA NCEI Integrated Surface Database station history (CTRY = SF)'; url = 'https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv'; accessed = $RETRIEVED }
    notes = "Includes OSCAR land stations with a WMO block-68 index (WIGOS 0-20000-0-68xxx or 0-710-0-68xxx) inside the SA bounding box, so Marion Island and SANAE are excluded. $surfOp of these are declared Operational. Status is OSCAR's declared status, not measured reporting. Excluded: $excludedLand other non-hydrological land records (the RADAR records, and GAW/INDAAF/BSRN research sites such as Cape Point, Irene, De Aar, Springbok, Amersfoort, Skukuza and Louis Trichardt). Ships and Argo floats are also excluded. This is only the WMO-registered part of SAWS's network. The EW4All Roadmap 2025-2029 reports 265 automatic weather stations and 156 automatic rainfall stations, but SAWS does not publish coordinates for the full set. Cross-check: NOAA ISD lists $($isdSF.Count) South African (SF) stations inside the bounding box, $isd2025 of them with data in 2025. The ISD history file ends $isdMaxEnd, so 2026 reporting cannot be checked from it. $isdMatched of the OSCAR stations match an ISD record by WMO index, and isd_last_obs gives that record's END date."
    points = $surfPts
}

# ---- River gauges (DWS, OSCAR WHYCOS, H-coded) --------------------------------
$why = $oscar | Where-Object { $_.stationProgramsDeclaredStatuses -match 'WHYCOS' }
$gauges = $why | Where-Object { $_.name -match '^[A-X]\d[H]\d{3}$' -and (In-SA $_.latitude $_.longitude) }
$gOut = @($why | Where-Object { $_.name -match '^[A-X]\d[H]\d{3}$' -and -not (In-SA $_.latitude $_.longitude) }).Count
$nGw = @($why | Where-Object { $_.name -match '^[A-X]\d[N]\d{4}$' }).Count
$nR  = @($why | Where-Object { $_.name -match '^[A-X]\d[R]\d{3}$' }).Count
$nL  = @($why | Where-Object { $_.name -match '^[A-X]\d[L]\d{3}$' }).Count
$gPts = @()
foreach ($g in ($gauges | Sort-Object name)) {
    $gPts += [ordered]@{ name = $g.name; lat = [double]$g.latitude; lon = [double]$g.longitude
        type = 'DWS river flow-gauging station'; status = $g.declaredStatus; id = $g.wigosId
        drainage_region = $g.name.Substring(0,1); established = $(if ($g.dateEstablished) { $g.dateEstablished.Substring(0,10) } else { $null }) }
}
$gOp = @($gPts | Where-Object { $_.status -eq 'Operational' }).Count
$dwsH = @($dwsRows | Where-Object { $_.code -match 'H' }).Count
$dwsR = @($dwsRows | Where-Object { $_.code -match 'R' }).Count
$dwsNo = @($dwsRows | Where-Object { $_.nodata }).Count
$layers += [ordered]@{
    id = 'river_gauges'
    label = 'DWS river flow-gauging stations'
    count_total = $gPts.Count
    count_with_coords = $gPts.Count
    count_declared_operational = $gOp
    source = [ordered]@{ title = 'WMO OSCAR/Surface station search, territory ZAF (WHYCOS stations registered by the Department of Water and Sanitation)'; url = 'https://oscar.wmo.int/surface/rest/api/search/station?territoryName=ZAF'; accessed = $RETRIEVED }
    notes = "DWS has registered $($why.Count) hydrological stations in OSCAR under WHYCOS. Plotted here: the $($gPts.Count) whose DWS code has H as the third character (e.g. A2H012), which are river flow-gauging stations. The type comes from the DWS code letter: DWS real-time pages list H stations as river 'Stage/Flow' and R stations as dams ('Blue row indicates station is a dam'), and DWS names its KMZ layers H_his 'River hydrological data' and R_his 'Dam hydrological data'. Not plotted: $nGw N-coded groundwater monitoring sites (OSCAR/WMDR observed variable 'Groundwater level', code 166, checked on A1N0001), $nR R-coded reservoir and $nL L-coded station(s). $gOut H-coded station(s) fall outside the bounding box. $gOp are declared Operational. OSCAR's assessed status is 'Unknown' for these stations, so how many report today is not known. This is fewer than the whole network: Wessels & Rooseboom (2009, Water SA 35(1)) report flow gauged at 782 positions by end-2007, with 780-880 operational gauging stations since 1975. The DWS Hydrology site (dws.gov.za/Hydrology) returned HTTP 403 to scripted requests on $RETRIEVED, so the DWS catalogue could not be downloaded. Real-time reporting sample: a Wayback copy (1 Jun 2023) of the DWS near-real-time page for the Vaal WMA only lists $($dwsRows.Count) stations ($dwsH H, $dwsR R), of which $dwsNo showed 'no data'. Other WMAs sit behind ASP.NET postbacks and were not archived. GRDC was not used because its catalogue needs the interactive portal."
    points = $gPts
}

# ---- Lightning ---------------------------------------------------------------
$layers += [ordered]@{
    id = 'lightning_sensors'
    label = 'South African Lightning Detection Network (SAWS, Vaisala)'
    count_total = 26
    count_with_coords = 0
    source = [ordered]@{ title = 'SAWS, Early Warning for All (EW4ALL) Initiative: Roadmap for South Africa 2025-2029 ("26 Lightning Detection Network Sensors")'; url = 'http://web.archive.org/web/20260426183623/https://www.weathersa.co.za/Documents/Corporate/ROADMAP_BOOKLET_FINAL_WEB_VERSION.pdf'; accessed = '2026-09-25' }
    notes = 'Sensor locations are not published. Earlier counts: 19 sensors at installation in 2005-06 (Gijben 2012, S Afr J Sci 108), 24 (Mahomed et al. 2021, S Afr J Sci), 25 (Enno & Gijben 2021, EUMETSAT). Count only; no points.'
    points = @()
}

# ================================================================ SATELLITES
$becker = 'Becker 2014, UKZN MSc (Irene QPE): "The SAWS also has access to Meteosat Second Generation (MSG) data." https://afriwx.co.za/resources/weather-documents/APPLICATION-OF-A-QUANTITATIVE-PRECIPITATION-ESTIMATION-ALGORITHM-FOR-THE-S-BAND-RADAR-AT-IRENE-SOUTH-AFRICA.pdf'
$msgRx = "yes, MSG series in general ($becker). Which MSG satellite is not stated."
$nd = 'not documented'
$eum = 'https://www.eumetsat.int/our-satellites/meteosat-series'
function SatRow($id, $name, $orbit, $pos, $op, $sees, $rx, $extra) {
    $s = $sat[$id]
    $src = "WMO OSCAR/Space $($s.url) (status: $($s.status); accessed $RETRIEVED)"
    if ($extra) { $src += "; $extra" }
    $w = $sees
    if ($s.instr) { $w += " Instruments (OSCAR/Space): $($s.instr)." }
    $pos = ($pos -replace 'deg\s*','' -replace '^(\d+(\.\d+)?)$','$1E' -replace '^(\d+(\.\d+)?) ([EW])','$1$3')
    return [ordered]@{ name = $name; orbit = $orbit; position = $pos; operator = $op; what_it_sees = $w; saws_receives = $rx; source = $src; oscar_status = $s.status }
}
function Pol($id) { $e = $sat[$id].ect; if ($e) { return "sun-synchronous, ~$($sat[$id].alt), equator crossing $e" } else { return 'sun-synchronous' } }

$sats = @(
  (SatRow 'meteosat_12' 'Meteosat-12 (MTG-I1)' 'geostationary' "$($sat['meteosat_12'].lon) (nominal 0.0E)" 'EUMETSAT' 'Prime 0-degree satellite. Full-disc imagery of Europe, Africa and surrounding seas every 10 minutes (FCI). The Lightning Imager maps lightning over the whole disc, South Africa included.' "$nd (SAWS-specific). EUMETSAT states Meteosat-12 data are disseminated to national meteorological services." "EUMETSAT $eum ('primary operational satellite at 0 degrees providing full disc imagery every 10 minutes')"),
  (SatRow 'meteosat_10' 'Meteosat-10 (MSG-3)' 'geostationary' $sat['meteosat_10'].lon 'EUMETSAT' 'SEVIRI full-disc imagery (MSG full disc every 15 min). Running in parallel with Meteosat-12 until Q2 2027, then backup.' $msgRx $null),
  (SatRow 'meteosat_11' 'Meteosat-11 (MSG-4)' 'geostationary' $sat['meteosat_11'].lon 'EUMETSAT' 'Rapid-scan service every 5 minutes over Europe and North Africa only (this does not cover South Africa). Also the full-disc backup.' $msgRx "EUMETSAT $eum ('provides imagery every 5 minutes over Europe and North Africa')"),
  (SatRow 'meteosat_9_iodc' 'Meteosat-9 (Indian Ocean Data Coverage)' 'geostationary' $sat['meteosat_9_iodc'].lon 'EUMETSAT' 'SEVIRI full disc centred on 45.5E over the Indian Ocean, operating until 2027. Its disc includes southern Africa: Pretoria is about 3,470 km (about 31 degrees of arc) from the sub-satellite point, computed by great-circle distance.' $msgRx "EUMETSAT $eum ('provides imagery over the Indian Ocean. Operating until 2027')"),
  (SatRow 'mtg_s1' 'MTG-S1 (to become Meteosat-13)' 'geostationary' $sat['mtg_s1'].lon 'EUMETSAT' 'Infrared sounder for vertical temperature and humidity profiles; still commissioning. Its UVN instrument (Sentinel-4) covers Europe only.' $nd "EUMETSAT $eum"),
  (SatRow 'mtg_i2' 'MTG-I2 (to become Meteosat-14)' 'geostationary' $sat['mtg_i2'].lon 'EUMETSAT' 'Second MTG imager, launched 27 Aug 2026 and commissioning. Not yet operational.' $nd "EUMETSAT $eum"),
  (SatRow 'fy_2h' 'FY-2H' 'geostationary' $sat['fy_2h'].lon 'CMA (China)' 'Geostationary imager at 79E. South Africa lies near the western edge of its view (Pretoria is about 6,430 km (about 58 degrees of arc) from the sub-satellite point, computed by great-circle distance). OSCAR notes "Only Limited access".' $nd $null),
  (SatRow 'metop_b' 'Metop-B' 'polar' (Pol 'metop_b') 'EUMETSAT' 'Mid-morning polar orbiter. It images a wide strip on each pass (AVHRR) and measures temperature/humidity soundings (IASI, AMSU-A, MHS) and ocean-surface winds (ASCAT).' $nd $null),
  (SatRow 'metop_c' 'Metop-C' 'polar' (Pol 'metop_c') 'EUMETSAT' 'Same instruments as Metop-B, flying in the same mid-morning orbit about half an orbit apart.' $nd $null),
  (SatRow 'noaa_21' 'NOAA-21 (JPSS-2)' 'polar' (Pol 'noaa_21') 'NOAA / NASA' 'Primary afternoon polar orbiter. VIIRS imagery (including a day/night low-light band) plus ATMS/CrIS temperature/humidity soundings.' $nd $null),
  (SatRow 'noaa_20' 'NOAA-20 (JPSS-1)' 'polar' (Pol 'noaa_20') 'NOAA / NASA' 'Secondary afternoon orbiter. Same payload as NOAA-21.' $nd $null),
  (SatRow 'snpp' 'Suomi-NPP' 'polar' (Pol 'snpp') 'NOAA / NASA' 'Tertiary afternoon orbiter with the VIIRS/ATMS/CrIS payload. OSCAR expected end of life: Nov 2026.' $nd $null),
  (SatRow 'fy_3d' 'FY-3D' 'polar' (Pol 'fy_3d') 'CMA (China)' 'Afternoon polar orbiter carrying an imager (MERSI-II) and microwave/infrared sounders.' $nd $null),
  (SatRow 'fy_3e' 'FY-3E' 'polar' (Pol 'fy_3e') 'CMA (China)' 'Early-morning-orbit polar orbiter with sounders and imager. It fills the dawn gap between Metop and JPSS.' $nd $null),
  (SatRow 'fy_3f' 'FY-3F' 'polar' (Pol 'fy_3f') 'CMA (China)' 'Morning polar orbiter with imager and sounders. OSCAR notes that MWRI-2 has failed.' $nd $null),
  (SatRow 'meteor_m_n2_3' 'Meteor-M N2-3' 'polar' (Pol 'meteor_m_n2_3') 'Roshydromet / Roscosmos' 'Russian polar orbiter with imager and sounders. OSCAR notes that global data are not transmitted because the X-band link failed.' $nd $null),
  (SatRow 'meteor_m_n2_4' 'Meteor-M N2-4' 'polar' (Pol 'meteor_m_n2_4') 'Roshydromet / Roscosmos' 'Russian polar orbiter with imager and sounders.' $nd $null)
)

# ================================================================ COVERAGE NOTES
$coverage = @(
  [ordered]@{ instrument = 'SAWS S-band / C-band weather radar'; what_it_can_see = 'Rain and hail inside a circle around each radar. SAWS network maps draw range rings at 200 km and 300 km, and 200 km is the usual working limit for rain estimates. The beam rises with distance, so low cloud and light rain far from a radar are missed, and mountains block parts of the beam. Each point in this layer is the centre of one such circle.'; source = 'Becker 2014 UKZN MSc (network map with 200 km and 300 km range rings; wording taken from a search-index extract, check against the PDF): https://afriwx.co.za/resources/weather-documents/APPLICATION-OF-A-QUANTITATIVE-PRECIPITATION-ESTIMATION-ALGORITHM-FOR-THE-S-BAND-RADAR-AT-IRENE-SOUTH-AFRICA.pdf' },
  [ordered]@{ instrument = 'Surface weather station (synoptic / AWS)'; what_it_can_see = 'Only the air at that one spot: temperature, humidity, wind, pressure and rain in a gauge about 20 cm wide. Anything between stations has to be interpolated.'; source = 'WMO OSCAR/Surface station metadata (observed variables per station): https://oscar.wmo.int/surface' },
  [ordered]@{ instrument = 'DWS river flow-gauging station'; what_it_can_see = 'Water level (stage) and derived flow at one river cross-section. It shows a flood passing that point, not where the rain fell.'; source = 'DWS near-real-time flow page (Stage (m), Flow columns), Wayback 1 Jun 2023: http://web.archive.org/web/20230601021928/https://www.dws.gov.za/Hydrology/Unverified/UnverifiedDataFlowInfo.aspx' },
  [ordered]@{ instrument = 'SA Lightning Detection Network'; what_it_can_see = 'Cloud-to-ground lightning across most of the country. Predicted flash detection efficiency is 90% with 0.5 km median location accuracy (Gijben 2012). Measured over Johannesburg: 84.9% flash detection efficiency (Fensham et al. 2023).'; source = 'Gijben 2012, S Afr J Sci 108(3/4): https://scielo.org.za/scielo.php?script=sci_arttext&pid=S0038-23532012000200013 ; Fensham et al. 2023, Electric Power Systems Research: https://doi.org/10.1016/j.epsr.2022.108968' },
  [ordered]@{ instrument = 'Geostationary imager (Meteosat-12 FCI)'; what_it_can_see = 'The whole of Africa and Europe in one view, every 10 minutes, from 36,000 km up: cloud tops, storm growth, and lightning (Lightning Imager). It sees clouds, not the rain reaching the ground.'; source = "EUMETSAT $eum ; WMO OSCAR/Space https://space.oscar.wmo.int/satellites/view/meteosat_12" },
  [ordered]@{ instrument = 'Geostationary imager (MSG SEVIRI: Meteosat-9/10/11)'; what_it_can_see = 'Full disc every 15 minutes (5-minute rapid scan over Europe and North Africa only). This is the MSG data SAWS is documented to have access to.'; source = "EUMETSAT $eum ; Becker 2014 (SAWS access to MSG)" },
  [ordered]@{ instrument = 'Polar-orbiting satellites (Metop, JPSS, FY-3, Meteor-M)'; what_it_can_see = 'Sharper images and vertical temperature/humidity profiles along a strip a few thousand km wide. A sun-synchronous satellite crosses a given place at roughly the same local times, about twice a day (one day pass, one night pass; the times follow from the equator-crossing times in the satellites list). So these are snapshots, not a continuous watch. A direct-readout (AHRPT) station receives Metop data out to about 1,500 km.'; source = 'WMO OSCAR/Space satellite pages (orbit, equator-crossing times); EUMETSAT Metop direct dissemination https://www.eumetsat.int/direct-dissemination (AHRPT local coverage radius up to 1,500 km; wording taken from a search-index extract)' }
)

# ================================================================ WRITE
$out = [ordered]@{
    retrieved = $RETRIEVED
    description = 'South Africa weather and hydrological observing network with coordinates, for the "points of light" visualisation. Built by methods/scripts/fetch_observing_network.ps1. See methods/observing_network_log.md.'
    bbox_filter = [ordered]@{ lat = @($LATMIN, $LATMAX); lon = @($LONMIN, $LONMAX) }
    layers = $layers
    satellites = $sats
    coverage_notes = $coverage
}
$json = $out | ConvertTo-Json -Depth 10
[IO.File]::WriteAllText($outFile, $json, (New-Object Text.UTF8Encoding $false))
Write-Host "Wrote $outFile"
foreach ($l in $layers) { Write-Host ("{0}: total {1}, with coords {2}" -f $l.id, $l.count_total, $l.count_with_coords) }
Write-Host "satellites: $($sats.Count)"
