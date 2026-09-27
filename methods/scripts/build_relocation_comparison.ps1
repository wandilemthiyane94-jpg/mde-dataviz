# Builds the "relocated into a flood zone" comparison: eThekwini's Lamontville camp against the Africa and world cases.
# Inputs: data/raw/relocation_into_floodzones_africa.json, data/raw/relocation_into_floodzones_world.json
# Output: data/relocation_cases.csv (one row per case, with the evidence fields plus the comparison codes below)
# The codes are our reading of each case's evidence fields (risk_known_before, temporary_vs_permanent, blame_framing,
# warning_at_site, accountability_outcome). nf = not found in the sources. in_counts=no marks a case that is only an
# assessment (ZA-KZN-04) or only alleged and not yet carried out (ZA-GP-01).
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$cases = foreach ($f in 'relocation_into_floodzones_africa', 'relocation_into_floodzones_world') {
  (Get-Content "$root\data\raw\$f.json" -Raw -Encoding UTF8 | ConvertFrom-Json).cases | ForEach-Object { $_ } }

# id = risk_known | announced_temporary | stayed_over_1yr | blame | warning_reached | accountability | deaths_at_site | in_counts
$code = @{
  'ZA-KZN-01'  = 'yes|yes|yes|weather|nf|none|5|yes'
  'ZA-KZN-02'  = 'partly|yes|yes|residents|nf|none|nf|yes'
  'ZA-KZN-03'  = 'nf|yes|yes|nf|nf|none|2|yes'
  'ZA-KZN-04'  = 'yes|yes|nf|nf|nf|audit|nf|no'
  'ZA-GP-01'   = 'alleged|nf|nf|nf|nf|none|nf|no'
  'MZ-01'      = 'nf|no|yes|nf|nf|none|nf|yes'
  'ZW-01'      = 'nf|yes|yes|deflect|nf|none|nf|yes'
  'NG-01'      = 'nf|yes|yes|nf|nf|none|nf|yes'
  'SS-01'      = 'yes|yes|yes|deflect|nf|none|nf|yes'
  'SD-01'      = 'nf|yes|nf|nf|nf|none|nf|yes'
  'IND-CHN-01' = 'partly|no|yes|nf|nf|none|nf|yes'
  'IND-CHN-02' = 'nf|no|yes|nf|no|none|12|yes'
  'HTI-01'     = 'yes|yes|yes|deflect|partial|none|nf|yes'
  'BGD-01'     = 'yes|yes|yes|deflect|nf|none|nf|yes'
  'BGD-02'     = 'yes|yes|yes|weather|nf|none|12|yes'
  'BGD-03'     = 'yes|no|yes|weather|nf|none|nf|yes'
  'PHL-01'     = 'yes|no|yes|deflect|no|none|nf|yes'
  'PHL-02'     = 'nf|no|yes|nf|nf|none|nf|yes'
  'USA-01'     = 'yes|no|yes|deflect|nf|lawsuit|nf|yes'
  'AFG-01'     = 'nf|yes|nf|weather|nf|none|nf|yes'
  'IDN-01'     = 'nf|nf|nf|residents|nf|none|nf|yes'
  'PAK-01'     = 'nf|yes|yes|nf|nf|none|nf|yes'
  'LKA-01'     = 'partly|no|yes|nf|nf|none|nf|yes'
  'IDN-02'     = 'partly|yes|yes|deflect|nf|none|nf|yes'
}
$rows = foreach ($c in $cases) {
  if (-not $code.ContainsKey($c.id)) { throw "no code for $($c.id)" }
  $k = $code[$c.id].Split('|')
  [pscustomobject][ordered]@{
    id = $c.id; place = $c.place; country = $c.country; relocation_year = "$($c.relocation_year)"; flooded_years = "$(@($c.flooded_years) -join '; ')"
    agency = $c.agency; confidence = $c.confidence; in_counts = $k[7]
    risk_known = $k[0]; announced_temporary = $k[1]; stayed_over_1yr = $k[2]; blame = $k[3]; warning_reached = $k[4]; accountability = $k[5]; deaths_at_site = $k[6]
    who_was_moved = "$($c.who_was_moved)"; distance_or_position = "$($c.distance_or_position)"; risk_known_before = "$($c.risk_known_before)"
    temporary_vs_permanent = "$($c.temporary_vs_permanent)"; blame_framing = "$($c.blame_framing)"; warning_at_site = "$($c.warning_at_site)"
    resident_voice = "$($c.resident_voice)"; accountability_outcome = "$($c.accountability_outcome)"; urls = (@($c.urls) -join ' ')
  }
}
$rows | Export-Csv "$root\data\relocation_cases.csv" -NoTypeInformation -Encoding UTF8

$n = @($rows | Where-Object in_counts -eq 'yes'); $t = @($n | Where-Object announced_temporary -eq 'yes')
"cases: $(@($rows).Count)  counted: $($n.Count)"
"risk on record before (yes/partly): $(@($n | Where-Object { $_.risk_known -in 'yes','partly' }).Count)"
"announced temporary: $($t.Count)  of which stayed >1yr: $(@($t | Where-Object stayed_over_1yr -eq 'yes').Count)"
"blame: " + (($n | Group-Object blame | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' ')
"warning confirmed reaching residents: $(@($n | Where-Object warning_reached -eq 'yes').Count)  explicitly not: $(@($n | Where-Object warning_reached -eq 'no').Count)"
"accountability: " + (($n | Group-Object accountability | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' ')
"deaths documented at site: " + (($n | Where-Object deaths_at_site -ne 'nf' | ForEach-Object { "$($_.id)=$($_.deaths_at_site)" }) -join ' ')
