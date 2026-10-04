# Relative Elevation Model (height above river) for the Lamontville / uMlazi area, following the IDW method
# (Dan Coe's REM tutorial; OpenTopography RiverREM does the same in Python):
#   1. DEM: AWS Terrain Tiles (Terrarium encoding, zoom 14; in South Africa the source is ~30 m SRTM/Copernicus-class data)
#   2. River cells: channels traced from the terrain (priority-flood, D8 flow accumulation, catchment >= ~0.2 km2), plus pixels that JRC Global Surface Water saw under water at least half the time (occurrence >= 50%; data/raw/durban_water_raw.png)
#   3. River surface (each river sample snapped to the lowest DEM cell within ~40 m): inverse-distance-weighted interpolation of the DEM height at river cells (coarse grid, upsampled)
#   4. REM = DEM - river surface (metres above the nearest river), plus a hillshade from the DEM
# Outputs: prototype/story/rem/rem.png (R = REM in 0.1 m steps, 0-25.5 m; G,B unused), rem/hill.png, rem/meta.json
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$cache = "$root\data\raw\terrain_tiles"; $out = "$root\prototype\story\rem"; New-Item -ItemType Directory -Force $cache, $out | Out-Null
$Z = 14; $W0 = 30.895; $E0 = 30.995; $N0 = -29.915; $S0 = -29.990      # study box around the Lamontville riverside camp (30.9455, -29.9537)
function TX([double]$lon) { [math]::Floor(($lon + 180) / 360 * [math]::Pow(2, $Z)) }
function TY([double]$lat) { $r = $lat * [math]::PI / 180; [math]::Floor((1 - [math]::Log([math]::Tan($r) + 1 / [math]::Cos($r)) / [math]::PI) / 2 * [math]::Pow(2, $Z)) }
$x0 = TX $W0; $x1 = TX $E0; $y0 = TY $N0; $y1 = TY $S0
foreach ($x in $x0..$x1) { foreach ($y in $y0..$y1) { $f = "$cache\${Z}_${x}_${y}.png"; if (-not (Test-Path $f)) { Invoke-WebRequest "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/$Z/$x/$y.png" -OutFile $f -TimeoutSec 60 } } }
Add-Type -ReferencedAssemblies System.Drawing -Language CSharp -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Collections.Generic;
public static class REM {
  static byte[] Px(Bitmap b, out int stride){ var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); stride=d.Stride; var a=new byte[d.Stride*b.Height]; Marshal.Copy(d.Scan0,a,0,a.Length); b.UnlockBits(d); return a; }
  public static float[] Mosaic(string dir,int z,int x0,int x1,int y0,int y1,out int W,out int H){
    W=(x1-x0+1)*256; H=(y1-y0+1)*256; var e=new float[W*H];
    for(int tx=x0;tx<=x1;tx++) for(int ty=y0;ty<=y1;ty++){ var b=new Bitmap(dir+"\\"+z+"_"+tx+"_"+ty+".png"); int st; var a=Px(b,out st); b.Dispose();
      for(int y=0;y<256;y++) for(int x=0;x<256;x++){ int i=y*st+x*4; e[((ty-y0)*256+y)*W+(tx-x0)*256+x]=a[i+2]*256f+a[i+1]+a[i]/256f-32768f; } }
    return e; }
  // water mask from the JRC mosaic (Web Mercator, given bounds); grid pixel -> lon/lat via tile math
  public static bool[] Water(string jrc,int W,int H,int z,int x0,int y0,double jw,double je,double jn,double js,int thr){
    var b=new Bitmap(jrc); int st; var a=Px(b,out st); int jW=b.Width,jH=b.Height; b.Dispose();
    double n=Math.Pow(2,z); Func<double,double> my=lat=>Math.Log(Math.Tan(Math.PI/4+lat*Math.PI/360));
    double mN=my(jn), mS=my(js); var m=new bool[W*H];
    for(int y=0;y<H;y++){ double ty=y0+(y+.5)/256.0; double lat=Math.Atan(Math.Sinh(Math.PI*(1-2*ty/n)))*180/Math.PI; int jy=(int)((mN-my(lat))/(mN-mS)*jH); if(jy<0||jy>=jH) continue;
      for(int x=0;x<W;x++){ double lon=(x0+(x+.5)/256.0)/n*360-180; int jx=(int)((lon-jw)/(je-jw)*jW); if(jx<0||jx>=jW) continue; int i=jy*st+jx*4; m[y*W+x]= a[i+3]>100 && a[i]>=thr; } }
    return m; }
  // rivers from the terrain: priority-flood sink filling, D8 flow directions, flow accumulation; river = catchment >= minCells
  public static bool[] Rivers(float[] e,int W,int H,int minCells){
    int N=W*H; var f=new float[N]; var done=new bool[N]; var heap=new SortedSet<long>(); Func<float,int,long> key=(v,i)=>(((long)Math.Round((v+1000)*1000))<<21)+(long)(uint)i;
    for(int i=0;i<N;i++){ int x=i%W,y=i/W; if(x==0||y==0||x==W-1||y==H-1){ f[i]=e[i]; done[i]=true; heap.Add(key(f[i],i)); } }
    int[] dx={1,1,0,-1,-1,-1,0,1}, dy={0,1,1,1,0,-1,-1,-1}; var order=new int[N]; int oc=0;
    while(heap.Count>0){ long k=heap.Min; heap.Remove(k); int i=(int)(k&((1L<<21)-1)); order[oc++]=i; int x=i%W,y=i/W;
      for(int d=0;d<8;d++){ int xx=x+dx[d],yy=y+dy[d]; if(xx<0||yy<0||xx>=W||yy>=H) continue; int j=yy*W+xx; if(done[j]) continue; done[j]=true; f[j]=Math.Max(e[j],f[i]+0.0001f); heap.Add(key(f[j],j)); } }
    // flow direction: steepest descent on the filled surface (ties broken towards lower raw DEM)
    var to=new int[N]; for(int i=0;i<N;i++){ int x=i%W,y=i/W; int best=-1; double bs=0; for(int d=0;d<8;d++){ int xx=x+dx[d],yy=y+dy[d]; if(xx<0||yy<0||xx>=W||yy>=H) continue; int j=yy*W+xx; double s=(f[i]-f[j])/((d%2==1)?1.4142:1.0); if(s>bs){bs=s;best=j;} } to[i]=best; }
    var acc=new int[N]; for(int i=0;i<N;i++) acc[i]=1;
    for(int k2=oc-1;k2>=0;k2--){ int i=order[k2]; if(to[i]>=0) acc[to[i]]+=acc[i]; }
    var r=new bool[N]; for(int i=0;i<N;i++) r[i]=acc[i]>=minCells; return r; }  public static float[] Surface(float[] e,bool[] w,int W,int H,int cell){
    var sx=new List<int>(); var sy=new List<int>(); var sv=new List<float>();
    for(int y=0;y<H;y+=2) for(int x=0;x<W;x+=2) if(w[y*W+x]){ float mn=e[y*W+x]; for(int dy=-5;dy<=5;dy++){ int yy=y+dy; if(yy<0||yy>=H) continue; for(int dx=-5;dx<=5;dx++){ int xx=x+dx; if(xx<0||xx>=W) continue; mn=Math.Min(mn,e[yy*W+xx]); } } sx.Add(x); sy.Add(y); sv.Add(mn); } // snap to the channel bottom within ~40 m: JRC 30 m water pixels often fall on the bank
    int gw=W/cell+1, gh=H/cell+1; var g=new float[gw*gh];
    for(int gy=0;gy<gh;gy++) for(int gx=0;gx<gw;gx++){ double px=gx*cell,py=gy*cell; // 12 nearest, power 2
      var bd=new double[12]; var bv=new double[12]; for(int k=0;k<12;k++) bd[k]=1e18;
      for(int s=0;s<sx.Count;s++){ double dx=sx[s]-px,dy=sy[s]-py,d=dx*dx+dy*dy; if(d<bd[11]){ int k=11; while(k>0&&bd[k-1]>d){bd[k]=bd[k-1];bv[k]=bv[k-1];k--;} bd[k]=d; bv[k]=sv[s]; } }
      double num=0,den=0; for(int k=0;k<12;k++){ double wt=1.0/Math.Max(1,bd[k]); num+=wt*bv[k]; den+=wt; } g[gy*gw+gx]=(float)(num/den); }
    var r=new float[W*H];
    for(int y=0;y<H;y++) for(int x=0;x<W;x++){ double fx=(double)x/cell, fy=(double)y/cell; int ix=(int)fx, iy=(int)fy; double ax=fx-ix, ay=fy-iy; int ix1=Math.Min(ix+1,gw-1), iy1=Math.Min(iy+1,gh-1);
      r[y*W+x]=(float)((g[iy*gw+ix]*(1-ax)+g[iy*gw+ix1]*ax)*(1-ay)+(g[iy1*gw+ix]*(1-ax)+g[iy1*gw+ix1]*ax)*ay); }
    return r; }
  public static void Save(float[] e,float[] s,int W,int H,double pxm,string remPath,string hillPath){
    var rb=new Bitmap(W,H,PixelFormat.Format32bppArgb); var hb=new Bitmap(W,H,PixelFormat.Format32bppArgb);
    var rd=rb.LockBits(new Rectangle(0,0,W,H),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb); var hd=hb.LockBits(new Rectangle(0,0,W,H),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
    var ra=new byte[rd.Stride*H]; var ha=new byte[hd.Stride*H]; double az=315*Math.PI/180, alt=45*Math.PI/180;
    for(int y=0;y<H;y++) for(int x=0;x<W;x++){ int i=y*rd.Stride+x*4; double v=Math.Max(0,Math.Min(25.5,e[y*W+x]-s[y*W+x])); byte q=(byte)Math.Round(v*10); ra[i]=q; ra[i+1]=q; ra[i+2]=q; ra[i+3]=255;
      int xl=Math.Max(0,x-1),xr=Math.Min(W-1,x+1),yu=Math.Max(0,y-1),yd=Math.Min(H-1,y+1);
      double dzdx=(e[y*W+xr]-e[y*W+xl])/(2*pxm)*2.5, dzdy=(e[yd*W+x]-e[yu*W+x])/(2*pxm)*2.5; double slope=Math.Atan(Math.Sqrt(dzdx*dzdx+dzdy*dzdy)), aspect=Math.Atan2(dzdy,-dzdx);
      double hs=Math.Cos(alt)*Math.Cos(slope)+Math.Sin(alt)*Math.Sin(slope)*Math.Cos(az-aspect); byte h=(byte)Math.Max(0,Math.Min(255,hs*255)); int j=y*hd.Stride+x*4; ha[j]=h; ha[j+1]=h; ha[j+2]=h; ha[j+3]=255; }
    Marshal.Copy(ra,0,rd.Scan0,ra.Length); Marshal.Copy(ha,0,hd.Scan0,ha.Length); rb.UnlockBits(rd); hb.UnlockBits(hd); rb.Save(remPath,ImageFormat.Png); hb.Save(hillPath,ImageFormat.Png); rb.Dispose(); hb.Dispose(); }
}
"@
$W = 0; $H = 0; $e = [REM]::Mosaic($cache, $Z, $x0, $x1, $y0, $y1, [ref]$W, [ref]$H)
$wm = [REM]::Water("$root\data\raw\durban_water_raw.png", $W, $H, $Z, $x0, $y0, 30.673828125, 31.201171875, -29.45873118535533, -30.145127183376118, 128)
$rv = [REM]::Rivers($e, $W, $H, 3000); for ($i = 0; $i -lt $wm.Length; $i++) { if ($rv[$i]) { $wm[$i] = $true } }   # ~3000 cells x 68.6 m2 = catchment >= ~0.2 km2
$nw = @($wm | Where-Object { $_ }).Count
$s = [REM]::Surface($e, $wm, $W, $H, 16)
$pxm = 40075016.686 * [math]::Cos(29.95 * [math]::PI / 180) / ([math]::Pow(2, $Z) * 256)
[REM]::Save($e, $s, $W, $H, $pxm, "$out\rem.png", "$out\hill.png")
$n = [math]::Pow(2, $Z)
function Lon($tx) { $tx / $n * 360 - 180 }; function Lat($ty) { [math]::Atan([math]::Sinh([math]::PI * (1 - 2 * $ty / $n))) * 180 / [math]::PI }
$meta = [ordered]@{ west = Lon $x0; east = Lon ($x1 + 1); north = Lat $y0; south = Lat ($y1 + 1); width = $W; height = $H; pixel_m = [math]::Round($pxm, 2); river_cells = $nw
  method = 'REM by IDW: DEM (AWS Terrain Tiles, Terrarium z14) minus a river surface interpolated from DEM heights at JRC Global Surface Water cells' }
($meta | ConvertTo-Json) | Out-File "$out\meta.json" -Encoding utf8
"grid ${W}x${H}, $([math]::Round($pxm,1)) m/px, river cells $nw"
