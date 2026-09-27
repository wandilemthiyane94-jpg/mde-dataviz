# Scores 11 relocation cases on structural factors to test what separates relocation INTO flood risk from relocation OUT of it.
# Evidence: data/raw/relocation_deep_sa_baseline.json, relocation_deep_does.json, relocation_deep_doesnt.json
# Output: data/relocation_rootcause_matrix.csv
# Codes are our reading of each case's variable findings: Y = present, N = absent, P = partial, nf = not found in sources.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
foreach ($f in 'relocation_deep_sa_baseline', 'relocation_deep_does', 'relocation_deep_doesnt') { $null = Get-Content "$root\data\raw\$f.json" -Raw -Encoding UTF8 | ConvertFrom-Json }

$factors = 'F1_site_is_cheapest_or_leftover_land', 'F2_hazard_info_binding_in_siting', 'F3_residents_co_decide_site', 'F4_permanent_tenure_at_move',
           'F5_one_body_owns_land_and_outcome', 'F6_emergency_or_temporary_route', 'F7_corruption_or_conflict_documented', 'F8_court_forced_action',
           'F9_livelihood_planned', 'F10_blame_shifted_after_flood'
# case = outcome | F1..F10
$cases = [ordered]@{
  'ZA eThekwini TEAs (baseline)' = 'into_risk|Y|N|N|N|N|Y|Y|N|N|Y'
  'PH Kasiglahan'                = 'into_risk|Y|N|N|N|N|N|P|N|N|Y'
  'IN Chennai resettlement'      = 'into_risk|Y|N|N|P|N|P|P|N|N|Y'
  'HT Corail/Canaan'             = 'into_risk|Y|N|N|N|N|Y|Y|N|N|Y'
  'MZ Lower Zambezi'             = 'livelihood_fail|P|P|N|P|N|N|nf|N|N|Y'
  'SO Beledweyne'                = 'into_risk|nf|N|N|N|N|Y|nf|N|N|Y'
  'AU Grantham'                  = 'safe|N|Y|P|Y|Y|P|nf|N|N|N'
  'NL Overdiepse polder'         = 'safe|N|Y|Y|Y|Y|N|nf|N|Y|N'
  'CO Gramalote'                 = 'safe|N|Y|Y|Y|Y|N|nf|N|N|N'
  'JP Iwanuma'                   = 'safe|N|Y|Y|Y|Y|P|nf|N|P|N'
  'FJ Vunidogoloa'               = 'safe|N|Y|Y|Y|P|N|nf|N|P|N'
}
$rows = foreach ($k in $cases.Keys) { $v = $cases[$k].Split('|'); $r = [ordered]@{ case = $k; outcome = $v[0] }
  for ($i = 0; $i -lt $factors.Count; $i++) { $r[$factors[$i]] = $v[$i + 1] }; [pscustomobject]$r }
$rows | Export-Csv "$root\data\relocation_rootcause_matrix.csv" -NoTypeInformation -Encoding UTF8

# How well does each factor separate the two groups? (share coded Y in failures vs in successes; P counts as half)
function Score($grp, $f) { $vals = @($grp | ForEach-Object { $_.$f } | Where-Object { $_ -ne 'nf' }); if (-not $vals.Count) { return 'nf' }
  $s = ($vals | ForEach-Object { if ($_ -eq 'Y') { 1 } elseif ($_ -eq 'P') { 0.5 } else { 0 } } | Measure-Object -Sum).Sum; '{0:P0} (n={1})' -f ($s / $vals.Count), $vals.Count }
$fail = @($rows | Where-Object outcome -ne 'safe'); $ok = @($rows | Where-Object outcome -eq 'safe')
foreach ($f in $factors) { '{0,-40} failures {1,-12} successes {2}' -f $f, (Score $fail $f), (Score $ok $f) }
