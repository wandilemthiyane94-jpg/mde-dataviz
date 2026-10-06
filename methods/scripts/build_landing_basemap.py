# Bakes the landing-page basemap for viz-wandile: Esri World Imagery (z13) blended with a hillshade from
# AWS Terrain Tiles (z12), plus per-site thumbnails (z16 imagery with the 1-in-100-year flood line, and with the
# JRC satellite water record). Writes viz-wandile/assets/basemap.jpg, assets/sites/*.jpg and data/landing-meta.js.
import io, json, math, os, urllib.request
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
V = os.path.join(ROOT, "viz-wandile"); os.makedirs(os.path.join(V, "assets", "sites"), exist_ok=True)
UA = {"User-Agent": "Mozilla/5.0 (student research project, Harvard GSD)"}
mx = lambda lon: (lon + 180) / 360
my = lambda lat: (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2
def get(url):
    return Image.open(io.BytesIO(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40).read()))
def mosaic(z, lon0, lat0, lon1, lat1, url, mode="RGB"):
    n = 2 ** z; x0, x1 = int(mx(lon0) * n), int(mx(lon1) * n); y0, y1 = int(my(lat0) * n), int(my(lat1) * n)
    im = Image.new(mode, ((x1 - x0 + 1) * 256, (y1 - y0 + 1) * 256))
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            im.paste(get(url.format(z=z, x=x, y=y)).convert(mode), ((x - x0) * 256, (y - y0) * 256))
    return im, (x0 / n, y0 / n, (x1 + 1) / n, (y1 + 1) / n)
SAT = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
TER = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
LON0, LAT0, LON1, LAT1 = 30.45, -29.40, 31.30, -30.18

# ---------- basemap ----------
sat, box = mosaic(13, LON0, LAT0, LON1, LAT1, SAT)
ter, tbox = mosaic(12, LON0, LAT0, LON1, LAT1, TER)
t = np.asarray(ter, np.float32); elev = t[..., 0] * 256 + t[..., 1] + t[..., 2] / 256 - 32768
# resample the elevation grid onto the imagery grid
W, H = sat.size
def resample(a, src, dst, size):
    sx0, sy0, sx1, sy1 = src; dx0, dy0, dx1, dy1 = dst; w, h = size
    xs = ((np.linspace(dx0, dx1, w, endpoint=False) - sx0) / (sx1 - sx0) * a.shape[1]).clip(0, a.shape[1] - 1)
    ys = ((np.linspace(dy0, dy1, h, endpoint=False) - sy0) / (sy1 - sy0) * a.shape[0]).clip(0, a.shape[0] - 1)
    y0i = np.floor(ys).astype(int); x0i = np.floor(xs).astype(int); y1i = np.minimum(y0i + 1, a.shape[0] - 1); x1i = np.minimum(x0i + 1, a.shape[1] - 1)
    fy = (ys - y0i)[:, None]; fx = (xs - x0i)[None, :]
    return a[y0i][:, x0i] * (1 - fy) * (1 - fx) + a[y0i][:, x1i] * (1 - fy) * fx + a[y1i][:, x0i] * fy * (1 - fx) + a[y1i][:, x1i] * fy * fx
E = resample(elev, tbox, box, (W, H))
for _ in range(2): E = (E + np.roll(E, 1, 0) + np.roll(E, -1, 0) + np.roll(E, 1, 1) + np.roll(E, -1, 1)) / 5   # light smoothing
px_m = 40075016.686 * math.cos(math.radians(29.8)) / (2 ** 13 * 256)
gy, gx = np.gradient(E, px_m)
az, alt = math.radians(315), math.radians(42)
slope = np.arctan(np.hypot(gx, gy) * 2.2); aspect = np.arctan2(-gx, gy)
hs = np.sin(alt) * np.cos(slope) + np.cos(alt) * np.sin(slope) * np.cos(az - aspect)
hs = np.clip(hs, 0, 1); hs[E <= 0.5] = 0.5   # sea: no relief (coarse bathymetry makes steps)
hs = hs[..., None]
S = np.asarray(sat, np.float32) / 255
# soft-light blend: keeps the photo, adds relief
out = np.where(hs < 0.5, S - (1 - 2 * hs) * S * (1 - S), S + (2 * hs - 1) * (np.sqrt(S) - S))
out = np.clip((out * 0.92) ** 1.05, 0, 1)                      # slightly darker so overlays read
Image.fromarray((out * 255).astype(np.uint8)).save(os.path.join(V, "assets", "basemap.jpg"), quality=84, optimize=True, progressive=True)
print("basemap", W, H, round(os.path.getsize(os.path.join(V, "assets", "basemap.jpg")) / 1e6, 1), "MB")

# ---------- flood polygons and water record for thumbnails ----------
md = open(os.path.join(V, "data", "map-data.js"), encoding="utf8").read()
GEO, _ = json.JSONDecoder().raw_decode(md[md.index("{"):]); OX, OY, U = GEO["o"]
META = json.loads(md[md.index("const META") + md[md.index("const META"):].index("{"):].split(";")[0])
FLOOD = [[(OX + r[k] / U, OY + r[k + 1] / U) for k in range(0, len(r), 2)] for r in GEO["flood"]]
WATER = Image.open(os.path.join(V, "assets", "water_near.png")).convert("RGBA")
st = open(os.path.join(V, "data", "sites.js"), encoding="utf8").read()
SITES, _ = json.JSONDecoder().raw_decode(st[st.index("[", st.index("const SITES")):])
def thumb(s):
    z = 16; n = 2 ** z; cx, cy = mx(s["lon"]) * n, my(s["lat"]) * n
    tw, th = 640, 400; x0, y0 = cx - tw / 512, cy - th / 512
    im = Image.new("RGB", (int((math.floor(x0 + tw / 256) - math.floor(x0) + 1) * 256), int((math.floor(y0 + th / 256) - math.floor(y0) + 1) * 256)))
    for x in range(int(math.floor(x0)), int(math.floor(x0 + tw / 256)) + 1):
        for y in range(int(math.floor(y0)), int(math.floor(y0 + th / 256)) + 1):
            im.paste(get(SAT.format(z=z, x=x, y=y)).convert("RGB"), ((x - int(math.floor(x0))) * 256, (y - int(math.floor(y0))) * 256))
    ox, oy = (x0 - math.floor(x0)) * 256, (y0 - math.floor(y0)) * 256
    base = im.crop((int(ox), int(oy), int(ox) + tw, int(oy) + th))
    P = lambda X, Y: ((X * n - x0) * 256, (Y * n - y0) * 256)
    # official flood map
    a = base.convert("RGBA"); lay = Image.new("RGBA", a.size, (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    for ring in FLOOD:
        pts = [P(X, Y) for X, Y in ring]
        if all(p[0] < -50 or p[0] > tw + 50 for p in pts) or all(p[1] < -50 or p[1] > th + 50 for p in pts): continue
        d.polygon(pts, fill=(40, 120, 220, 120), outline=(120, 190, 255, 255))
    a = Image.alpha_composite(a, lay); d = ImageDraw.Draw(a); c = P(mx(s["lon"]), my(s["lat"]))
    d.ellipse([c[0] - 13, c[1] - 13, c[0] + 13, c[1] + 13], outline=(251, 201, 0, 255), width=4); d.ellipse([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=(251, 201, 0, 255))
    a.convert("RGB").save(os.path.join(V, "assets", "sites", f"{s['id']}_flood.jpg"), quality=82)
    # satellite water record (JRC, 1984-2021), cut from the water layer
    wx0, wy0, wx1, wy1 = META["water"]; ww, wh = WATER.size
    X0, Y0 = x0 / n, y0 / n; X1, Y1 = (x0 + tw / 256) / n, (y0 + th / 256) / n
    crop = WATER.crop((int((X0 - wx0) / (wx1 - wx0) * ww), int((Y0 - wy0) / (wy1 - wy0) * wh), int((X1 - wx0) / (wx1 - wx0) * ww), int((Y1 - wy0) / (wy1 - wy0) * wh))).resize((tw, th), Image.NEAREST)
    b = Image.alpha_composite(Image.eval(base, lambda v: int(v * 0.75)).convert("RGBA"), crop); d = ImageDraw.Draw(b)
    d.ellipse([c[0] - 13, c[1] - 13, c[0] + 13, c[1] + 13], outline=(251, 201, 0, 255), width=4); d.ellipse([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=(251, 201, 0, 255))
    b.convert("RGB").save(os.path.join(V, "assets", "sites", f"{s['id']}_water.jpg"), quality=82)
    base.save(os.path.join(V, "assets", "sites", f"{s['id']}.jpg"), quality=84)
import sys
if '--base-only' not in sys.argv:
    for s in SITES: thumb(s); print("thumb", s["id"])

# ---------- other eThekwini TRAs from our list (approximate locations) ----------
tr = open(os.path.join(ROOT, "prototype", "story", "tra-story-data.js"), encoding="utf8").read()
TRA, _ = json.JSONDecoder().raw_decode(tr[tr.index("window.TRA=") + len("window.TRA="):])
SKIP = {31, 32, 33, 35, 42, 43, 45, 51, 52, 54}          # already among the 12 detailed sites
OTHER = [{"id": x["id"], "name": x["site"], "lat": float(x["lat"]), "lon": float(x["lon"]), "status": x["status"], "est": x["est"], "conf": x["conf"], "fp": x["fp"], "size": x["size"]}
         for x in TRA["sites"] if "Thekwini" in (x["muni"] or "") and x["lat"] and x["id"] not in SKIP]
js = "/* Generated by methods/scripts/build_landing_basemap.py. */\nconst BASE = " + json.dumps(list(box)) + ";\nconst OTHER_TRA = " + json.dumps(OTHER, ensure_ascii=False) + ";\nconst TRA_COUNTS = " + json.dumps({"ethekwini": 28, "national": TRA["summary"]["sites"], "detailed": len(SITES)}) + ";\n"
open(os.path.join(V, "data", "landing-meta.js"), "w", encoding="utf8").write(js); print("other TRAs", len(OTHER))
