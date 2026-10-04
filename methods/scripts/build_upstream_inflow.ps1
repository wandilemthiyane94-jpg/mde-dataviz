# Upstream inflow for the flood simulation: rivers that enter the 10 km study box from outside it.
# Terrain: AWS Terrain Tiles z11 (~70 m cells) over the wider uMlazi / Umlaas catchments.
# Method : fill pits, D8 flow directions, flow accumulation; find cells just outside the study box whose flow enters it
#          with a catchment of 5 km2 or more; for each, record upstream area binned by flow distance (travel time at 1.5 m/s).
#          Hydrograph Q(t) = sum over bins of area x runoff x rain(t - lag) (same ERA5 hourly rain everywhere; 70% runoff).
# Output : data/raw/upstream_inflow.json (entry points with lon/lat, catchment km2, hourly inflow m3/s for the 36-hour window)
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$cache = "$root\data\raw\terrain_tiles"; New-Item -ItemType Directory -Force $cache | Out-Null
$ZZ = 11; $W0 = 30.05; $E0 = 31.02; $N0 = -29.55; $S0 = -30.25
$BOX = @(30.8935546875, 31.00341796875, -29.897805610155867, -29.993002284551071)   # study box (rem/meta.json): W, E, N, S
function TX([double]$lon) { [math]::Floor(($lon + 180) / 360 * [math]::Pow(2, $ZZ)) }
function TY([double]$lat) { $r = $lat * [math]::PI / 180; [math]::Floor((1 - [math]::Log([math]::Tan($r) + 1 / [math]::Cos($r)) / [math]::PI) / 2 * [math]::Pow(2, $ZZ)) }
$x0 = TX $W0; $x1 = TX $E0; $y0 = TY $N0; $y1 = TY $S0
foreach ($x in $x0..$x1) { foreach ($y in $y0..$y1) { $f = "$cache\${ZZ}_${x}_${y}.png"; if (-not (Test-Path $f)) { Invoke-WebRequest "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/$ZZ/$x/$y.png" -OutFile $f -TimeoutSec 60 } } }
$rj = Get-Content "$root\data\raw\era5_rain_lamontville_2022-04.json" -Raw | ConvertFrom-Json
$si = [array]::IndexOf($rj.hourly.time, '2022-04-11T06:00'); $pre = 12   # include 12 h before the window so lagged rain is counted
$rainAll = @(0..(36 + $pre - 1) | ForEach-Object { [double]$rj.hourly.precipitation[$si - $pre + $_] })
Add-Type -ReferencedAssemblies System.Drawing -Language CSharp -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Collections.Generic;
public static class UP {
  public static float[] Mosaic(string dir,int z,int x0,int x1,int y0,int y1,out int W,out int H){
    W=(x1-x0+1)*256; H=(y1-y0+1)*256; var e=new float[W*H];
    for(int tx=x0;tx<=x1;tx++) for(int ty=y0;ty<=y1;ty++){ var b=new Bitmap(dir+"\\"+z+"_"+tx+"_"+ty+".png"); var d=b.LockBits(new Rectangle(0,0,256,256),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); var a=new byte[d.Stride*256]; Marshal.Copy(d.Scan0,a,0,a.Length); int st=d.Stride; b.UnlockBits(d); b.Dispose();
      for(int y=0;y<256;y++) for(int x=0;x<256;x++){ int i=y*st+x*4; e[((ty-y0)*256+y)*W+(tx-x0)*256+x]=a[i+2]*256f+a[i+1]+a[i]/256f-32768f; } }
    return e; }
  // returns downstream index per cell (-1 = edge / sea outlet)
  public static int[] Flow(float[] e,int W,int H){
    int N=W*H; var f=new float[N]; var done=new bool[N]; var heap=new SortedSet<long>(); Func<float,int,long> key=(v,i)=>(((long)Math.Round((v+1000)*1000))<<22)+(long)(uint)i;
    for(int i=0;i<N;i++){ int x=i%W,y=i/W; if(x==0||y==0||x==W-1||y==H-1||e[i]<=0.3f){ f[i]=e[i]; done[i]=true; heap.Add(key(f[i],i)); } }
    int[] dx={1,1,0,-1,-1,-1,0,1}, dy={0,1,1,1,0,-1,-1,-1}; var to=new int[N]; for(int i=0;i<N;i++) to[i]=-1;
    while(heap.Count>0){ long k=heap.Min; heap.Remove(k); int i=(int)(k&((1L<<22)-1)); int x=i%W,y=i/W;
      for(int d=0;d<8;d++){ int xx=x+dx[d],yy=y+dy[d]; if(xx<0||yy<0||xx>=W||yy>=H) continue; int j=yy*W+xx; if(done[j]) continue; done[j]=true; f[j]=Math.Max(e[j],f[i]+0.0005f); to[j]=i; heap.Add(key(f[j],j)); } }
    return to; }
  // entry cells: outside the box, flowing into it; for each, upstream cell counts binned by travel hours (dist/vel)
  public static List<double[]> Entries(int[] to,bool[] inBox,int W,int H,double cellm,double vel,int minCells,int maxLag){
    int N=W*H; var cnt=new int[N]; for(int i=0;i<N;i++) if(to[i]>=0) cnt[to[i]]++;
    var start=new int[N+1]; for(int i=0;i<N;i++) start[i+1]=start[i]+cnt[i]; var fill=new int[N]; var kid=new int[start[N]];
    for(int i=0;i<N;i++){ int j=to[i]; if(j>=0){ kid[start[j]+fill[j]]=i; fill[j]++; } }
    var res=new List<double[]>(); var dist=new double[N]; var q=new int[N];
    for(int i=0;i<N;i++){ int j=to[i]; if(j<0||inBox[i]||!inBox[j]) continue;
      int qh=0,qt=0; q[qt++]=i; dist[i]=0; var bins=new double[maxLag+1]; int n=0;
      while(qh<qt){ int c=q[qh++]; n++; int lag=(int)Math.Min(maxLag,Math.Floor(dist[c]/vel/3600)); bins[lag]+=1;
        for(int k=start[c];k<start[c+1];k++){ int ch=kid[k]; if(inBox[ch]) continue; int dx=Math.Abs(ch%W-c%W), dy=Math.Abs(ch/W-c/W); dist[ch]=dist[c]+((dx+dy==2)?1.4142:1.0)*cellm; q[qt++]=ch; } }
      if(n<minCells) continue; var row=new double[3+maxLag+1]; row[0]=j; row[1]=n; row[2]=i; for(int b=0;b<=maxLag;b++) row[3+b]=bins[b]; res.Add(row); }
    return res; }}
"@
$W = 0; $H = 0; $e = [UP]::Mosaic($cache, $ZZ, $x0, $x1, $y0, $y1, [ref]$W, [ref]$H); $to = [UP]::Flow($e, $W, $H)
$n = [math]::Pow(2, $ZZ); $cellm = 40075016.686 * [math]::Cos(29.9 * [math]::PI / 180) / ($n * 256); $cellA = $cellm * $cellm
function LonOf($x) { ($x0 + ($x + .5) / 256) / $n * 360 - 180 }; function LatOf($y) { $ty = $y0 + ($y + .5) / 256; [math]::Atan([math]::Sinh([math]::PI * (1 - 2 * $ty / $n))) * 180 / [math]::PI }
$NC = $W * $H; $isIn = New-Object bool[] $NC
function YP([double]$lat) { $r = $lat * [math]::PI / 180; ((1 - [math]::Log([math]::Tan($r) + 1 / [math]::Cos($r)) / [math]::PI) / 2 * $n - $y0) * 256 }
$xa = [int][math]::Ceiling(((($BOX[0] + 180) / 360 * $n) - $x0) * 256); $xb = [int][math]::Floor(((($BOX[1] + 180) / 360 * $n) - $x0) * 256)
$ya = [int][math]::Ceiling((YP $BOX[2])); $yb = [int][math]::Floor((YP $BOX[3]))
for ($y = $ya; $y -le $yb; $y++) { for ($x = $xa; $x -le $xb; $x++) { $isIn[$y * $W + $x] = $true } }
$minCells = [int][math]::Ceiling(5e6 / $cellA); $maxLag = 30
$rows = [UP]::Entries($to, $isIn, $W, $H, $cellm, 1.5, $minCells, $maxLag)
$entries = foreach ($row in $rows) { $j = [int]$row[0]
  $Q = @(0..35 | ForEach-Object { $t2 = $_ + $pre; $s = 0.0; for ($b = 0; $b -le $maxLag; $b++) { $ti = $t2 - $b; if ($ti -ge 0) { $s += $row[3 + $b] * $cellA * 0.7 * $rainAll[$ti] / 1000 / 3600 } }; [math]::Round($s, 1) })
  $ml = 0; for ($b = 0; $b -le $maxLag; $b++) { if ($row[3 + $b] -gt 0) { $ml = $b } }
  [pscustomobject][ordered]@{ lon = [math]::Round((LonOf ($j % $W)), 5); lat = [math]::Round((LatOf ([math]::Floor($j / $W))), 5); catchment_km2 = [math]::Round($row[1] * $cellA / 1e6, 1); max_lag_h = $ml; inflow_m3s = $Q } }$entries = $entries | Sort-Object catchment_km2 -Descending
@{ cell_m = [math]::Round($cellm, 1); runoff = 0.7; velocity_ms = 1.5; entries = @($entries) } | ConvertTo-Json -Depth 5 | Out-File "$root\data\raw\upstream_inflow.json" -Encoding utf8
$entries | ForEach-Object { "{0},{1}  {2} km2  peak {3} m3/s  lag<= {4} h" -f $_.lon, $_.lat, $_.catchment_km2, ($_.inflow_m3s | Measure-Object -Maximum).Maximum, $_.max_lag_h }
