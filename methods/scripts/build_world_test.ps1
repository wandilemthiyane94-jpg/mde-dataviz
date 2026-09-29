# World relocation test: does governance structure predict outcomes, once we don't pick cases by outcome?
# Inputs : data/world_relocation_sample.csv (64 random cases), data/raw/world_coding_batch{1..4}.json (coded per codebook),
#          data/raw/wb_country_covariates.csv (World Bank income group + WGI government effectiveness 2022)
# Outputs: data/world_relocation_coded.csv, data/world_relocation_test.csv (factor x outcome tables),
#          data/raw/world_geocode_cache.json, prototype/story/world-test-data.js
# Tests  : 2x2 tables, risk difference, two-sided Fisher exact p; repeated within income strata.
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$inv = [Globalization.CultureInfo]::InvariantCulture
$sample = Import-Csv "$root\data\world_relocation_sample.csv" -Encoding UTF8
$wb = Import-Csv "$root\data\raw\wb_country_covariates.csv" -Encoding UTF8
$alias = @{ 'Vietnam' = 'Viet Nam'; 'Laos' = 'Lao PDR'; 'South Korea' = 'Korea, Rep.'; 'Russia' = 'Russian Federation'; 'Iran' = 'Iran, Islamic Rep.'; 'Egypt' = 'Egypt, Arab Rep.'; 'Venezuela' = 'Venezuela, RB'; 'Bolivia' = 'Bolivia'; 'Micronesia' = 'Micronesia, Fed. Sts.'; 'Federated States of Micronesia' = 'Micronesia, Fed. Sts.'; 'Gambia' = 'Gambia, The'; 'Congo' = 'Congo, Rep.'; 'DRC' = 'Congo, Dem. Rep.'; 'Democratic Republic of the Congo' = 'Congo, Dem. Rep.'; 'Turkey' = 'Turkiye'; 'USA' = 'United States'; 'United States of America' = 'United States'; 'UK' = 'United Kingdom'; 'Yemen' = 'Yemen, Rep.'; 'Kyrgyzstan' = 'Kyrgyz Republic'; 'Slovakia' = 'Slovak Republic'; 'Ivory Coast' = "Cote d'Ivoire"; "Côte d'Ivoire" = "Cote d'Ivoire"; 'Taiwan' = 'Taiwan, China' }
function WB($country) { $n = if ($alias.ContainsKey($country)) { $alias[$country] } else { $country }; $wb | Where-Object { $_.country -eq $n } | Select-Object -First 1 }

# ---- load coding ----
$coded = @{}
foreach ($b in 1..4) { $f = "$root\data\raw\world_coding_batch$b.json"; if (-not (Test-Path $f)) { Write-Warning "missing $f"; continue }
  $j = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json; foreach ($c in $j.cases) { $coded[[int]$c.sample_no] = $c } }
function Code($c, $v) { if ($null -eq $c -or $null -eq $c.$v) { return 'unknown' }; $x = $c.$v; if ($x -is [string]) { return $x }; if ($x.code) { return [string]$x.code }; 'unknown' }

# ---- geocode (Nominatim, cached) ----
$gcFile = "$root\data\raw\world_geocode_cache.json"; $gc = @{}
if (Test-Path $gcFile) { (Get-Content $gcFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $gc[$_.Name] = $_.Value } }
function Geo($q) { if ($gc.ContainsKey($q)) { return $gc[$q] }
  try { Start-Sleep -Milliseconds 1100; $r = Invoke-RestMethod ("https://nominatim.openstreetmap.org/search?format=json&limit=1&q=" + [uri]::EscapeDataString($q)) -Headers @{ 'User-Agent' = 'last-mile-research/1.0 (Harvard GSD student project)' } -TimeoutSec 30
    $v = if ($r -and $r[0]) { @{ lat = [double]$r[0].lat; lon = [double]$r[0].lon } } else { $null } } catch { $v = $null }
  $gc[$q] = $v; return $v }

$rows = foreach ($s in $sample) { $c = $coded[[int]$s.sample_no]; $w = WB $s.country
  $g = Geo "$($s.place_origin), $($s.province_state), $($s.country)"; $prec = 'place'
  if (-not $g) { $g = Geo "$($s.province_state), $($s.country)"; $prec = 'province' }
  if (-not $g) { $g = Geo "$($s.country)"; $prec = 'country' }
  [pscustomobject][ordered]@{
    sample_no = [int]$s.sample_no; id = $s.id; region = $s.region; country = $s.country; place_origin = $s.place_origin; place_destination = $s.place_destination; hazard = $s.hazard; hazard_original = $s.hazard_original
    income_group = $(if ($w) { $w.income_group } else { 'unknown' }); wgi_gov_eff = $(if ($w -and $w.gov_effectiveness_wgi) { $w.gov_effectiveness_wgi } else { '' })
    coded = [bool]$c; year_start = (Code $c 'year_start'); trigger = (Code $c 'trigger')
    lead = (Code $c 'lead'); single_owner = (Code $c 'single_owner'); resident_site_choice = (Code $c 'resident_site_choice'); tenure_destination = (Code $c 'tenure_destination')
    hazard_binding = (Code $c 'hazard_binding'); funding = (Code $c 'funding'); distance = (Code $c 'distance')
    hazard_at_destination = (Code $c 'hazard_at_destination'); return_to_origin = (Code $c 'return_to_origin'); livelihoods = (Code $c 'livelihoods'); overall = (Code $c 'overall')
    lat = $(if ($g) { $g.lat } else { '' }); lon = $(if ($g) { $g.lon } else { '' }); geo_precision = $(if ($g) { $prec } else { 'none' })
    sources = $(if ($c -and $c.sources) { @($c.sources) -join ' ' } else { '' }) } }
$rows | Export-Csv "$root\data\world_relocation_coded.csv" -NoTypeInformation -Encoding UTF8
($gc | ConvertTo-Json -Depth 4) | Out-File $gcFile -Encoding utf8

# ---- tests ----
function LF($n) { $s = 0.0; for ($i = 2; $i -le $n; $i++) { $s += [math]::Log($i) }; $s }
function Fisher($a, $b, $c, $d) { $r1 = $a + $b; $r2 = $c + $d; $c1 = $a + $c; $n = $r1 + $r2
  $pObs = [math]::Exp((LF $r1) + (LF $r2) + (LF $c1) + (LF ($n - $c1)) - (LF $n) - (LF $a) - (LF $b) - (LF $c) - (LF $d)); $p = 0.0
  for ($x = [math]::Max(0, $c1 - $r2); $x -le [math]::Min($r1, $c1); $x++) { $pa = [math]::Exp((LF $r1) + (LF $r2) + (LF $c1) + (LF ($n - $c1)) - (LF $n) - (LF $x) - (LF ($r1 - $x)) - (LF ($c1 - $x)) - (LF ($r2 - $c1 + $x))); if ($pa -le $pObs * 1.0000001) { $p += $pa } }
  [math]::Min([double]1.0, [double]$p) }
$factors = [ordered]@{
  'single_owner = yes'                      = { param($r) if ($r.single_owner -eq 'unknown') { $null } else { $r.single_owner -eq 'yes' } }
  'clear lead body (single_owner yes/partial)' = { param($r) if ($r.single_owner -eq 'unknown') { $null } else { $r.single_owner -in 'yes', 'partial' } }
  'government top-down'                     = { param($r) if ($r.lead -eq 'unknown') { $null } else { $r.lead -eq 'gov_topdown' } }
  'residents chose site (yes/partial)'      = { param($r) if ($r.resident_site_choice -eq 'unknown') { $null } else { $r.resident_site_choice -in 'yes', 'partial' } }
  'community led or joint'                  = { param($r) if ($r.lead -eq 'unknown') { $null } else { $r.lead -in 'gov_community_joint', 'community_initiated' } }
  'secure tenure at destination'            = { param($r) if ($r.tenure_destination -eq 'unknown') { $null } else { $r.tenure_destination -eq 'secure' } }
  'hazard assessment binding (yes/partial)' = { param($r) if ($r.hazard_binding -eq 'unknown') { $null } else { $r.hazard_binding -in 'yes', 'partial' } }
  'standing programme funding'              = { param($r) if ($r.funding -eq 'unknown') { $null } else { $r.funding -eq 'standing_programme' } }
  'higher-income country (UMIC/HIC)'        = { param($r) if ($r.income_group -eq 'unknown') { $null } else { $r.income_group -in 'High income', 'Upper middle income' } }
  'above-median government effectiveness'   = { param($r) if ($r.wgi_gov_eff -eq '') { $null } else { [double]::Parse($r.wgi_gov_eff, $inv) -gt $script:wgiMed } }
}
$wv = @($rows | Where-Object { $_.wgi_gov_eff -ne '' } | ForEach-Object { [double]::Parse($_.wgi_gov_eff, $inv) } | Sort-Object); $script:wgiMed = if ($wv.Count) { $wv[[int]($wv.Count / 2)] } else { 0 }
$outcomes = [ordered]@{
  'new site hit / exposed' = { param($r) if ($r.hazard_at_destination -eq 'unknown') { $null } else { $r.hazard_at_destination -eq 'exposed_or_hit' } }
  'judged failure or mixed' = { param($r) if ($r.overall -eq 'unknown') { $null } else { $r.overall -in 'failure', 'mixed' } }
  'people returned (some/many)' = { param($r) if ($r.return_to_origin -eq 'unknown') { $null } else { $r.return_to_origin -in 'some', 'many' } }
}
function Tab($set, $fk, $ok, $stratum) { $a = $b = $c = $d = 0
  foreach ($r in $set) { $fv = & $factors[$fk] $r; $ov = & $outcomes[$ok] $r; if ($null -eq $fv -or $null -eq $ov) { continue }
    if ($fv -and $ov) { $a++ } elseif ($fv) { $b++ } elseif ($ov) { $c++ } else { $d++ } }
  $n1 = $a + $b; $n0 = $c + $d
  [pscustomobject][ordered]@{ stratum = $stratum; factor = $fk; outcome = $ok; n = $n1 + $n0; with_factor_n = $n1; with_factor_bad_pct = $(if ($n1) { [math]::Round(100 * $a / $n1) } else { '' }); without_factor_n = $n0; without_factor_bad_pct = $(if ($n0) { [math]::Round(100 * $c / $n0) } else { '' })
    risk_difference_pts = $(if ($n1 -and $n0) { [math]::Round(100 * ($a / $n1 - $c / $n0)) } else { '' }); fisher_p = $(if ($n1 -and $n0) { [math]::Round((Fisher $a $b $c $d), 3) } else { '' }); a = $a; b = $b; c = $c; d = $d } }
$codedRows = @($rows | Where-Object coded)
$res = foreach ($ok in $outcomes.Keys) { foreach ($fk in $factors.Keys) { Tab $codedRows $fk $ok 'all' } }
$res += foreach ($st in @(@('lower-income (LIC/LMIC)', { param($r) $r.income_group -in 'Low income', 'Lower middle income' }), @('higher-income (UMIC/HIC)', { param($r) $r.income_group -in 'Upper middle income', 'High income' }))) {
  $sub = @($codedRows | Where-Object { & $st[1] $_ }); foreach ($fk in @($factors.Keys)[0..5]) { Tab $sub $fk 'new site hit / exposed' $st[0]; Tab $sub $fk 'judged failure or mixed' $st[0] } }
$res | Export-Csv "$root\data\world_relocation_test.csv" -NoTypeInformation -Encoding UTF8
$js = "window.WORLDTEST=" + (@{ cases = @($rows); tests = @($res); wgi_median = $script:wgiMed; built = (Get-Date -Format 'yyyy-MM-dd') } | ConvertTo-Json -Depth 5 -Compress) + ";"
[IO.File]::WriteAllText("$root\prototype\story\world-test-data.js", $js, (New-Object Text.UTF8Encoding($false)))
"coded: $($codedRows.Count) of $(@($rows).Count); geocoded: $(@($rows | Where-Object lat).Count); WGI median: $script:wgiMed"
$res | Where-Object stratum -eq 'all' | Format-Table factor, outcome, n, with_factor_n, with_factor_bad_pct, without_factor_n, without_factor_bad_pct, risk_difference_pts, fisher_p -AutoSize | Out-String -Width 220
