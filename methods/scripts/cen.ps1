param([string[]]$ids, [switch]$kids)
foreach ($id in $ids) {
  $u = "https://census2011.adrianfrith.com/place/$id"
  try { $c = (Invoke-WebRequest -UseBasicParsing $u).Content } catch { "ERR $id"; continue }
  $t = [regex]::Match($c, '<title[^>]*>(.*?)</title>').Groups[1].Value
  $bc = ([regex]::Matches($c, '<li class="breadcrumb-item[^"]*">(?:<a[^>]*>)?([^<]+)') | % { $_.Groups[1].Value }) -join ' > '
  $pop = [regex]::Match($c, '<dt>Population</dt><dd>([\d,]+)').Groups[1].Value
  $i = $c.IndexOf('<h4>First language</h4>')
  $lang = ''
  if ($i -ge 0) {
    $seg = $c.Substring($i)
    $tb = $seg.IndexOf('<tbody>'); $te = $seg.IndexOf('</tbody>')
    $rows = [regex]::Matches($seg.Substring($tb, $te - $tb), '<tr><td>([^<]+)</td><td class="text-right">([\d,]+)</td><td class="text-right">([\d.]+)%</td></tr>')
    $lang = ($rows | % { "$($_.Groups[1].Value)=$($_.Groups[3].Value)" }) -join '; '
  }
  "[$id] $t | $bc | pop $pop"
  "   $lang"
  if ($kids) {
    $m = [regex]::Matches($c, '<a href="/place/(\d+)">([^<]+)</a>')
    "   kids: " + (($m | % { "$($_.Groups[2].Value)=$($_.Groups[1].Value)" } | select -Unique) -join ', ')
  }
}
