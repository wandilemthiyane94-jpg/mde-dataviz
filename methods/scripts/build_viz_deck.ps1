# Builds the editable sketch data-viz deck (PowerPoint via COM; needs Microsoft PowerPoint on Windows).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sp = $env:TEMP; $r = 'C:\Users\Wandile\OneDrive\last-mile'
$out = 'C:\Users\Wandile\Desktop\Who_Owns_the_Flood_Submission\Who_Owns_the_Flood_DataViz_Deck.pptx'
$inv = [Globalization.CultureInfo]::InvariantCulture
$ARW = [string][char]0x2192; $DOTC = [string][char]0x00B7; $TIMES = [string][char]0x00D7; $DASH = [string][char]0x2014; $Q1 = [string][char]0x201C; $Q2 = [string][char]0x201D; $CK = [string][char]0x2713
function RGB3($r, $g, $b) { $r + $g * 256 + $b * 65536 }
$COL = @{ ink = (RGB3 34 34 34); grey = (RGB3 140 140 140); light = (RGB3 205 205 205); faint = (RGB3 232 232 230); red = (RGB3 208 49 45); pink = (RGB3 244 182 182); blue = (RGB3 111 168 207); paleblue = (RGB3 220 230 236); paper = (RGB3 250 250 247); white = (RGB3 255 255 255) }
$rnd = New-Object System.Random 7
function J($a) { ($rnd.NextDouble() - 0.5) * $a }
$script:sl = $null

# ---------- drawing helpers (all native, editable shapes) ----------
function SLine($pts, $col, $w = 1.5, $dash = 1, $jit = 1.2, [switch]$arrow, [switch]$closed) {
  $p = @($pts); if ($closed) { $p += , $p[0] }
  $dense = New-Object System.Collections.Generic.List[object]
  for ($i = 0; $i -lt $p.Count - 1; $i++) { $a = $p[$i]; $b = $p[$i + 1]; $len = [math]::Sqrt(($b[0] - $a[0]) * ($b[0] - $a[0]) + ($b[1] - $a[1]) * ($b[1] - $a[1])); $n = [math]::Max(1, [math]::Min(8, [int]($len / 40)))
    for ($k = 0; $k -lt $n; $k++) { $t = $k / $n; $dense.Add(@(($a[0] + ($b[0] - $a[0]) * $t + (J $jit)), ($a[1] + ($b[1] - $a[1]) * $t + (J $jit)))) } }
  $last = $p[$p.Count - 1]; $dense.Add(@(($last[0] + (J $jit)), ($last[1] + (J $jit))))
  $bf = $script:sl.Shapes.BuildFreeform(0, [single]$dense[0][0], [single]$dense[0][1])
  for ($i = 1; $i -lt $dense.Count; $i++) { $bf.AddNodes(0, 0, [single]$dense[$i][0], [single]$dense[$i][1]) }
  $s = $bf.ConvertToShape(); $s.Fill.Visible = 0; $s.Line.ForeColor.RGB = [int]$col; $s.Line.Weight = [single]$w; $s.Line.DashStyle = $dash
  if ($arrow) { $s.Line.EndArrowheadStyle = 2 }; return $s }
function Poly($pts, $fillCol, $lineCol = $null, $trans = 0) {
  $bf = $script:sl.Shapes.BuildFreeform(0, [single]$pts[0][0], [single]$pts[0][1])
  for ($i = 1; $i -lt $pts.Count; $i++) { $bf.AddNodes(0, 0, [single]$pts[$i][0], [single]$pts[$i][1]) }; $bf.AddNodes(0, 0, [single]$pts[0][0], [single]$pts[0][1])
  $s = $bf.ConvertToShape(); $s.Fill.Visible = -1; $s.Fill.Solid(); $s.Fill.ForeColor.RGB = [int]$fillCol; $s.Fill.Transparency = [single]$trans
  if ($lineCol -ne $null) { $s.Line.ForeColor.RGB = [int]$lineCol; $s.Line.Weight = 0.5 } else { $s.Line.Visible = 0 }; return $s }
function Hatch($pts, $lc) { $s = Poly $pts $COL.pink $lc 0.25; $s.Line.ForeColor.RGB = [int]$lc; $s.Line.Weight = 1.2; $s.Line.DashStyle = 4; return $s }
function SBox($x, $y, $w, $h, $col, $lw = 1.5, $fill = $null, $dash = 1) { $x = [double]$x; $y = [double]$y; $w = [double]$w; $h = [double]$h
  if ($fill -ne $null) { $b = $script:sl.Shapes.AddShape(1, [single]$x, [single]$y, [single]$w, [single]$h); $b.Line.Visible = 0; $b.Fill.ForeColor.RGB = [int]$fill }
  SLine @(@($x, $y), @(($x + $w), $y), @(($x + $w), ($y + $h)), @($x, ($y + $h))) $col $lw $dash 1.4 -closed | Out-Null }
function Txt($x, $y, $w, $h, $text, $size = 12, $col = $COL.ink, $font = 'Ink Free', $bold = 0, $align = 1) {
  $t = $script:sl.Shapes.AddTextbox(1, [single]$x, [single]$y, [single]$w, [single]$h); $t.TextFrame.WordWrap = -1; $t.TextFrame.MarginLeft = 0; $t.TextFrame.MarginRight = 0; $t.TextFrame.MarginTop = 0; $t.TextFrame.MarginBottom = 0
  $tr = $t.TextFrame.TextRange; $tr.Text = [string]$text; $tr.Font.Name = [string]$font; $tr.Font.Size = [single]$size; $tr.Font.Color.RGB = [int]$col; $tr.Font.Bold = [int]$bold; $tr.ParagraphFormat.Alignment = [int]$align; return $t }
function Dot($x, $y, $rad, $col, $lineCol = $null) { $o = $script:sl.Shapes.AddShape(9, ($x - $rad), ($y - $rad), (2 * $rad), (2 * $rad)); $o.Fill.ForeColor.RGB = [int]$col; if ($lineCol -ne $null) { $o.Line.ForeColor.RGB = [int]$lineCol; $o.Line.Weight = 1 } else { $o.Line.Visible = 0 }; return $o }
function Ring($x, $y, $rad, $col, $w = 1.5, $dash = 1) { $o = $script:sl.Shapes.AddShape(9, ($x - $rad), ($y - $rad), (2 * $rad), (2 * $rad)); $o.Fill.Visible = 0; $o.Line.ForeColor.RGB = [int]$col; $o.Line.Weight = [single]$w; $o.Line.DashStyle = $dash; return $o }
function Squig($x, $y, $w, $amp, $col, $lw = 2.5) { $pts = @(); for ($i = 0; $i -le 12; $i++) { $pts += , @(($x + $w * $i / 12), ($y + [math]::Sin($i * 1.1) * $amp)) }; SLine $pts $col $lw 1 1.5 | Out-Null }
function NewSlide($idx) { $s = $script:pres.Slides.Add($idx, 12); $s.FollowMasterBackground = 0; $s.Background.Fill.Solid(); $s.Background.Fill.ForeColor.RGB = [int]$COL.paper; $script:sl = $s; return $s }
function Header($kicker, $title, $page) {
  Txt 36 22 520 14 $kicker 9 $COL.grey 'Consolas' | Out-Null
  Txt 36 38 620 34 $title 26 $COL.red 'Bahnschrift' 1 | Out-Null
  Txt 640 22 284 14 "Hollie & Wandile $DOTC Harvard GSD MDE" 8 $COL.grey 'Consolas' 0 3 | Out-Null
  if ($page) { Txt 880 510 44 14 $page 8 $COL.grey 'Consolas' 0 3 | Out-Null } }
function Progress($n) { for ($i = 1; $i -le 7; $i++) { $x = 640 + ($i - 1) * 22; if ($i -eq $n) { Dot $x 508 5 $COL.red | Out-Null } else { Ring $x 508 4 $COL.grey 1 | Out-Null } }; Txt 640 518 200 12 'frame 1 2 3 4 5 6 7' 7 $COL.grey 'Consolas' | Out-Null }
function SideText($num, $narr, $inter, $q) {
  Txt 650 92 270 60 $num 44 $COL.light 'Bahnschrift' 1 | Out-Null
  Txt 650 150 270 90 $narr 14 $COL.ink 'Segoe UI' | Out-Null
  if ($inter) { Txt 650 262 270 14 'INTERACTION' 8 $COL.grey 'Consolas' | Out-Null; Txt 650 278 270 80 $inter 13 $COL.ink 'Ink Free' | Out-Null }
  if ($q) { Txt 650 380 270 80 $q 18 $COL.red 'Ink Free' 1 | Out-Null } }
# schematic Durban map; returns site positions
$SITEPOS = @(@(.22, .30), @(.35, .24), @(.44, .42), @(.26, .58), @(.40, .68), @(.52, .55), @(.58, .28), @(.16, .46), @(.48, .80), @(.62, .66), @(.30, .44), @(.55, .40))
function MapSketch($x, $y, $w, $h, [switch]$flood, [switch]$sites, [switch]$hits, [switch]$dim) {
  SBox $x $y $w $h $COL.light 1 $COL.white
  SLine @(@(($x + $w * .80), ($y + 4)), @(($x + $w * .74), ($y + $h * .35)), @(($x + $w * .86), ($y + $h * .62)), @(($x + $w * .70), ($y + $h - 4))) $COL.grey 3 1 2 | Out-Null
  Txt ($x + $w * .84) ($y + $h * .40) 60 14 'Indian Ocean' 9 $COL.grey 'Ink Free' | Out-Null
  Squig ($x + 12) ($y + $h * .33) ($w * .62) 10 $COL.blue 2.5; Squig ($x + 20) ($y + $h * .62) ($w * .55) 9 $COL.blue 2.5
  SLine @(@(($x + $w * .30), ($y + $h * .34)), @(($x + $w * .27), ($y + $h * .50)), @(($x + $w * .33), ($y + $h * .60))) $COL.blue 1.5 | Out-Null
  if ($flood) { Hatch @(@(($x + $w * .12), ($y + $h * .30)), @(($x + $w * .30), ($y + $h * .22)), @(($x + $w * .46), ($y + $h * .30)), @(($x + $w * .38), ($y + $h * .42)), @(($x + $w * .18), ($y + $h * .40))) $COL.red | Out-Null
    Hatch @(@(($x + $w * .28), ($y + $h * .58)), @(($x + $w * .46), ($y + $h * .54)), @(($x + $w * .60), ($y + $h * .62)), @(($x + $w * .50), ($y + $h * .74)), @(($x + $w * .32), ($y + $h * .70))) $COL.red | Out-Null }
  $pos = @(); $i = 0
  foreach ($s in $SITEPOS) { $px = $x + $w * $s[0]; $py = $y + $h * $s[1]; $pos += , @($px, $py)
    if ($sites) { if ($hits -and $i -lt 3) { Ring $px $py 13 $COL.red 1.2 4 | Out-Null; Dot $px $py 6 $COL.red $COL.white | Out-Null } else { Dot $px $py 4.5 $(if ($dim) { $COL.grey } else { $COL.ink }) $COL.white | Out-Null } }; $i++ }
  return , $pos }

# ---------- data ----------
$sitesCsv = Import-Csv "$r\data\tra_sites_exposure.csv"
$nYes = @($sitesCsv | Where-Object { $_.reflood_documented -eq 'yes' }).Count

$pp = New-Object -ComObject PowerPoint.Application
$script:pres = $pp.Presentations.Add(0); $pres.PageSetup.SlideWidth = 960; $pres.PageSetup.SlideHeight = 540
$n = 0

# ===== 0 TITLE: vertical-line poster from real data =====
$n++; NewSlide $n | Out-Null
Txt 36 40 420 90 "Who owns the flood?" 44 $COL.red 'Bahnschrift' 1 | Out-Null
Txt 36 100 400 60 "A sketch deck of the interaction states and the first prototype of our data visualization." 14 $COL.ink 'Segoe UI' | Out-Null
Txt 36 170 400 14 "Hollie & Wandile $DOTC Harvard GSD MDE $DOTC Sept 2026" 10 $COL.grey 'Consolas' | Out-Null
$act = @($sitesCsv | Where-Object { $_.est_year -match '^\d{4}$' } | Sort-Object province, { [int]$_.est_year })
$x0 = 470; $x1 = 925; $yTop = 70; $yBot = 470; $yr = { param($v) $yTop + ($v - 2000) / 26.0 * ($yBot - $yTop) }
SLine @(@(($x0 - 6), $yTop), @(($x1 + 4), $yTop)) $COL.ink 1 1 0.6 | Out-Null
$step = ($x1 - $x0) / [math]::Max(1, $act.Count - 1); $i = 0
foreach ($s in $act) { $xx = $x0 + $i * $step; $y1 = [single](& $yr ([int]$s.est_year)); $xx = [single]$xx
  $ln = $script:sl.Shapes.AddLine($xx, $yTop, $xx, $yBot); $ln.Line.ForeColor.RGB = [int]$COL.light; $ln.Line.Weight = 0.6
  $b = $script:sl.Shapes.AddLine($xx, $y1, $xx, $yBot); $b.Line.ForeColor.RGB = [int]$(if ($s.reflood_documented -eq 'yes') { $COL.red } elseif ($s.origin -eq 'flood') { $COL.pink } else { $COL.grey }); $b.Line.Weight = [single]$(if ($s.reflood_documented -eq 'yes') { 3.5 } else { 1.6 })
  if ($s.reflood_documented -eq 'yes') { Dot $xx ($yBot + 12) 4 $COL.red | Out-Null }; $i++ }
foreach ($yv in 2000, 2010, 2020, 2026) { Txt ($x0 - 40) ((& $yr $yv) - 6) 32 12 "$yv" 8 $COL.grey 'Consolas' 0 3 | Out-Null }
Dot 480 500 18 $COL.red | Out-Null
Txt 36 330 400 110 ("Each vertical line is one of South Africa's $($act.Count) dated " + $Q1 + "temporary" + $Q2 + " relocation sites. It runs from the year the site opened to 2026. Pink = opened for flood survivors. Red = flooded again after people moved in ($nYes sites; 30 of 84 searched).") 11 $COL.ink 'Ink Free' | Out-Null
Txt 36 470 400 14 "Source: SA TRAs 2022-2026 site list; reflooding sweep (data/tra_sites_exposure.csv)" 7 $COL.grey 'Consolas' | Out-Null

# ===== 1 OVERVIEW =====
$n++; NewSlide $n | Out-Null; Header "03 $DOTC MOCK-UP $DOTC PROJECT INTERACTION ACROSS STATES" "Seven states, one scroll" "$n"
$names = @('The response', 'Add the flood map', 'Ground truth', 'Not just a map', 'Only South Africa?', 'What changes?', 'The reveal')
for ($i = 0; $i -lt 7; $i++) { $x = 36 + $i * 128; SBox $x 110 112 90 $COL.ink 1.3 $COL.white
  switch ($i) {
    0 { Squig ($x + 10) 140 70 5 $COL.blue 1.5; foreach ($k in 0..4) { Dot ($x + 20 + $k * 15) (160 + ($k % 2) * 12) 2.5 $COL.ink | Out-Null } }
    1 { Squig ($x + 10) 140 70 5 $COL.blue 1.5; Hatch @(@(($x + 25), 145), @(($x + 60), 138), @(($x + 70), 162), @(($x + 30), 170)) $COL.red | Out-Null; foreach ($k in 0..3) { Dot ($x + 28 + $k * 14) (156 + ($k % 2) * 8) 2.5 $COL.ink | Out-Null } }
    2 { Ring ($x + 45) 150 22 $COL.ink 1.5 | Out-Null; SLine @(@(($x + 61), 166), @(($x + 80), 185)) $COL.ink 2 | Out-Null; Dot ($x + 45) 150 4 $COL.red | Out-Null }
    3 { foreach ($k in 0..3) { SBox ($x + 8 + $k * 25) (130 + ($k % 3) * 18) 20 12 $COL.grey 1 } }
    4 { foreach ($k in 0..6) { $l = $script:sl.Shapes.AddLine(($x + 14 + $k * 13), 125, ($x + 14 + $k * 13), 190); $l.Line.ForeColor.RGB = [int]$COL.grey; $l.Line.Weight = 0.8; if ($k -lt 4) { $b = $script:sl.Shapes.AddLine(($x + 14 + $k * 13), (140 + $k * 8), ($x + 14 + $k * 13), (160 + $k * 6)); $b.Line.ForeColor.RGB = [int]$COL.red; $b.Line.Weight = 3 } } }
    5 { SLine @(@(($x + 10), 140), @(($x + 100), 140)) $COL.red 1.5 1 1 -arrow | Out-Null; SLine @(@(($x + 10), 170), @(($x + 100), 170)) $COL.ink 1.5 1 1 -arrow | Out-Null }
    6 { Squig ($x + 20) 150 60 5 $COL.blue 1.5; SBox ($x + 6) 125 26 10 $COL.red 1; SBox ($x + 6) 175 26 10 $COL.red 1; Dot ($x + 60) 155 4 $COL.red | Out-Null } }
  Txt $x 208 112 14 ("0" + ($i + 1)) 10 $COL.red 'Consolas' 1 | Out-Null; Txt $x 222 112 30 $names[$i] 13 $COL.ink 'Ink Free' 1 | Out-Null
  if ($i -lt 6) { SLine @(@(($x + 114), 155), @(($x + 126), 155)) $COL.ink 1.2 1 0.5 -arrow | Out-Null } }
$arc = @('Geography', 'Evidence', 'People', 'Institutions', 'Comparison', 'Systemic reveal')
for ($i = 0; $i -lt 6; $i++) { $x = 60 + $i * 150; Txt ($x - 20) 330 140 20 $arc[$i] 16 $COL.ink 'Bahnschrift' 1 2 | Out-Null; Dot ($x + 50) 312 4 $(if ($i -eq 5) { $COL.red } else { $COL.ink }) | Out-Null
  if ($i -lt 5) { SLine @(@(($x + 58), 312), @(($x + 100), 296), @(($x + 142), 296), @(($x + 192), 310)) $COL.grey 1 4 0.8 -arrow | Out-Null } }
Txt 60 380 840 60 "The viewer scrolls. Each state adds one layer to the last: the map, then the evidence, then the people, then the institutions behind it, then the world, and finally the reveal." 14 $COL.ink 'Segoe UI' | Out-Null

# ===== FRAMES =====
$frames = @(
 @{ t = "Frame 1 $DASH The response"; num = '01'; narr = 'After the 2022 floods, government identified and relocated displaced residents.'; inter = 'The map loads. Relocation sites fade in one by one as the viewer scrolls.'; q = '' },
 @{ t = "Frame 2 $DASH Add the flood map"; num = '02'; narr = "Same map. Add the city's 1:100 floodline (1:50 not yet obtained)."; inter = 'Toggle the floodline layer. Relocation sites become visible against known flood risk.'; q = 'Are these places actually safer?' },
 @{ t = "Frame 3 $DASH Ground truth"; num = '03'; narr = "Some relocated communities experienced flooding again. Gwala St (Lamontville), Isipingo and Madamfana are documented Durban examples; nationally, $nYes sites (30 of 84 searched)."; inter = 'Zoom into a site: photographs, testimony and the flood incidents open in a side panel.'; q = '' },
 @{ t = "Frame 4 $DASH This is not just a map problem"; num = '04'; narr = 'The risk information exists, but it passes through a fragmented decision chain.'; inter = 'Pull back from the sites. The chain draws itself link by link; a red x appears at every hand-off.'; q = '' },
 @{ t = "Frame 5 $DASH Is this only South Africa?"; num = '05'; narr = 'International cases: failure-like systems on the left, different architectures on the right.'; inter = 'Scroll: red flood marks drop onto each timeline after the move. The right-hand timelines stay clean.'; q = '' },
 @{ t = "Frame 6 $DASH What changes?"; num = '06'; narr = 'Compare the two decision architectures.'; inter = 'The two flows animate in parallel. The failure flow loops back on itself.'; q = '' },
 @{ t = "Frame 7 $DASH The reveal"; num = '07'; narr = 'Return to the original Durban map, with the system drawn over it.'; inter = 'Each institution lights up and links to what it knew. None connects to the decision about the site.'; q = '' }
)
for ($f = 0; $f -lt 7; $f++) {
  $n++; NewSlide $n | Out-Null; $fr = $frames[$f]; Header "03 $DOTC MOCK-UP $DOTC STATE $($f + 1) OF 7" $fr.t "$n"; SideText $fr.num $fr.narr $fr.inter $fr.q; Progress ($f + 1)
  $bx = 36; $by = 92; $bw = 580; $bh = 400
  switch ($f) {
   0 { $p = MapSketch $bx $by $bw $bh -sites
       Txt ($bx + 14) ($by + 12) 200 16 'eThekwini (Durban)' 14 $COL.ink 'Bahnschrift' 1 | Out-Null
       SLine @(@(($bx + 390), ($by + 70)), @(($p[6][0] + 8), ($p[6][1] - 6))) $COL.ink 1 1 1 -arrow | Out-Null; Txt ($bx + 330) ($by + 50) 200 16 'relocation sites (TRAs / TEAs)' 12 $COL.ink | Out-Null
       Txt ($bx + 14) ($by + $bh - 26) 300 14 'black dot = relocation site' 10 $COL.grey | Out-Null }
   1 { $p = MapSketch $bx $by $bw $bh -sites -flood
       SBox ($bx + 12) ($by + 12) 190 64 $COL.ink 1 $COL.white; Txt ($bx + 22) ($by + 18) 170 14 'LAYERS' 8 $COL.grey 'Consolas' | Out-Null
       $tg = $script:sl.Shapes.AddShape(5, ($bx + 22), ($by + 36), 26, 12); $tg.Fill.ForeColor.RGB = [int]$COL.red; $tg.Line.Visible = 0; Dot ($bx + 42) ($by + 42) 5 $COL.white | Out-Null; Txt ($bx + 54) ($by + 34) 140 14 '1:100 floodline' 11 $COL.ink | Out-Null
       $tg2 = $script:sl.Shapes.AddShape(5, ($bx + 22), ($by + 54), 26, 12); $tg2.Fill.ForeColor.RGB = [int]$COL.light; $tg2.Line.Visible = 0; Dot ($bx + 28) ($by + 60) 5 $COL.white | Out-Null; Txt ($bx + 54) ($by + 52) 140 14 '1:50 floodline (not yet)' 11 $COL.grey | Out-Null
       SLine @(@(($bx + 420), ($by + 330)), @(($p[4][0] + 10), ($p[4][1] + 6))) $COL.red 1 1 1 -arrow | Out-Null; Txt ($bx + 360) ($by + 336) 210 30 'sites light up where they touch the floodline' 11 $COL.red | Out-Null
       Txt ($bx + 14) ($by + $bh - 26) 420 14 'hatched = eThekwini 1:100 floodplain (open data)' 10 $COL.grey | Out-Null }
   2 { $p = MapSketch $bx $by 250 $bh -sites -flood -hits
       Ring ($bx + 250 * .22) ($by + $bh * .30) 26 $COL.ink 1.5 | Out-Null; SLine @(@(($bx + 76), ($by + 138)), @(($bx + 290), ($by + 110))) $COL.ink 1 4 0.5 | Out-Null; SLine @(@(($bx + 76), ($by + 160)), @(($bx + 290), ($by + 290))) $COL.ink 1 4 0.5 | Out-Null
       SBox ($bx + 290) ($by + 10) 290 ($bh - 20) $COL.ink 1.5 $COL.white
       foreach ($k in 0, 1) { $px = $bx + 305 + $k * 138; SBox $px ($by + 26) 124 88 $COL.grey 1; SLine @(@($px, ($by + 26)), @(($px + 124), ($by + 114))) $COL.light 1 | Out-Null; SLine @(@(($px + 124), ($by + 26)), @($px, ($by + 114))) $COL.light 1 | Out-Null }
       Txt ($bx + 305) ($by + 118) 124 14 'photo: Gwala St, 2022' 10 $COL.grey | Out-Null; Txt ($bx + 443) ($by + 118) 124 14 'photo: Isipingo' 10 $COL.grey | Out-Null
       Txt ($bx + 305) ($by + 146) 262 60 ($Q1 + "We have been moved from one place to another." + $Q2) 17 $COL.ink 'Ink Free' 1 | Out-Null
       Txt ($bx + 305) ($by + 198) 262 14 "resident, GroundUp (headline)" 9 $COL.grey 'Consolas' | Out-Null
       SLine @(@(($bx + 310), ($by + 300)), @(($bx + 565), ($by + 300))) $COL.ink 1 1 0.5 | Out-Null
       $ev = @(@(2008, 'moved', 0), @(2019, 'flood', 1), @(2021, 'moved', 0), @(2022, 'flood', 1), @(2025, '5 dead', 1))
       $ei = 0; foreach ($e in $ev) { $ly = $(if ($ei % 2) { -36 } else { 0 }); $ei++; $ex = $bx + 310 + ($e[0] - 2007) / 19.0 * 255; if ($e[2]) { Dot $ex ($by + 300) 6 $COL.red | Out-Null } else { SBox ($ex - 4) ($by + 294) 8 12 $COL.ink 1 $COL.ink }; Txt ($ex - 20) ($by + 312 + $ly) 40 12 "$($e[0])" 8 $COL.grey 'Consolas' 0 2 | Out-Null; Txt ($ex - 26) ($by + 324 + $ly) 52 14 $e[1] 10 $(if ($e[2]) { $COL.red } else { $COL.ink }) 'Ink Free' 0 2 | Out-Null }
       Txt ($bx + 305) ($by + 260) 262 14 'INCIDENTS AT THIS CAMP' 8 $COL.grey 'Consolas' | Out-Null }
   3 { $lanes = @(150, 250, 350); $sph = @(0, 2, 2, 1, 1, 2, 1, 1); $nm = @('SAWS', 'Disaster Mgmt', 'Municipality', 'Province', 'Human Settlements', 'Land', 'Temporary housing', 'Permanent housing')
       Txt $bx ($lanes[0] + 6) 70 14 'national' 11 $COL.grey | Out-Null; Txt $bx ($lanes[1] + 6) 70 14 'provincial' 11 $COL.grey | Out-Null; Txt $bx ($lanes[2] + 6) 70 14 'municipal' 11 $COL.grey | Out-Null
       foreach ($l in $lanes) { SLine @(@(($bx + 70), ($l + 34)), @(($bx + $bw), ($l + 34))) $COL.faint 1 4 0.3 | Out-Null }
       $pts = @(); for ($i = 0; $i -lt 8; $i++) { $pts += , @(($bx + 80 + $i * 62), $lanes[$sph[$i]]) }
       for ($i = 0; $i -lt 7; $i++) { $a = $pts[$i]; $b = $pts[$i + 1]; SLine @(@(($a[0] + 54), ($a[1] + 14)), @($b[0], ($b[1] + 14))) $COL.red 1.3 4 0.8 | Out-Null; Txt (($a[0] + 54 + $b[0]) / 2 - 5) ([math]::Min($a[1], $b[1]) + $(if ($a[1] -eq $b[1]) { -4 } else { 30 })) 12 14 $TIMES 13 $COL.red 'Segoe UI' 1 | Out-Null }
       for ($i = 0; $i -lt 8; $i++) { SBox $pts[$i][0] $pts[$i][1] 54 28 $COL.ink 1.3 $COL.white; Txt ($pts[$i][0] + 2) ($pts[$i][1] + 3) 50 24 $nm[$i] 8.5 $COL.ink 'Ink Free' 1 2 | Out-Null }
       SBox ($bx + 76) ($by + 6) 110 26 $COL.blue 1.3 $COL.white; Txt ($bx + 80) ($by + 11) 104 16 'risk information' 11 $COL.blue 'Ink Free' 1 2 | Out-Null
       SLine @(@(($bx + 110), ($by + 32)), @(($bx + 106), ($lanes[0] - 2))) $COL.blue 1.5 1 1 -arrow | Out-Null
       SLine @(@(($bx + 136), ($by + 38)), @(($bx + 300), ($by + 30)), @(($bx + 560), ($by + 44))) $COL.blue 1 3 1 | Out-Null; Txt ($bx + 300) ($by + 10) 260 14 'fades as it moves down the chain' 10 $COL.blue | Out-Null
       Txt ($bx + 80) ($by + 350) 500 20 "8 links $DOTC 3 spheres $DOTC 7 hand-offs $DOTC 0 end-to-end owners" 15 $COL.red 'Bahnschrift' 1 | Out-Null }
   4 { $yA = $by + 50; $yB = $by + $bh - 40; $yy = { param($v) $yA + ($v - 1998) / 28.5 * ($yB - $yA) }
       Txt $bx ($by + 4) 300 16 'Failure-like systems' 15 $COL.red 'Bahnschrift' 1 | Out-Null; Txt ($bx + 360) ($by + 4) 230 16 'Different architectures' 15 $COL.ink 'Bahnschrift' 1 | Out-Null
       $fail = @(@('South Africa', 2021, @(2022, 2025)), @('Chennai', 2016, @(2018, 2019, 2020, 2021, 2023)), @('Kasiglahan', 2000, @(2009, 2012, 2014, 2020)), @('Corail-Canaan', 2010, @()), @("Cox's Bazar", 2017, @(2018, 2019, 2020, 2021, 2024)), @('Bentiu', 2014, @(2021, 2022)), @('Mozambique', 2001, @(2007)))
       for ($i = 0; $i -lt 7; $i++) { $cx = $bx + 30 + $i * 44; $cs = $fail[$i]; $l = $script:sl.Shapes.AddLine($cx, $yA, $cx, $yB); $l.Line.ForeColor.RGB = [int]$COL.light; $l.Line.Weight = 0.8
         $m = $script:sl.Shapes.AddLine($cx, (& $yy $cs[1]), $cx, $yB); $m.Line.ForeColor.RGB = [int]$COL.grey; $m.Line.Weight = 1.5; SBox ($cx - 5) ((& $yy $cs[1]) - 1) 10 2 $COL.ink 1.5
         if ($cs[0] -eq 'Corail-Canaan') { $band = $script:sl.Shapes.AddShape(1, ($cx - 3), (& $yy 2010.5), 6, ($yB - (& $yy 2010.5))); $band.Fill.ForeColor.RGB = [int]$COL.pink; $band.Line.Visible = 0 }
         foreach ($fy in $cs[2]) { $bb = $script:sl.Shapes.AddShape(1, ($cx - 2.5), ((& $yy $fy) - 5), 5, 10); $bb.Fill.ForeColor.RGB = [int]$COL.red; $bb.Line.Visible = 0 }
         $tl = Txt ($cx - 8) ($yB + 6) 80 12 $cs[0] 9 $COL.ink 'Ink Free'; $tl.Rotation = 40 }
       $good = @(@('Grantham', 2011.9), @('Vunidogoloa', 2014), @('Iwanuma', 2015), @('Overdiepse', 2015), @('Gramalote', 2017))
       for ($i = 0; $i -lt 5; $i++) { $cx = $bx + 390 + $i * 42; $l = $script:sl.Shapes.AddLine($cx, $yA, $cx, $yB); $l.Line.ForeColor.RGB = [int]$COL.light; $l.Line.Weight = 0.8
         $m = $script:sl.Shapes.AddLine($cx, (& $yy $good[$i][1]), $cx, $yB); $m.Line.ForeColor.RGB = [int]$COL.ink; $m.Line.Weight = 2.5; SBox ($cx - 5) ((& $yy $good[$i][1]) - 1) 10 2 $COL.ink 1.5
         $tl = Txt ($cx - 8) ($yB + 6) 80 12 $good[$i][0] 9 $COL.ink 'Ink Free'; $tl.Rotation = 40 }
       foreach ($yv in 2000, 2010, 2020) { Txt ($bx - 4) ((& $yy $yv) - 6) 28 12 "$yv" 8 $COL.grey 'Consolas' | Out-Null }
       Txt ($bx + 360) ($by + 26) 220 14 'dash = move-in; red = flood after the move' 9 $COL.grey | Out-Null }
   5 { $y1 = $by + 70; $y2 = $by + 260
       Txt $bx ($by + 20) 300 16 'Failure pattern' 15 $COL.red 'Bahnschrift' 1 | Out-Null
       $fa = @('Information', 'Multiple institutions', 'Fragmented authority', 'Temporary solution', 'Repeated exposure'); for ($i = 0; $i -lt 5; $i++) { $x = $bx + $i * 118; SBox $x $y1 100 46 $COL.red 1.3 $COL.white; Txt ($x + 4) ($y1 + 8) 92 32 $fa[$i] 12 $COL.ink 'Ink Free' 1 2 | Out-Null; if ($i -lt 4) { SLine @(@(($x + 102), ($y1 + 23)), @(($x + 116), ($y1 + 23))) $COL.red 1.3 1 0.5 -arrow | Out-Null } }
       foreach ($k in -1, 0, 1) { SLine @(@(($bx + 100), ($y1 + 23)), @(($bx + 118), ($y1 + 23 + $k * 18))) $COL.red 1 4 0.4 | Out-Null }
       SLine @(@(($bx + 522), ($y1 + 48)), @(($bx + 500), ($y1 + 96)), @(($bx + 400), ($y1 + 100)), @(($bx + 390), ($y1 + 50))) $COL.red 1.5 1 1 -arrow | Out-Null; Txt ($bx + 400) ($y1 + 104) 160 14 'loops back after the next flood' 11 $COL.red | Out-Null
       Txt $bx ($y2 - 50) 300 16 'Alternative pattern' 15 $COL.ink 'Bahnschrift' 1 | Out-Null
       $al = @('Government owner', 'Land + budget + authority', 'Residents participate', 'Risk information is binding', 'Long-term settlement'); for ($i = 0; $i -lt 5; $i++) { $x = $bx + $i * 118; SBox $x $y2 100 52 $COL.ink 1.8 $COL.white; Txt ($x + 4) ($y2 + 8) 92 38 $al[$i] 12 $COL.ink 'Ink Free' 1 2 | Out-Null; if ($i -lt 4) { SLine @(@(($x + 102), ($y2 + 26)), @(($x + 116), ($y2 + 26))) $COL.ink 1.5 1 0.5 -arrow | Out-Null } }
       Txt ($bx + 480) ($y2 + 58) 100 20 "$CK stays dry" 13 $COL.ink 'Ink Free' 1 | Out-Null
       Txt $bx ($by + 360) 560 30 'Separates the cases: one owner (0% vs 90%), residents choose the site (0% vs 90%), binding flood maps (8% vs 100%).' 11 $COL.grey 'Segoe UI' | Out-Null }
   6 { $p = MapSketch ($bx + 170) $by 410 $bh -sites -flood -hits
       $bxs = @(@('SAWS', 'had the forecast'), @('City', 'had the flood map'), @('Auditor-General', 'flagged the site'), @('Province', 'owns the shelters'), @('Councillor', 'sent families back'))
       for ($i = 0; $i -lt 5; $i++) { $yb = $by + 10 + $i * 78; SBox $bx $yb 150 56 $COL.ink 1.3 $COL.white; Txt ($bx + 8) ($yb + 6) 140 16 $bxs[$i][0] 13 $COL.ink 'Bahnschrift' 1 | Out-Null; Txt ($bx + 8) ($yb + 28) 140 16 $bxs[$i][1] 12 $COL.grey 'Ink Free' | Out-Null
         SLine @(@(($bx + 150), ($yb + 28)), @(($p[0][0] - 12), ($p[0][1] + ($i - 2) * 4))) $COL.red 1 4 1 | Out-Null }
       Txt 650 300 270 40 'Why are people living in dangerous places?' 13 $COL.grey 'Ink Free' | Out-Null; SLine @(@(648, 309), @(912, 305)) $COL.red 2 1 0.5 | Out-Null
       Txt 650 330 270 50 'Who owns the decision that determines where they live?' 17 $COL.red 'Ink Free' 1 | Out-Null
       Txt 650 400 270 80 ("South Africa has the information. The institutions that possess it do not control the decisions that determine exposure.") 11 $COL.ink 'Segoe UI' 1 | Out-Null } }
}

# ===== 04 PROTOTYPE: what are we building =====
$n++; NewSlide $n | Out-Null; Header "04 $DOTC PROTOTYPE DATA VISUALIZATION" "What are we actually building?" "$n"
Txt 36 88 880 30 'An interactive scroll story that moves between:' 15 $COL.ink 'Segoe UI' | Out-Null
$st = @(@('Geography', 'frames 1-2'), @('Evidence', 'frames 2-3'), @('People', 'frame 3'), @('Institutions', 'frame 4'), @('Comparison', 'frames 5-6'), @('Systemic reveal', 'frame 7'))
for ($i = 0; $i -lt 6; $i++) { $cx = 100 + $i * 152; Ring $cx 200 44 $(if ($i -eq 5) { $COL.red } else { $COL.ink }) 1.8 | Out-Null; Txt ($cx - 60) 186 120 20 $st[$i][0] 14 $(if ($i -eq 5) { $COL.red } else { $COL.ink }) 'Bahnschrift' 1 2 | Out-Null; Txt ($cx - 60) 252 120 14 $st[$i][1] 10 $COL.grey 'Ink Free' 0 2 | Out-Null
  if ($i -lt 5) { SLine @(@(($cx + 48), 200), @(($cx + 104), 200)) $COL.grey 1.3 1 0.6 -arrow | Out-Null } }
SBox 36 300 880 150 $COL.red 1.5 $COL.white
Txt 56 314 840 18 'HIGH-FIDELITY FIRST PROTOTYPE' 9 $COL.red 'Consolas' 1 | Out-Null
Txt 56 334 840 40 'Frame 2: the eThekwini map with relocation sites and floodline data.' 20 $COL.ink 'Bahnschrift' 1 | Out-Null
Txt 56 376 840 60 'Why this frame first: it uses our actual dataset (84 sites, the city floodplain, 300 random comparison points) and it establishes the visual language of the whole project: map, points, layers.' 13 $COL.ink 'Segoe UI' | Out-Null

# ===== HI-FI FRAME 2 from real data =====
$n++; NewSlide $n | Out-Null; Header "04 $DOTC PROTOTYPE $DOTC HIGH-FIDELITY FRAME 2" "Are these places actually safer?" "$n"
$LW = 30.74; $LE = 31.14; $LN = -29.53; $LS = -30.06
function MY($lat) { $p = $lat * [math]::PI / 180; [math]::Log([math]::Tan([math]::PI / 4 + $p / 2)) }
$mh = 430.0; $mw = $mh * (($LE - $LW) * [math]::PI / 180) / ((MY $LN) - (MY $LS)); $mx0 = 40.0; $my0 = 88.0
function PX($lon) { $mx0 + ($lon - $LW) / ($LE - $LW) * $mw }; function PY($lat) { $my0 + ((MY $LN) - (MY $lat)) / ((MY $LN) - (MY $LS)) * $mh }
# light recolour of the satellite mosaic, cropped to the map extent
$src = [System.Drawing.Bitmap]::FromFile("$r\data\raw\durban_water_raw.png")
$mw0 = 30.673828125; $me0 = 31.201171875; $mn0 = -29.45873118535533; $ms0 = -30.145127183376118
$cx0 = [int](($LW - $mw0) / ($me0 - $mw0) * $src.Width); $cx1 = [int](($LE - $mw0) / ($me0 - $mw0) * $src.Width)
$cy0 = [int](((MY $mn0) - (MY $LN)) / ((MY $mn0) - (MY $ms0)) * $src.Height); $cy1 = [int](((MY $mn0) - (MY $LS)) / ((MY $mn0) - (MY $ms0)) * $src.Height)
$crop = $src.Clone((New-Object System.Drawing.Rectangle $cx0, $cy0, ($cx1 - $cx0), ($cy1 - $cy0)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb); $src.Dispose()
$rect = New-Object System.Drawing.Rectangle 0, 0, $crop.Width, $crop.Height; $bd = $crop.LockBits($rect, 3, $crop.PixelFormat); $nb = $bd.Stride * $crop.Height; $buf = New-Object byte[] $nb
[Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $buf, 0, $nb)
for ($i = 0; $i -lt $nb; $i += 4) { if ($buf[$i + 3] -eq 0) { continue }; if ($buf[$i] -ge 128) { $buf[$i] = 236; $buf[$i + 1] = 230; $buf[$i + 2] = 220 } else { $buf[$i] = 207; $buf[$i + 1] = 168; $buf[$i + 2] = 111 }; $buf[$i + 3] = 255 }
[Runtime.InteropServices.Marshal]::Copy($buf, 0, $bd.Scan0, $nb); $crop.UnlockBits($bd); $crop.Save("$sp\hifi_water.png", [System.Drawing.Imaging.ImageFormat]::Png); $crop.Dispose()
$bg = $script:sl.Shapes.AddShape(1, $mx0, $my0, $mw, $mh); $bg.Fill.ForeColor.RGB = [int]$COL.white; $bg.Line.ForeColor.RGB = [int]$COL.light; $bg.Line.Weight = 0.75
$pic = $script:sl.Shapes.AddPicture("$sp\hifi_water.png", 0, -1, $mx0, $my0, $mw, $mh); $pic.Name = 'Satellite water (JRC GSW)'
# floodplain polygons (simplified)
$gj = Get-Content "$r\data\raw\ethekwini_floodplain_100yr.geojson" -Raw | ConvertFrom-Json
$polys = 0
foreach ($ft in $gj.features) { $g = $ft.geometry; $rings = New-Object System.Collections.Generic.List[object]; if ($g.type -eq 'Polygon') { $rings.Add($g.coordinates[0]) } else { foreach ($pg0 in $g.coordinates) { $rings.Add($pg0[0]) } }
  foreach ($ring in $rings) { $pts = @($ring); if ($pts.Count -lt 4) { continue }
    $lons = $pts | ForEach-Object { [double]$_[0] }; $lats = $pts | ForEach-Object { [double]$_[1] }
    $mnx = ($lons | Measure-Object -Minimum).Minimum; $mxx = ($lons | Measure-Object -Maximum).Maximum; $mny = ($lats | Measure-Object -Minimum).Minimum; $mxy = ($lats | Measure-Object -Maximum).Maximum
    if ($mxx -lt $LW -or $mnx -gt $LE -or $mxy -lt $LS -or $mny -gt $LN) { continue }
    if ((($mxx - $mnx) * ($mxy - $mny)) -lt 0.000004) { continue }
    $k = [math]::Max(1, [int]($pts.Count / 40)); $sp2 = @(); for ($i = 0; $i -lt $pts.Count; $i += $k) { $qx = [math]::Min([math]::Max((PX ([double]$pts[$i][0])), $mx0), ($mx0 + $mw)); $qy = [math]::Min([math]::Max((PY ([double]$pts[$i][1])), $my0), ($my0 + $mh)); $sp2 += , @($qx, $qy) }
    if ($sp2.Count -ge 3) { $pg = Poly $sp2 $COL.red $COL.red 0.55; $polys++ } } }
# sites
$dsites = @($sitesCsv | Where-Object { $_.municipality -eq 'eThekwini' -and $_.lat })
foreach ($s in $dsites) { $px = PX ([double]::Parse($s.lon, $inv)); $py = PY ([double]::Parse($s.lat, $inv))
  $near = $s.ethekwini_floodplain -in 'inside', 'within_250m'
  if ($s.reflood_documented -eq 'yes') { Ring $px $py 11 $COL.red 1.3 | Out-Null; Dot $px $py 5.5 $COL.red $COL.white | Out-Null }
  elseif ($near) { Dot $px $py 4.5 $COL.ink $COL.white | Out-Null } else { Dot $px $py 4.5 $COL.white $COL.ink | Out-Null } }
$lab = @{ '32' = 'Gwala St, Lamontville'; '26' = 'Isipingo'; '29' = 'Madamfana' }
foreach ($s in $dsites) { if ($lab.ContainsKey($s.id)) { $px = PX ([double]::Parse($s.lon, $inv)); $py = PY ([double]::Parse($s.lat, $inv)); Txt ($px + 12) ($py - 7) 140 14 $lab[$s.id] 10 $COL.red 'Bahnschrift' 1 | Out-Null } }
foreach ($l in @(@('DURBAN CBD', 31.02, -29.858), @('UMLAZI', 30.885, -29.965), @('PINETOWN', 30.86, -29.815), @('INANDA', 30.95, -29.69))) { Txt ((PX $l[1]) - 40) ((PY $l[2]) - 6) 80 12 $l[0] 7 $COL.grey 'Consolas' 0 2 | Out-Null }
$km = 10 / (111.32 * [math]::Cos(30 * [math]::PI / 180)); $l1 = $script:sl.Shapes.AddLine(($mx0 + 10), ($my0 + $mh - 14), ($mx0 + 10 + $km / ($LE - $LW) * $mw), ($my0 + $mh - 14)); $l1.Line.ForeColor.RGB = [int]$COL.ink; $l1.Line.Weight = 1.5; Txt ($mx0 + 10) ($my0 + $mh - 28) 60 12 '10 km' 8 $COL.ink 'Consolas' | Out-Null
# right panel: layer toggles + stat + legend
$rx = $mx0 + $mw + 36
Txt $rx 92 300 14 'LAYERS (toggle)' 8 $COL.grey 'Consolas' | Out-Null
$layers = @(@('Satellite water, 1984-2021', $COL.blue, 1), @('1:100 floodline', $COL.red, 1), @('Relocation sites', $COL.ink, 1), @('Documented reflooding', $COL.red, 1), @('1:50 floodline (not yet)', $COL.light, 0))
for ($i = 0; $i -lt 5; $i++) { $yy = 110 + $i * 24; $tg = $script:sl.Shapes.AddShape(5, $rx, $yy, 26, 13); $tg.Fill.ForeColor.RGB = [int]$(if ($layers[$i][2]) { $layers[$i][1] } else { $COL.light }); $tg.Line.Visible = 0
  Dot $(if ($layers[$i][2]) { $rx + 19 } else { $rx + 7 }) ($yy + 6.5) 5 $COL.white | Out-Null; Txt ($rx + 34) ($yy - 1) 260 14 $layers[$i][0] 11 $(if ($layers[$i][2]) { $COL.ink } else { $COL.grey }) 'Segoe UI' | Out-Null }
$within = @($dsites | Where-Object { $_.ethekwini_floodplain -in 'inside', 'within_250m' }).Count
Txt $rx 250 330 60 "$within of $($dsites.Count)" 44 $COL.ink 'Bahnschrift' 1 | Out-Null
Txt $rx 302 330 40 "Durban relocation sites inside the city's 1:100 floodplain or within 250 m of it." 12 $COL.ink 'Segoe UI' | Out-Null
Txt $rx 344 330 40 'Random ground across Durban: 34%.' 16 $COL.red 'Bahnschrift' 1 | Out-Null
Txt $rx 368 330 30 'The flood map made no difference to where people were put (binomial p = 0.34).' 11 $COL.ink 'Ink Free' | Out-Null
Dot ($rx + 6) 414 4.5 $COL.ink $COL.white | Out-Null; Txt ($rx + 16) 408 300 12 'site inside / within 250 m of floodplain' 9 $COL.ink 'Segoe UI' | Out-Null
Dot ($rx + 6) 430 4.5 $COL.white $COL.ink | Out-Null; Txt ($rx + 16) 424 300 12 'site farther away' 9 $COL.ink 'Segoe UI' | Out-Null
Ring ($rx + 6) 446 7 $COL.red 1.2 | Out-Null; Dot ($rx + 6) 446 3.5 $COL.red | Out-Null; Txt ($rx + 16) 440 300 12 'flooding documented after the move' 9 $COL.ink 'Segoe UI' | Out-Null
Txt 40 522 880 12 "Data: eThekwini Flood Plain 100yr (open data); JRC Global Surface Water 1984-2021; SA TRAs 2022-2026 site list ($($dsites.Count) Durban sites with coordinates, +/-1-3 km); 300 seeded random points. methods/scripts/build_tra_exposure.ps1" 7 $COL.grey 'Consolas' | Out-Null

# ===== TYPOLOGY =====
$n++; NewSlide $n | Out-Null; Header "04 $DOTC PROTOTYPE" "Core visual typology" "$n"
$ty = @(@('Map', 'geography / exposure'), @('Points', 'people / sites'), @('Layers', 'evidence'), @('Flow diagram', 'institutional responsibility'), @('Comparison matrix', 'system architecture'))
for ($i = 0; $i -lt 5; $i++) { $x = 50 + $i * 176; $y = 130; SBox $x $y 150 150 $COL.light 1 $COL.white
  switch ($i) {
    0 { Squig ($x + 14) ($y + 50) 110 8 $COL.blue 2; Squig ($x + 20) ($y + 100) 100 7 $COL.blue 2; SLine @(@(($x + 125), ($y + 8)), @(($x + 115), ($y + 70)), @(($x + 130), ($y + 142))) $COL.grey 3 1 1.5 | Out-Null }
    1 { foreach ($k in 0..9) { Dot ($x + 25 + ($k * 37 % 100)) ($y + 30 + ($k * 53 % 95)) 5 $(if ($k -lt 2) { $COL.red } else { $COL.ink }) | Out-Null } }
    2 { foreach ($k in 0..2) { $o = $k * 22; Poly @(@(($x + 30), ($y + 50 + $o)), @(($x + 110), ($y + 40 + $o)), @(($x + 125), ($y + 70 + $o)), @(($x + 45), ($y + 80 + $o))) ([int](@($COL.paleblue, $COL.pink, $COL.faint)[$k])) $COL.grey 0.1 | Out-Null } }
    3 { foreach ($k in 0..2) { SBox ($x + 14 + $k * 44) ($y + 60 + ($k % 2) * 30) 34 20 $COL.ink 1.2; if ($k -lt 2) { SLine @(@(($x + 49 + $k * 44), ($y + 70 + ($k % 2) * 30)), @(($x + 58 + $k * 44), ($y + 70 + (($k + 1) % 2) * 30))) $COL.red 1 4 0.5 -arrow | Out-Null } } }
    4 { for ($a = 0; $a -lt 5; $a++) { for ($b = 0; $b -lt 5; $b++) { $cell = $script:sl.Shapes.AddShape(1, ($x + 22 + $b * 22), ($y + 22 + $a * 22), 18, 18); $cell.Line.ForeColor.RGB = [int]$COL.grey; $cell.Line.Weight = 0.75; $cell.Fill.ForeColor.RGB = [int]$(if (($a -lt 3 -and $b -lt 2) -or ($a -ge 3 -and $b -ge 2)) { $COL.red } else { $COL.white }) } } } }
  Txt $x ($y + 162) 150 20 $ty[$i][0] 16 $COL.ink 'Bahnschrift' 1 2 | Out-Null; Txt $x ($y + 184) 150 30 ("= " + $ty[$i][1]) 13 $COL.grey 'Ink Free' 0 2 | Out-Null }
Txt 50 380 860 40 'One visual language across the scroll: geography and evidence are layered on the map, then the story pulls back to flows (who is responsible) and a matrix (how the systems compare).' 13 $COL.ink 'Segoe UI' | Out-Null

if (Test-Path $out) { [IO.File]::Delete($out) }
$pres.SaveAs($out); $pres.SaveAs(($out -replace '\.pptx$', '.pdf'), 32)
$pres.Slides(11).Export("$sp\deck_s9.png", 'PNG', 1280, 720); $pres.Slides(5).Export("$sp\deck_s12.png", 'PNG', 1280, 720); $pres.Slides(1).Export("$sp\deck_s1.png", 'PNG', 1280, 720)
$pres.Close(); $pp.Quit()
"saved $out  slides=$n  floodplain polygons=$polys"
