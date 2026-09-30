# Sentinel-1 flood extent for eThekwini: before/after change detection on radar backscatter.
# Source: Sentinel-1 RTC (radiometrically terrain corrected, gamma0, 10 m) from Microsoft Planetary Computer,
#         cropped to the story bounds (30.74-31.14 E, 29.53-30.06 S) by its data API, in Web Mercator.
# Method: VV backscatter; smooth 5x5 mean (speckle); water = VV < -16 dB. New flood water = water AFTER and not BEFORE,
#         with a drop of at least 3 dB. Permanent water = water in both. Same orbit (relative orbit 43) for each pair.
# Outputs: data/raw/s1/*.png (8-bit VV, 0-0.1 linear), prototype/story/s1/*.png (display + masks), data/s1_flood_summary.json
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$raw = "$root\data\raw\s1"; $web = "$root\prototype\story\s1"; New-Item -ItemType Directory -Force $raw, $web | Out-Null
$W = 1000; $H = 1500
$pairs = [ordered]@{
  'apr2022' = @{ before = 'S1A_IW_GRDH_1SDV_20220405T163741_20220405T163806_042640_05165E_rtc'; after = 'S1A_IW_GRDH_1SDV_20220417T163742_20220417T163807_042815_051C3F_rtc'; label = 'April 2022 floods (peak 11-12 Apr)'; b = '2022-04-05'; a = '2022-04-17' }
  'feb2025' = @{ before = 'S1A_IW_GRDH_1SDV_20250224T163745_20250224T163810_058040_072A69_rtc'; after = 'S1A_IW_GRDH_1SDV_20250308T163745_20250308T163810_058215_07318D_rtc'; label = 'February 2025 Lamontville flood (c. 25-26 Feb)'; b = '2025-02-24'; a = '2025-03-08' } }
function Get-VV($id) { $f = "$raw\$id.png"
  if (-not (Test-Path $f)) { $u = "https://planetarycomputer.microsoft.com/api/data/v1/item/bbox/30.74,-30.06,31.14,-29.53/${W}x${H}.png?collection=sentinel-1-rtc&item=$id&assets=vv&rescale=0,0.1&dst_crs=epsg:3857&nodata=0"
    Invoke-WebRequest $u -OutFile $f -TimeoutSec 300 }
  $f }
Add-Type -ReferencedAssemblies System.Drawing -Language CSharp -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class S1 {
  public static float[] Load(string path, out int w, out int h) {
    var bmp = new Bitmap(path); w = bmp.Width; h = bmp.Height;
    var d = bmp.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    var buf = new byte[d.Stride*h]; Marshal.Copy(d.Scan0, buf, 0, buf.Length); bmp.UnlockBits(d); bmp.Dispose();
    var v = new float[w*h];
    for (int y=0;y<h;y++) for (int x=0;x<w;x++){ int i=y*d.Stride+x*4; v[y*w+x] = (buf[i+3]<128 || buf[i]==0) ? float.NaN : buf[i]/255f*0.1f; }
    return v; }
  public static float[] SmoothDb(float[] v, int w, int h, int r) {
    var o = new float[w*h];
    for (int y=0;y<h;y++) for (int x=0;x<w;x++){ double s=0; int n=0;
      for (int dy=-r;dy<=r;dy++){ int yy=y+dy; if(yy<0||yy>=h) continue; for(int dx=-r;dx<=r;dx++){ int xx=x+dx; if(xx<0||xx>=w) continue; float q=v[yy*w+xx]; if(float.IsNaN(q)) continue; s+=q; n++; } }
      o[y*w+x] = n==0 ? float.NaN : (float)(10*Math.Log10(Math.Max(1e-4, s/n))); }
    return o; }
  // classes: 0 none/nodata, 1 permanent water, 2 new flood water
  // exclusion mask from the recoloured JRC GSW image: permanent water / sea (navy #163047), grown by 1 GSW pixel (~30 m)
  public static bool[] GswPermanent(string path, int w, int h, double ax, double bx, double ay, double by) {
    var bmp=new Bitmap(path); int gw=bmp.Width, gh=bmp.Height; var d=bmp.LockBits(new Rectangle(0,0,gw,gh),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
    var buf=new byte[d.Stride*gh]; Marshal.Copy(d.Scan0,buf,0,buf.Length); bmp.UnlockBits(d); bmp.Dispose();
    var perm=new bool[gw*gh]; for(int y=0;y<gh;y++) for(int x=0;x<gw;x++){ int i=y*d.Stride+x*4; perm[y*gw+x]= buf[i+3]>0 && buf[i]<120; }
    var m=new bool[w*h];
    for(int y=0;y<h;y++){ int gy=(int)(ay*y+by); for(int x=0;x<w;x++){ int gx=(int)(ax*x+bx); bool e=false;
      for(int dy=-1;dy<=1&&!e;dy++) for(int dx=-1;dx<=1&&!e;dx++){ int xx=gx+dx, yy=gy+dy; if(xx>=0&&yy>=0&&xx<gw&&yy<gh&&perm[yy*gw+xx]) e=true; }
      m[y*w+x]=e; } }
    return m; }
  public static byte[] Classify(float[] b, float[] a, bool[] excl, float thr, float drop, out int nNew, out int nPerm) {
    var c = new byte[a.Length]; nNew=0; nPerm=0;
    for (int i=0;i<a.Length;i++){ if(float.IsNaN(a[i])||float.IsNaN(b[i])) continue; if(excl[i]){ c[i]=1; continue; }
      bool wa=a[i]<thr, wb=b[i]<thr;
      if (wa&&wb){ c[i]=1; nPerm++; } else if (wa && (a[i]-b[i])<=-drop){ c[i]=2; nNew++; } }
    return c; }
  public static void SaveGrayJpg(float[] db, int w, int h, int outW, string path) {
    var bmp = new Bitmap(w,h,PixelFormat.Format32bppArgb); var d=bmp.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
    var buf=new byte[d.Stride*h];
    for(int y=0;y<h;y++) for(int x=0;x<w;x++){ int i=y*d.Stride+x*4; float q=db[y*w+x]; byte g = float.IsNaN(q)?(byte)0:(byte)Math.Max(0,Math.Min(255,(q+25)/20*255)); buf[i]=g;buf[i+1]=g;buf[i+2]=g;buf[i+3]=255; }
    Marshal.Copy(buf,0,d.Scan0,buf.Length); bmp.UnlockBits(d);
    int outH=(int)Math.Round((double)h*outW/w); var sm=new Bitmap(outW,outH); using(var g=Graphics.FromImage(sm)){ g.InterpolationMode=System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic; g.DrawImage(bmp,0,0,outW,outH);} bmp.Dispose();
    var enc=Array.Find(ImageCodecInfo.GetImageEncoders(), e=>e.MimeType=="image/jpeg"); var ps=new EncoderParameters(1); ps.Param[0]=new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 78L); sm.Save(path, enc, ps); sm.Dispose(); }
  // block-max downsample so small flood patches survive: class 2 beats 1 beats 0
  public static void SaveMask(byte[] c0, int w0, int h0, int f, string path) {
    int w=w0/f, h=h0/f; var c=new byte[w*h];
    for(int y=0;y<h;y++) for(int x=0;x<w;x++){ byte m=0; for(int dy=0;dy<f;dy++) for(int dx=0;dx<f;dx++){ byte k=c0[(y*f+dy)*w0+x*f+dx]; if(k==2){m=2;} else if(k==1&&m==0) m=1; } c[y*w+x]=m; }
    var bmp = new Bitmap(w,h,PixelFormat.Format32bppArgb); var d=bmp.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
    var buf=new byte[d.Stride*h];
    for(int y=0;y<h;y++) for(int x=0;x<w;x++){ int i=y*d.Stride+x*4; byte k=c[y*w+x];
      if(k==2){ buf[i]=79;buf[i+1]=91;buf[i+2]=255;buf[i+3]=255; }        // new flood water  #FF5B4F
      else if(k==1){ buf[i]=71;buf[i+1]=48;buf[i+2]=22;buf[i+3]=255; } }  // permanent water  #163047
    Marshal.Copy(buf,0,d.Scan0,buf.Length); bmp.UnlockBits(d); bmp.Save(path, ImageFormat.Png); bmp.Dispose(); }
}
"@
# pixel area: bbox in Web Mercator split into W x H; ground size shrinks by cos(latitude)
$mx = 6378137 * [math]::PI / 180
function MY([double]$lat) { 6378137 * [math]::Log([math]::Tan([math]::PI / 4 + $lat * [math]::PI / 360)) }
$gW = 0.40 * $mx * [math]::Cos(29.8 * [math]::PI / 180); $gH = ((MY (-29.53)) - (MY (-30.06))) * [math]::Cos(29.8 * [math]::PI / 180)   # ground extent (m)
$sum = [ordered]@{ method = 'Sentinel-1 RTC VV, 5x5 mean, water < -16 dB, new flood = water after & not before & drop >= 3 dB; sea and permanent water (JRC GSW >= 50%, +30 m) excluded'; pairs = [ordered]@{} }
foreach ($k in $pairs.Keys) { $p = $pairs[$k]; $w = 0; $h = 0
  $b = [S1]::Load((Get-VV $p.before), [ref]$w, [ref]$h); $a = [S1]::Load((Get-VV $p.after), [ref]$w, [ref]$h)
  $pxW = $gW / $w; $pxH = $gH / $h; $sum.pixel_m = [math]::Round([math]::Sqrt($pxW * $pxH), 1)
  $bd = [S1]::SmoothDb($b, $w, $h, 2); $ad = [S1]::SmoothDb($a, $w, $h, 2)
  $W0 = 30.673828125; $E0 = 31.201171875; $N0 = -29.45873118535533; $S0 = -30.145127183376118   # GSW mosaic bounds
  Add-Type -AssemblyName System.Drawing; $gi = [Drawing.Image]::FromFile("$root\prototype\story\durban_water.png"); $GW = $gi.Width; $GH = $gi.Height; $gi.Dispose()
  $ax = 0.40 / $w / ($E0 - $W0) * $GW; $bx = ((30.74 - $W0) / ($E0 - $W0) + 0.5 * 0.40 / $w / ($E0 - $W0)) * $GW
  $mTop = MY (-29.53); $mBot = MY (-30.06); $mN = MY $N0; $mS = MY $S0
  $ay = ($mTop - $mBot) / $h / ($mN - $mS) * $GH; $by = (($mN - $mTop) / ($mN - $mS) + 0.5 * ($mTop - $mBot) / $h / ($mN - $mS)) * $GH
  $excl = [S1]::GswPermanent("$root\prototype\story\durban_water.png", $w, $h, $ax, $bx, $ay, $by)
  $nNew = 0; $nPerm = 0; $c = [S1]::Classify($bd, $ad, $excl, -16, 3, [ref]$nNew, [ref]$nPerm)
  [S1]::SaveGrayJpg($bd, $w, $h, 1200, "$web\${k}_before.jpg"); [S1]::SaveGrayJpg($ad, $w, $h, 1200, "$web\${k}_after.jpg"); [S1]::SaveMask($c, $w, $h, 3, "$web\${k}_flood.png")
  $sum.pairs[$k] = [ordered]@{ label = $p.label; before = $p.b; after = $p.a; before_id = $p.before; after_id = $p.after; new_water_km2 = [math]::Round($nNew * $pxW * $pxH / 1e6, 2); permanent_water_km2 = [math]::Round($nPerm * $pxW * $pxH / 1e6, 2) }
  "$k : new flood water $($sum.pairs[$k].new_water_km2) km2, permanent $($sum.pairs[$k].permanent_water_km2) km2" }
($sum | ConvertTo-Json -Depth 5) | Out-File "$root\data\s1_flood_summary.json" -Encoding utf8
