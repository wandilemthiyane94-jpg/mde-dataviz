$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # last-mile/
$ErrorActionPreference = 'Stop'
$sp = $root
$out = "$root\data"
function Load($p) { Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json }
$mp = Load "$root\data\raw\media_patterns_coded.json"
$master = Load "$out\floods_2016_2026.json"; $byId = @{}; foreach ($e in $master) { $byId[$e.id] = $e }
$ds = Load "$out\death_site_language.json"; $dsById = @{}; foreach ($d in $ds) { $dsById[$d.id] = $d }

$metros = 'eThekwini|Durban|Cape Town|Johannesburg|Tshwane|Pretoria|Ekurhuleni|Nelson Mandela Bay|Gqeberha|Buffalo City|East London|Mangaung'
$rows = foreach ($c in $mp.events) {
  $e = $byId[$c.id]; $d = $dsById[$c.id]
  $deaths = if ($e.deaths -ne $null) { [double]$e.deaths } elseif ($e.deaths_text -match '(\d+)') { [double]$matches[1] } else { 0 }
  $txt = (@($e.municipalities) + @($e.named_places) + $e.event) -join ' '
  $sites = @(); if ($d) { $sites = @($d.death_sites) }
  $siteTxt = ($sites | ForEach-Object { "$($_.place) $($_.settlement_type) $($_.deaths_note)" }) -join ' '
  $allTxt = "$siteTxt $($e.deaths_text) $($e.notes) $($e.settlement_type_mentioned)"
  $inf = @($sites | Where-Object { "$($_.settlement_type) $($_.place)" -match 'informal|shack|squatter' }).Count
  [pscustomobject]@{
    id = $c.id; year = $e.year; deaths = $deaths
    scale = if ($deaths -ge 20) { 'mass (20+)' } elseif ($deaths -ge 5) { 'mid (5-19)' } else { 'small (1-4)' }
    provinces = (@($e.provinces) -join '/'); n_prov = @($e.provinces).Count
    metro = [bool]($txt -match $metros)
    declared = $e.disaster_declared
    death_sites_n = $sites.Count; death_sites_informal = $inf
    informal_death_site = if ($sites.Count) { $inf -gt 0 } else { $null }
    mech_vehicle = [bool]($allTxt -match 'vehicle|car |cars|taxi|bus|bridge|causeway|driv|motorist|bakkie|low-level|crossing')
    mech_collapse = [bool]($allTxt -match 'collaps|wall|mudslide|landslide|house fell|roof')
    mech_electro = [bool]($allTxt -match 'electrocut')
    mech_lightning = [bool]($allTxt -match 'lightning')
    settlement_mentioned = $e.settlement_type_mentioned
    P1 = $c.P1.value; P2 = $c.P2.value; P2_type = $c.P2.mention_type
    P3 = $c.P3.value; P3_who = $c.P3.who; P3b = $c.P3.other_visit.value; P3b_who = $c.P3.other_visit.who
    P4 = $c.P4.value; off = $c.P4.officials_quoted; res = $c.P4.residents_quoted
    P5 = $c.P5.value; P5_ev = $c.P5.evidence; P5_note = $c.P5.note; P5_url = $c.P5.url
    P2_ev = $c.P2.evidence; P2_note = $c.P2.note
    P3_ev = $c.P3.evidence; P3_note = $c.P3.note
  }
}
[IO.File]::WriteAllText("$root\data\raw\pattern_join.json", (ConvertTo-Json -InputObject @($rows) -Depth 4), (New-Object Text.UTF8Encoding($false)))
$rows | Sort-Object year | Format-Table id, deaths, scale, metro, declared, informal_death_site, mech_vehicle, mech_collapse, P2_type, P3_who, P3b_who, P5 -AutoSize | Out-String -Width 250
