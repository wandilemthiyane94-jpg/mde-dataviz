# Fine-scale rain-on-grid flood simulation around Gwala Street, Lamontville (Durban).
# Same flow scheme as build_flood_sim.ps1, on much better terrain. Not a hydraulic engineering model.
#   Terrain : eThekwini Municipality 2 m contours (LiDAR-derived, Open GIS Data, Contours_2m feature service),
#             gridded to $Cell m by harmonic (Laplace) interpolation between contour lines
#   Rivers  : eThekwini Rivers feature service; natural / canal reaches are carved into the grid so channels below
#             the lowest enclosing contour can carry water (piped and culverted reaches are not carved)
#   Rain    : ERA5 hourly precipitation (same series and window as sim_<Suffix>.json), 70% runoff
#   Inflow  : upstream_inflow_<Suffix>.json: the uMlazi enters at the lowest west-edge cell, the northern stream
#             (entry lon 30.9447) at the lowest north-edge cell near that longitude; travel time to the box edge ignored
#   Missing : storm-water pipes, culvert capacity, canal walls narrower than a cell, buildings
# Outputs  : prototype/story/rem/fine_<Suffix>.json (camp depth series, flooded area), fine_<Suffix>_max.png (max depth
#            over hillshade), fine_<Suffix>_frames.png (sprite, depth*60 in grey), fine_dem.png (hillshade check)
param([string]$Suffix = '2025', [double]$Cell = 10, [double]$Dt = 2.0)
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out = "$root\prototype\story\rem"
$W0 = 30.915; $E0 = 30.975; $N0 = -29.920; $S0 = -29.980
$kx = 111320 * [math]::Cos(29.95 * [math]::PI / 180); $ky = 110574
$GW = [int][math]::Ceiling(($E0 - $W0) * $kx / $Cell); $GH = [int][math]::Ceiling(($N0 - $S0) * $ky / $Cell)
$prev = Get-Content "$out\sim_$Suffix.json" -Raw | ConvertFrom-Json
$rain = [double[]]@($prev.rain_mm_per_hour | ForEach-Object { [double]$_ }); $start = $prev.start
$up = Get-Content "$root\data\raw\upstream_inflow_$Suffix.json" -Raw | ConvertFrom-Json
Add-Type -ReferencedAssemblies System.Drawing -Language CSharp -TypeDefinition @"
using System; using System.Collections.Generic; using System.Text.RegularExpressions; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class FINE {
  static Regex rxF=new Regex("\\{\\s*\"type\"\\s*:\\s*\"Feature\""), rxP=new Regex("\\[\\s*(-?\\d+\\.?\\d*)\\s*,\\s*(-?\\d+\\.?\\d*)\\s*\\]");
  // contour lines -> fixed cells
  public static float[] Dem(string json,int W,int H,double w0,double n0,double kx,double ky,double cell,out int fixedCount){
    var sum=new double[W*H]; var cnt=new int[W*H]; var parts=rxF.Split(json); var rxE=new Regex("\"ELEVATION\"\\s*:\\s*(-?\\d+\\.?\\d*)");
    foreach(var p in parts){ var me=rxE.Match(p); if(!me.Success) continue; double el=double.Parse(me.Groups[1].Value,System.Globalization.CultureInfo.InvariantCulture);
      double px=double.NaN,py=double.NaN; foreach(Match m in rxP.Matches(p)){ double x=(double.Parse(m.Groups[1].Value,System.Globalization.CultureInfo.InvariantCulture)-w0)*kx/cell, y=(n0-double.Parse(m.Groups[2].Value,System.Globalization.CultureInfo.InvariantCulture))*ky/cell;
        if(!double.IsNaN(px)){ double L=Math.Sqrt((x-px)*(x-px)+(y-py)*(y-py)); if(L<6){ int n=(int)Math.Ceiling(L*2)+1; for(int k=0;k<=n;k++){ double t=(double)k/n; int cx=(int)(px+(x-px)*t), cy=(int)(py+(y-py)*t); if(cx<0||cy<0||cx>=W||cy>=H) continue; sum[cy*W+cx]+=el; cnt[cy*W+cx]++; } } }
        px=x; py=y; } }
    var z=new float[W*H]; var fix=new bool[W*H]; fixedCount=0;
    for(int i=0;i<W*H;i++) if(cnt[i]>0){ z[i]=(float)(sum[i]/cnt[i]); fix[i]=true; fixedCount++; }
    // seed unknown cells from nearest fixed cell (BFS), then relax to a harmonic surface
    var q=new Queue<int>(); var seen=new bool[W*H]; for(int i=0;i<W*H;i++) if(fix[i]){ q.Enqueue(i); seen[i]=true; }
    while(q.Count>0){ int i=q.Dequeue(), x=i%W, y=i/W; int[] nb={i-1,i+1,i-W,i+W}; bool[] ok={x>0,x<W-1,y>0,y<H-1}; for(int k=0;k<4;k++){ if(!ok[k]) continue; int j=nb[k]; if(seen[j]) continue; seen[j]=true; z[j]=z[i]; q.Enqueue(j); } }
    for(int it=0;it<2500;it++){ for(int y=0;y<H;y++) for(int x=0;x<W;x++){ int i=y*W+x; if(fix[i]) continue; double s=0; int n=0; if(x>0){s+=z[i-1];n++;} if(x<W-1){s+=z[i+1];n++;} if(y>0){s+=z[i-W];n++;} if(y<H-1){s+=z[i+W];n++;} z[i]=(float)(z[i]+1.9*(s/n-z[i])); } }
    return z; }
  // carve river reaches into the surface
  public static int Carve(string json,float[] z,int W,int H,double w0,double n0,double kx,double ky,double cell){
    var parts=rxF.Split(json); int carved=0; var mark=new bool[W*H];
    foreach(var p in parts){ if(p.IndexOf("\"STATUS\"")<0) continue; if(p.Contains("\"Piped\"")||p.Contains("\"Culvert\"")) continue; bool major=p.Contains("\"Major River\"")||p.Contains("uMlazi"); double depth=major?2.5:1.0;
      double px=double.NaN,py=double.NaN; foreach(Match m in rxP.Matches(p)){ double x=(double.Parse(m.Groups[1].Value,System.Globalization.CultureInfo.InvariantCulture)-w0)*kx/cell, y=(n0-double.Parse(m.Groups[2].Value,System.Globalization.CultureInfo.InvariantCulture))*ky/cell;
        if(!double.IsNaN(px)){ double L=Math.Sqrt((x-px)*(x-px)+(y-py)*(y-py)); if(L<20){ int n=(int)Math.Ceiling(L*2)+1; for(int k=0;k<=n;k++){ double t=(double)k/n; int cx=(int)(px+(x-px)*t), cy=(int)(py+(y-py)*t); if(cx<1||cy<1||cx>=W-1||cy>=H-1) continue; int i=cy*W+cx; if(mark[i]) continue; mark[i]=true;
          float mn=z[i]; for(int a=-1;a<=1;a++) for(int b=-1;b<=1;b++) mn=Math.Min(mn,z[i+a*W+b]); z[i]=(float)(mn-depth); carved++; } } }
        px=x; py=y; } }
    return carved; }
  public static float[] Fill(float[] e,int W,int H){ int N=W*H; var f=new float[N]; var done=new bool[N]; var heap=new SortedSet<long>();
    Func<float,int,long> key=(v,i)=>(((long)Math.Round((v+1000)*1000))<<21)+(long)(uint)i;
    for(int i=0;i<N;i++){ int x=i%W,y=i/W; if(x==0||y==0||x==W-1||y==H-1){ f[i]=e[i]; done[i]=true; heap.Add(key(f[i],i)); } }
    int[] dx={1,-1,0,0,1,1,-1,-1}, dy={0,0,1,-1,1,-1,1,-1};
    while(heap.Count>0){ long k=heap.Min; heap.Remove(k); int i=(int)(k&((1L<<21)-1)); int x=i%W,y=i/W;
      for(int d=0;d<8;d++){ int xx=x+dx[d],yy=y+dy[d]; if(xx<0||yy<0||xx>=W||yy>=H) continue; int j=yy*W+xx; if(done[j]) continue; done[j]=true; f[j]=Math.Max(e[j],f[i]+0.0005f); heap.Add(key(f[j],j)); } }
    return f; }
  public static byte[][] Run(float[] z,int W,int H,double dx,double[] rain,double runoff,double dt,int frameMin,int[] probe,double[] probeDepth,double[] floodKm2,double[] maxD,int[] srcIdx,double[] srcQ,int srcLen){
    int N=W*H; var d=new double[N]; var nd=new double[N]; int stepsPerHour=(int)(3600/dt); int perFrame=(int)(frameMin*60/dt);
    int nFrames=rain.Length*60/frameMin; var frames=new byte[nFrames][]; int fi=0; double nMan=0.05; int np=probe.Length/3;
    int[] ox={1,-1,0,0}, oy={0,0,1,-1}; var q=new double[4];
    for(int h=0;h<rain.Length;h++){ double r=rain[h]/1000.0*runoff/stepsPerHour;
      for(int s=0;s<stepsPerHour;s++){
        for(int i=0;i<N;i++) d[i]+=r;
        for(int k=0;k<srcIdx.Length;k++){ int hh=Math.Min(h,srcLen-1); d[srcIdx[k]]+=srcQ[k*srcLen+hh]*dt/(dx*dx); }
        Array.Copy(d,nd,N);
        for(int y=0;y<H;y++) for(int x=0;x<W;x++){ int i=y*W+x; double di=d[i]; if(di<=1e-5) continue; double si=z[i]+di, tot=0, p23=Math.Pow(di,2.0/3)/nMan;
          for(int k=0;k<4;k++){ q[k]=0; int xx=x+ox[k], yy=y+oy[k];
            if(xx<0||yy<0||xx>=W||yy>=H){ double v0=p23*0.1; q[k]=Math.Min(di,v0*dt/dx*di); tot+=q[k]; continue; }
            int j=yy*W+xx; double diff=si-(z[j]+d[j]); if(diff<=0) continue;
            double v=p23*Math.Sqrt(diff/dx); double qq=Math.Min(v*dt/dx*di, diff/2); q[k]=qq; tot+=qq; }
          if(tot<=0) continue; double sc=tot>di?di/tot:1;
          for(int k=0;k<4;k++){ if(q[k]<=0) continue; double m=q[k]*sc; nd[i]-=m; int xx=x+ox[k], yy=y+oy[k]; if(xx<0||yy<0||xx>=W||yy>=H) continue; nd[yy*W+xx]+=m; } }
        for(int i=0;i<N;i++){ double v=nd[i]<0?0:nd[i]; d[i]=v; if(v>maxD[i]) maxD[i]=v; }
        int step=h*stepsPerHour+s+1;
        if(step%perFrame==0 && fi<nFrames){ var fb=new byte[N]; int wet=0; for(int i=0;i<N;i++){ fb[i]=(byte)Math.Min(255,d[i]*60); if(d[i]>0.15) wet++; } frames[fi]=fb;
          for(int p=0;p<np;p++){ int cx=probe[p*3], cy=probe[p*3+1], rad=probe[p*3+2]; double mx=0; for(int a=-rad;a<=rad;a++) for(int b=-rad;b<=rad;b++){ int xx=cx+b, yy=cy+a; if(xx<0||yy<0||xx>=W||yy>=H) continue; mx=Math.Max(mx,d[yy*W+xx]); } probeDepth[p*nFrames+fi]=mx; }
          floodKm2[fi]=wet*dx*dx/1e6; fi++; } } }
    return frames; }
  static double[] Shade(float[] z,int W,int H,double dx){ var s=new double[W*H]; for(int y=1;y<H-1;y++) for(int x=1;x<W-1;x++){ int i=y*W+x; double gx=(z[i+1]-z[i-1])/(2*dx), gy=(z[i+W]-z[i-W])/(2*dx); double nx=-gx, ny=-gy, nz=1, L=Math.Sqrt(nx*nx+ny*ny+1); s[i]=Math.Max(0,(nx*-0.5+ny*-0.5+nz*0.7)/L/1.0); } return s; }
  public static void MaxPng(float[] z,double[] md,int W,int H,double dx,string path){ var sh=Shade(z,W,H,dx); var b=new Bitmap(W,H,PixelFormat.Format32bppArgb);
    float zmin=float.MaxValue,zmax=float.MinValue; foreach(var v in z){ zmin=Math.Min(zmin,v); zmax=Math.Max(zmax,v); }
    for(int y=0;y<H;y++) for(int x=0;x<W;x++){ int i=y*W+x; double t=(z[i]-zmin)/(zmax-zmin+1e-6), s=0.55+0.45*sh[i]; int r=(int)((215-40*t)*s), g=(int)((205-30*t)*s), bl=(int)((180-30*t)*s);
      double dd=md[i]; if(dd>0.15){ double a=Math.Min(1,0.35+dd/2.5); r=(int)(r*(1-a)+30*a); g=(int)(g*(1-a)+(110-Math.Min(70,dd*25))*a); bl=(int)(bl*(1-a)+(190-Math.Min(60,dd*20))*a); }
      b.SetPixel(x,y,Color.FromArgb(255,Math.Max(0,Math.Min(255,r)),Math.Max(0,Math.Min(255,g)),Math.Max(0,Math.Min(255,bl)))); }
    b.Save(path,ImageFormat.Png); b.Dispose(); }
  public static void Sprite(byte[][] frames,int W,int H,int cols,string path){
    int rows=(frames.Length+cols-1)/cols; var b=new Bitmap(W*cols,H*rows,PixelFormat.Format32bppArgb); var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb); var a=new byte[d.Stride*b.Height];
    for(int f=0;f<frames.Length;f++){ int ox=(f%cols)*W, oy=(f/cols)*H; for(int y=0;y<H;y++) for(int x=0;x<W;x++){ byte v=frames[f][y*W+x]; int i=(oy+y)*d.Stride+(ox+x)*4; a[i]=v; a[i+1]=v; a[i+2]=v; a[i+3]=255; } }
    Marshal.Copy(a,0,d.Scan0,a.Length); b.UnlockBits(d); b.Save(path,ImageFormat.Png); b.Dispose(); }
}
"@
$cj = [IO.File]::ReadAllText("$root\data\raw\ethekwini_contours_2m_lamontville.geojson"); $fixed = 0
$z = [FINE]::Dem($cj, $GW, $GH, $W0, $N0, $kx, $ky, $Cell, [ref]$fixed)
$rj = [IO.File]::ReadAllText("$root\data\raw\ethekwini_rivers_lamontville.geojson")
$carved = [FINE]::Carve($rj, $z, $GW, $GH, $W0, $N0, $kx, $ky, $Cell)
$z = [FINE]::Fill($z, $GW, $GH)
function Cell([double]$lon, [double]$lat) { @([int](($lon - $W0) * $kx / $Cell), [int](($N0 - $lat) * $ky / $Cell)) }
# inflow: uMlazi at the lowest west-edge cell; northern stream at the lowest north-edge cell within 800 m of lon 30.9447
$srcI = @(); $srcQ = @(); $srcLen = $up.entries[0].inflow_m3s.Count
$e1 = $up.entries | Where-Object { [math]::Abs($_.lat - (-29.93976)) -lt 0.001 -and [math]::Abs($_.lon - 30.8939) -lt 0.001 } | Select-Object -First 1
$best = 0; for ($y = 1; $y -lt $GH - 1; $y++) { if ($z[$y * $GW] -lt $z[$best]) { $best = $y * $GW } }; $srcI += $best; $srcQ += @($e1.inflow_m3s | ForEach-Object { [double]$_ })
$e2 = $up.entries | Where-Object { [math]::Abs($_.lon - 30.94471) -lt 0.001 } | Select-Object -First 1
if ($e2) { $c = Cell 30.94471 $N0; $r80 = [int](800 / $Cell); $best = [math]::Max(1, $c[0] - $r80); for ($x = [math]::Max(1, $c[0] - $r80); $x -le [math]::Min($GW - 2, $c[0] + $r80); $x++) { if ($z[$x] -lt $z[$best]) { $best = $x } }; $srcI += $best; $srcQ += @($e2.inflow_m3s | ForEach-Object { [double]$_ }) }
# probes: Lamontville riverside camp and the larger Gwala Street camp (Hollie's pins), max depth within ~30 m
$p1 = Cell 30.9455 -29.9537; $p2 = Cell 30.9462 -29.953; $rad = [int][math]::Max(1, [math]::Round(30 / $Cell))
$probe = [int[]]@($p1[0], $p1[1], $rad, $p2[0], $p2[1], $rad)
$frameMin = 15; $nF = $rain.Length * 60 / $frameMin
$pd = New-Object double[] (2 * $nF); $area = New-Object double[] $nF; $maxD = New-Object double[] ($GW * $GH)
$t0 = Get-Date
$frames = [FINE]::Run($z, $GW, $GH, $Cell, $rain, 0.7, $Dt, $frameMin, $probe, $pd, $area, $maxD, [int[]]$srcI, [double[]]$srcQ, $srcLen)
$secs = [math]::Round(((Get-Date) - $t0).TotalSeconds)
[FINE]::MaxPng($z, $maxD, $GW, $GH, $Cell, "$out\fine_${Suffix}_max.png")
[FINE]::Sprite($frames, $GW, $GH, 8, "$out\fine_${Suffix}_frames.png")
$campElev = $z[$p1[1] * $GW + $p1[0]]; $gwElev = $z[$p2[1] * $GW + $p2[0]]
$s1 = @(0..($nF - 1) | ForEach-Object { [math]::Round($pd[$_], 2) }); $s2 = @(0..($nF - 1) | ForEach-Object { [math]::Round($pd[$nF + $_], 2) })
$res = [ordered]@{ suffix = $Suffix; grid = @($GW, $GH); cell_m = $Cell; box = @($W0, $S0, $E0, $N0); start = $start; frame_minutes = $frameMin; frames = $nF; cols = 8; depth_scale = 60
  rain_mm_per_hour = $rain; contour_cells = $fixed; carved_cells = $carved; inflow_cells = $srcI
  lamontville_camp = [ordered]@{ lonlat = @(30.9455, -29.9537); ground_m = [math]::Round($campElev, 1); depth_m = $s1; peak_m = ($s1 | Measure-Object -Maximum).Maximum }
  gwala_camp = [ordered]@{ lonlat = @(30.9462, -29.953); ground_m = [math]::Round($gwElev, 1); depth_m = $s2; peak_m = ($s2 | Measure-Object -Maximum).Maximum }
  flooded_km2 = @($area | ForEach-Object { [math]::Round($_, 3) })
  source = "eThekwini 2 m contours (LiDAR-derived) gridded to $Cell m; eThekwini rivers carved; ERA5 hourly rain, runoff 0.7; upstream inflow from terrain-traced catchments; Manning n 0.05; dt $Dt s" }
($res | ConvertTo-Json -Depth 5 -Compress) | Out-File "$out\fine_$Suffix.json" -Encoding utf8
"grid ${GW}x${GH} @ $Cell m | contour cells $fixed | carved $carved | run ${secs}s | camp ground $([math]::Round($campElev,1)) m, peak depth $($res.lamontville_camp.peak_m) m | Gwala camp ground $([math]::Round($gwElev,1)) m, peak $($res.gwala_camp.peak_m) m | peak flooded $([math]::Round(($area|Measure-Object -Maximum).Maximum,2)) km2"
