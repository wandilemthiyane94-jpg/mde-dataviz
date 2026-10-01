# One table of all 84 temporary relocation sites: who was moved there, and every source.
# Inputs : the compiled site list South_Africa_TRAs_2022-2026.xlsx (sheet "Existing TRAs": status, size, Source 1/2;
#          sheet "Closed, planned & context"), copied into data/raw/ by this script;
#          data/tra_sites_exposure.csv (our coding: origin = why people were moved, floodplain band, reflooding evidence).
# Outputs: data/tra_sites_full.csv, data/tra_sites_context.csv, prototype/story/tra-sources-data.js
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$xlsx = "$root\data\raw\South_Africa_TRAs_2022-2026.xlsx"
$dl = "$env:USERPROFILE\Downloads\South_Africa_TRAs_2022-2026.xlsx"
if (-not (Test-Path $xlsx) -and (Test-Path $dl)) { Copy-Item $dl $xlsx }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead($xlsx)
function Read-Entry($n) { $e = $z.GetEntry($n); $s = New-Object IO.StreamReader($e.Open()); $t = $s.ReadToEnd(); $s.Close(); $t }
$wb = [xml](Read-Entry 'xl/workbook.xml'); $rels = [xml](Read-Entry 'xl/_rels/workbook.xml.rels'); $ss = [xml](Read-Entry 'xl/sharedStrings.xml')
$str = @($ss.sst.si | ForEach-Object { if ($_.t -is [string]) { $_.t } elseif ($_.t.'#text') { $_.t.'#text' } else { ($_.r | ForEach-Object { if ($_.t -is [string]) { $_.t } else { $_.t.'#text' } }) -join '' } })
function Col($ref) { $l = ($ref -replace '\d', ''); $n = 0; foreach ($ch in $l.ToCharArray()) { $n = $n * 26 + ([int]$ch - 64) }; $n - 1 }
function Sheet($name) {
  $sh = $wb.workbook.sheets.sheet | Where-Object name -eq $name
  $rid = $sh.GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
  $target = ($rels.Relationships.Relationship | Where-Object Id -eq $rid).Target
  $x = [xml](Read-Entry ('xl/' + $target.TrimStart('/').Replace('xl/', '')))
  $grid = foreach ($r in $x.worksheet.sheetData.row) { $vals = @{}
    foreach ($c in $r.c) { $v = $c.v; $vals[(Col $c.r)] = if ($c.t -eq 's') { $str[[int]$v] } elseif ($c.t -eq 'inlineStr') { $c.is.t } else { $v } }
    , $vals }
  $grid }
$ex = @(Sheet 'Existing TRAs'); $hdr = $ex[0]; $cols = 0..(($hdr.Keys | Measure-Object -Maximum).Maximum) | ForEach-Object { $hdr[$_] }
$list = foreach ($row in $ex[1..($ex.Count - 1)]) { $o = [ordered]@{}; for ($i = 0; $i -lt $cols.Count; $i++) { $o[$cols[$i]] = [string]$row[$i] }; [pscustomobject]$o }
$ctxRows = @(Sheet 'Closed, planned & context'); $ch = $ctxRows[0]; $ccols = 0..(($ch.Keys | Measure-Object -Maximum).Maximum) | ForEach-Object { $ch[$_] }
$ctx = foreach ($row in $ctxRows[1..($ctxRows.Count - 1)]) { $o = [ordered]@{}; for ($i = 0; $i -lt $ccols.Count; $i++) { $o[$ccols[$i]] = [string]$row[$i] }; [pscustomobject]$o }
$z.Dispose()

$ours = @{}; Import-Csv "$root\data\tra_sites_exposure.csv" -Encoding UTF8 | ForEach-Object { $ours[$_.id] = $_ }
$who = @{ flood = 'Flood survivors'; covid = 'Covid-19 de-densification'; clearance = 'Cleared for a housing or infrastructure project'; eviction = 'Evicted'
  fire = 'Fire survivors'; upgrading = 'Decanted for in-situ upgrading'; densification = 'De-densification of an informal settlement'; other = 'Other'; unknown = 'Not stated in sources' }
$fpLabel = @{ inside = 'inside floodplain'; within_250m = 'within 250 m'; within_1km = 'within 1 km'; beyond_1km = 'beyond 1 km' }
$full = foreach ($s in $list) { $id = $s.'#'; $o = $ours[$id]
  [pscustomobject][ordered]@{
    id = $id; province = $s.Province; municipality = $s.Municipality; site = $s.'Site name / aliases'; type = $s.Type; suburb_landmark = $s.'Suburb / landmark'
    lat = $s.'Approx. latitude'; lon = $s.'Approx. longitude'; coord_confidence = $s.'Coordinate confidence'; established = $s.Established; size = $s.'Size (households / units)'
    status = $s.Status; status_detail = $s.'Status detail (latest source)'; latest_source_date = $s.'Latest source date'; source_1 = $s.'Source 1'; source_2 = $s.'Source 2'
    who_was_moved = $(if ($o) { $who[$o.origin] } else { '' }); who_basis = $(if ($o) { $o.origin_basis } else { '' })
    ethekwini_floodplain = $(if ($o -and $o.ethekwini_floodplain) { $fpLabel[$o.ethekwini_floodplain] } else { '' })
    reflood_documented = $(if ($o) { $o.reflood_documented } else { '' }); reflood_evidence = $(if ($o) { $o.reflood_basis } else { '' }) } }
$full | Export-Csv "$root\data\tra_sites_full.csv" -NoTypeInformation -Encoding UTF8
$ctx | Export-Csv "$root\data\tra_sites_context.csv" -NoTypeInformation -Encoding UTF8
$js = 'window.TRASRC=' + (@{ sites = @($full); context = @($ctx); built = (Get-Date -Format 'yyyy-MM-dd') } | ConvertTo-Json -Depth 4 -Compress) + ';'
[IO.File]::WriteAllText("$root\prototype\story\tra-sources-data.js", $js, (New-Object Text.UTF8Encoding($false)))
"sites $(@($full).Count) (with source 1: $(@($full | Where-Object source_1).Count), source 2: $(@($full | Where-Object source_2).Count))  context $(@($ctx).Count)"
$full | Group-Object who_was_moved | Sort-Object Count -Descending | ForEach-Object { "  $($_.Name): $($_.Count)" }
