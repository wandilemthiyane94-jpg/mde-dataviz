# Simplified rain-on-grid flood simulation of the April 2022 storm over Lamontville / uMlazi (Durban).
# Not a hydraulic engineering model: a cellular-automaton overland-flow scheme for visualisation.
#   Terrain : AWS Terrain Tiles (z14) averaged to 33 m cells, same box as the REM (build_rem.ps1)
#   Rain    : ERA5 reanalysis hourly precipitation at -29.95, 30.95 (Open-Meteo archive), 11 Apr 06:00 -> 12 Apr 18:00 SAST
#   Runoff  : 70% of rain becomes runoff (ground already saturated by rain on 10-11 April)
#   Terrain pits are filled first (priority-flood), as GIS flood tools do, so water can drain.
#   Flow    : each 10 s step, water moves to lower neighbours (4-connected) at a Manning velocity (n = 0.05),
#             limited so no cell gives away more than half the water-surface difference; the sea and the grid edge drain
#   Inflow  : rivers entering the box from upstream catchments (build_upstream_inflow.ps1) are added at their entry points
#   Missing : storm-water drains, canal walls and culverts are not represented at 33 m
# Outputs  : prototype/story/rem/sim_frames.png (12x12 sprite of 144 frames, 15 min apart; depth*60 in red channel, 0-4.25 m)
#            prototype/story/rem/sim.json (rain series, per-frame flooded area, depth at the camp)
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$cache = "$root\data\raw\terrain_tiles"; $out = "$root\prototype\story\rem"
$Z = 14; $W0 = 30.895; $E0 = 30.995; $N0 = -29.915; $S0 = -29.990
function TX([double]$lon) { [math]::Floor(($lon + 180) / 360 * [math]::Pow(2, $Z)) }
function TY([double]$lat) { $r = $lat * [math]::PI / 180; [math]::Floor((1 - [math]::Log([math]::Tan($r) + 1 / [math]::Cos($r)) / [math]::PI) / 2 * [math]::Pow(2, $Z)) }
$x0 = TX $W0; $x1 = TX $E0; $y0 = TY $N0; $y1 = TY $S0
# rainfall (cached)
$rainFile = "$root\data\raw\era5_rain_lamontville_2022-04.json"
if (-not (Test-Path $rainFile)) { Invoke-WebRequest "https://archive-api.open-meteo.com/v1/archive?latitude=-29.95&longitude=30.95&start_date=2022-04-10&end_date=2022-04-13&hourly=precipitation&timezone=Africa%2FJohannesburg&models=era5" -OutFile $rainFile -TimeoutSec 60 }
$rj = Get-Content $rainFile -Raw | ConvertFrom-Json
$startIdx = [array]::IndexOf($rj.hourly.time, '2022-04-11T06:00'); $hours = 36
$rain = @(0..($hours - 1) | ForEach-Object { [double]$rj.hourly.precipitation[$startIdx + $_] })
$times = @(0..($hours - 1) | ForEach-Object { $rj.hourly.time[$startIdx + $_] })
Add-Type -ReferencedAssemblies System.Drawing -Language CSharp -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class SIM {
  public static float[] Dem(string dir,int z,int x0,int x1,int y0,int y1,int f,out int W,out int H){
    int FW=(x1-x0+1)*256, FH=(y1-y0+1)*256; var e=new float[FW*FH];
    for(int tx=x0;tx<=x1;tx++) for(int ty=y0;ty<=y1;ty++){ var b=new Bitmap(dir+"\\"+z+"_"+tx+"_"+ty+".png"); var d=b.LockBits(new Rectangle(0,0,256,256),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); var a=new byte[d.Stride*256]; Marshal.Copy(d.Scan0,a,0,a.Length); int st=d.Stride; b.UnlockBits(d); b.Dispose();
      for(int y=0;y<256;y++) for(int x=0;x<256;x++){ int i=y*st+x*4; e[((ty-y0)*256+y)*FW+(tx-x0)*256+x]=a[i+2]*256f+a[i+1]+a[i]/256f-32768f; } }
    W=FW/f; H=FH/f; var o=new float[W*H];
    for(int y=0;y<H;y++) for(int x=0;x<W;x++){ double s=0; for(int dy=0;dy<f;dy++) for(int dx=0;dx<f;dx++) s+=e[(y*f+dy)*FW+x*f+dx]; o[y*W+x]=(float)(s/(f*f)); }
    return o; }
  // priority-flood: fill terrain pits (SRTM-class artefacts) so water can drain, as GIS flood tools do before routing
  public static float[] Fill(float[] e,int W,int H){ int N=W*H; var f=new float[N]; var done=new bool[N]; var heap=new System.Collections.Generic.SortedSet<long>();
    Func<float,int,long> key=(v,i)=>(((long)Math.Round((v+1000)*1000))<<21)+(long)(uint)i;
    for(int i=0;i<N;i++){ int x=i%W,y=i/W; if(x==0||y==0||x==W-1||y==H-1||e[i]<=0.3f){ f[i]=e[i]; done[i]=true; heap.Add(key(f[i],i)); } }
    int[] dx={1,-1,0,0,1,1,-1,-1}, dy={0,0,1,-1,1,-1,1,-1};
    while(heap.Count>0){ long k=heap.Min; heap.Remove(k); int i=(int)(k&((1L<<21)-1)); int x=i%W,y=i/W;
      for(int d=0;d<8;d++){ int xx=x+dx[d],yy=y+dy[d]; if(xx<0||yy<0||xx>=W||yy>=H) continue; int j=yy*W+xx; if(done[j]) continue; done[j]=true; f[j]=Math.Max(e[j],f[i]+0.001f); heap.Add(key(f[j],j)); } }
    return f; }  // rain[h] mm/h; returns frames (depth as byte) every frameMin minutes
  public static byte[][] Run(float[] z,int W,int H,double dx,double[] rain,double runoff,double dt,int frameMin,int campIdx,double[] campDepth,double[] floodKm2,int[] srcIdx,double[] srcQ){
    int N=W*H; var d=new double[N]; var nd=new double[N]; int stepsPerHour=(int)(3600/dt); int perFrame=(int)(frameMin*60/dt);
    int nFrames=rain.Length*60/frameMin; var frames=new byte[nFrames][]; int fi=0; double nMan=0.05;
    int[] ox={1,-1,0,0}, oy={0,0,1,-1};
    for(int h=0;h<rain.Length;h++){ double r=rain[h]/1000.0*runoff/stepsPerHour;
      for(int s=0;s<stepsPerHour;s++){
        for(int i=0;i<N;i++) d[i]+=r;
        for(int k=0;k<srcIdx.Length;k++) d[srcIdx[k]]+=srcQ[k*rain.Length+h]*dt/(dx*dx);   // upstream river inflow (m3/s -> depth)
        Array.Copy(d,nd,N);
        for(int y=0;y<H;y++) for(int x=0;x<W;x++){ int i=y*W+x; if(d[i]<=1e-5) continue; double si=z[i]+d[i];
          double[] q=new double[4]; double tot=0;
          for(int k=0;k<4;k++){ int xx=x+ox[k], yy=y+oy[k];
            if(xx<0||yy<0||xx>=W||yy>=H){ double v0=Math.Pow(d[i],2.0/3)*Math.Sqrt(0.01)/nMan; q[k]=Math.Min(d[i],v0*dt/dx*d[i]); tot+=q[k]; continue; }
            int j=yy*W+xx; double sj=z[j]+d[j], diff=si-sj; if(diff<=0) continue;
            double S=diff/dx, v=Math.Pow(d[i],2.0/3)*Math.Sqrt(S)/nMan; double qq=Math.Min(v*dt/dx*d[i], diff/2); q[k]=qq; tot+=qq; }
          if(tot<=0) continue; double sc=tot>d[i]?d[i]/tot:1;
          for(int k=0;k<4;k++){ if(q[k]<=0) continue; double m=q[k]*sc; nd[i]-=m; int xx=x+ox[k], yy=y+oy[k]; if(xx<0||yy<0||xx>=W||yy>=H) continue; nd[yy*W+xx]+=m; } }
        for(int i=0;i<N;i++){ d[i]=nd[i]<0?0:nd[i]; if(z[i]<=0.3) d[i]=0; }   // sea drains
        int step=h*stepsPerHour+s+1;
        if(step%perFrame==0 && fi<nFrames){ var fb=new byte[N]; int wet=0; for(int i=0;i<N;i++){ double dd=d[i]; fb[i]=(byte)Math.Min(255,dd*60); if(dd>0.1) wet++; } frames[fi]=fb; { double mx=0; int cxx=campIdx%W, cyy=campIdx/W; for(int a2=-1;a2<=1;a2++) for(int b2=-1;b2<=1;b2++){ int q2=(cyy+a2)*W+cxx+b2; if(q2>=0&&q2<N) mx=Math.Max(mx,d[q2]); } campDepth[fi]=mx; } floodKm2[fi]=wet*dx*dx/1e6; fi++; }
      } }
    return frames; }
  public static void Sprite(byte[][] frames,int W,int H,int cols,string path){
    int rows=(frames.Length+cols-1)/cols; var b=new Bitmap(W*cols,H*rows,PixelFormat.Format32bppArgb); var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb); var a=new byte[d.Stride*b.Height];
    for(int f=0;f<frames.Length;f++){ int ox=(f%cols)*W, oy=(f/cols)*H; for(int y=0;y<H;y++) for(int x=0;x<W;x++){ byte v=frames[f][y*W+x]; int i=(oy+y)*d.Stride+(ox+x)*4; a[i]=v; a[i+1]=v; a[i+2]=v; a[i+3]=255; } }
    Marshal.Copy(a,0,d.Scan0,a.Length); b.UnlockBits(d); b.Save(path,ImageFormat.Png); b.Dispose(); }
}
"@
$F = 4; $W = 0; $H = 0; $terrain = [SIM]::Dem($cache, $Z, $x0, $x1, $y0, $y1, $F, [ref]$W, [ref]$H); $terrain = [SIM]::Fill($terrain, $W, $H)
$pxm = 40075016.686 * [math]::Cos(29.95 * [math]::PI / 180) / ([math]::Pow(2, $Z) * 256) * $F
# camp cell (Lamontville riverside camp, from the site map)
$n = [math]::Pow(2, $Z); $fx = (30.9455 + 180) / 360 * $n; $r = -29.9537 * [math]::PI / 180; $fy = (1 - [math]::Log([math]::Tan($r) + 1 / [math]::Cos($r)) / [math]::PI) / 2 * $n
$cx = [int](($fx - $x0) * 256 / $F); $cy = [int](($fy - $y0) * 256 / $F); $campIdx = $cy * $W + $cx
$frameMin = 15; $nF = $hours * 60 / $frameMin; $campD = New-Object double[] $nF; $area = New-Object double[] $nF
# upstream inflow entry points (build_upstream_inflow.ps1), snapped to the lowest cell within 3 cells of the box edge
$srcI = @(); $srcQ = @()
$upF = "$root\data\raw\upstream_inflow.json"
if (Test-Path $upF) { $up = Get-Content $upF -Raw | ConvertFrom-Json
  foreach ($en in $up.entries) { $efx = ($en.lon + 180) / 360 * $n; $er = $en.lat * [math]::PI / 180; $efy = (1 - [math]::Log([math]::Tan($er) + 1 / [math]::Cos($er)) / [math]::PI) / 2 * $n
    $ex = [math]::Max(0, [math]::Min($W - 1, [int](($efx - $x0) * 256 / $F))); $ey = [math]::Max(0, [math]::Min($H - 1, [int](($efy - $y0) * 256 / $F)))
    $best = $ey * $W + $ex; for ($a = -3; $a -le 3; $a++) { for ($b = -3; $b -le 3; $b++) { $xx = $ex + $b; $yy = $ey + $a; if ($xx -ge 0 -and $yy -ge 0 -and $xx -lt $W -and $yy -lt $H -and $terrain[$yy * $W + $xx] -lt $terrain[$best]) { $best = $yy * $W + $xx } } }
    $srcI += $best; $srcQ += @($en.inflow_m3s | ForEach-Object { [double]$_ }) } }
$frames = [SIM]::Run($terrain, $W, $H, $pxm, [double[]]$rain, 0.7, 10.0, $frameMin, $campIdx, $campD, $area, [int[]]$srcI, [double[]]$srcQ)
[SIM]::Sprite($frames, $W, $H, 12, "$out\sim_frames.png")
$inv = [Globalization.CultureInfo]::InvariantCulture
$sim = [ordered]@{ grid = @($W, $H); cell_m = [math]::Round($pxm, 1); frame_minutes = $frameMin; frames = $nF; cols = 12; depth_scale = 60
  start = $times[0]; rain_mm_per_hour = $rain; rain_times = $times; camp_cell = @($cx, $cy)
  camp_depth_m = @($campD | ForEach-Object { [math]::Round($_, 3) }); flooded_km2 = @($area | ForEach-Object { [math]::Round($_, 3) })
  source = 'pits filled; ERA5 hourly precipitation via Open-Meteo; AWS Terrain Tiles z14; simplified rain-on-grid flow, runoff 0.7, Manning n 0.05; upstream river inflow from terrain-traced catchments (velocity 1.5 m/s, runoff 0.7)' }
($sim | ConvertTo-Json -Depth 4 -Compress) | Out-File "$out\sim.json" -Encoding utf8
"grid ${W}x${H} @ $([math]::Round($pxm,1)) m; rain total $([math]::Round(($rain|Measure-Object -Sum).Sum,1)) mm; peak camp depth $([math]::Round(($campD|Measure-Object -Maximum).Maximum,2)) m; peak flooded $([math]::Round(($area|Measure-Object -Maximum).Maximum,2)) km2"
