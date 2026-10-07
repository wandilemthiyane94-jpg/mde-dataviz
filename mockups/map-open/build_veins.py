# Layers for the "veins" opening mockup: base map, river + flood layer, and a distance-from-ocean field (drives the growth).
import json, math, os, re
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from scipy import ndimage
H0 = os.path.dirname(os.path.abspath(__file__)); IMG = os.path.join(H0, "img"); OUT = os.path.join(H0, "veins"); os.makedirs(OUT, exist_ok=True)
W, H = 1600, 1000
mx = lambda lon: (lon + 180) / 360
my = lambda lat: (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2
md = open(os.path.join(IMG, "map-data.js"), encoding="utf8").read()
V, _ = json.JSONDecoder().raw_decode(md[md.index("{"):]); OX, OY, U = V["o"]
META = json.loads(re.search(r"const META = (\{.*?\});", md).group(1))
st = open(os.path.join(IMG, "sites.js"), encoding="utf8").read()
SITES, _ = json.JSONDecoder().raw_decode(st[st.index("[", st.index("const SITES")):])
CX, CY, Z = mx(30.93), my(-29.86), 11.65; S = 256 * 2 ** Z
sx = lambda X: (X - CX) * S + W / 2; sy = lambda Y: (Y - CY) * S + H / 2
BOX = [0.584716796875, 0.585693359375, 0.58740234375, 0.588134765625]
def place(im, b, size=(W, H)):
    x0, y0, x1, y1 = sx(b[0]), sy(b[1]), sx(b[2]), sy(b[3])
    big = im.resize((max(1, int(x1 - x0)), max(1, int(y1 - y0))), Image.LANCZOS)
    c = Image.new(im.mode, size, (0, 0, 0, 0) if im.mode == "RGBA" else 0); c.paste(big, (int(x0), int(y0))); return c
# ---- base: dark canvas + relief (soft light) + deep ocean gradient + labels
dark = place(Image.open(os.path.join(IMG, "dark.png")).convert("RGB"), BOX)
rel = place(Image.open(os.path.join(IMG, "hillshade.png")).convert("RGB"), BOX)  # fresh hillshade, AWS Terrain Tiles
D = np.asarray(dark, np.float32) / 255; R = np.asarray(rel, np.float32) / 255; L = R.mean(2, keepdims=True)

soft = np.where(L < .5, D - (1 - 2 * L) * D * (1 - D), D + (2 * L - 1) * (np.sqrt(D) - D))
lum = np.clip((L - .55) * 1.6 + .5 + (D.mean(2, keepdims=True) - .3) * .4, 0, 1)
# lush green ramp: deep valley green -> sunlit ridge green, shaded by the real terrain
lo, mid, hi = np.array([.05, .17, .08]), np.array([.16, .40, .15]), np.array([.55, .74, .38])
base = np.where(lum < .5, lo + (mid - lo) * (lum / .5), mid + (hi - mid) * ((lum - .5) / .5))
base = np.clip(base, 0, 1)

# ocean mask from the city's ocean polygons
def poly_mask(rings, scale=2):
    m = Image.new("L", (W * scale, H * scale), 0); d = ImageDraw.Draw(m)
    for r in rings:
        pts = [(sx(OX + r[i] / U) * scale, sy(OY + r[i + 1] / U) * scale) for i in range(0, len(r), 2)]
        if len(pts) > 2: d.polygon(pts, fill=255)
    return m.resize((W, H), Image.LANCZOS)
ocean = np.asarray(poly_mask(V["ocean"]), np.float32) / 255
# anything outside the dark tiles' land (very dark) east of the coast also counts as sea
sea = np.maximum(ocean, ((D.mean(2) < .17) & (np.arange(W)[None, :] > W * .55)).astype(np.float32))
sea = ndimage.binary_opening(sea > .5, iterations=3).astype(np.float32)
yy = np.linspace(0, 1, H)[:, None, None]
ocean_col = np.array([.035, .075, .13]) * (1 - .35 * yy) + np.array([.0, .02, .05]) * yy
base = base * (1 - sea[..., None]) + ocean_col * sea[..., None]
# soft coastline glow
edge = ndimage.binary_dilation(sea > .5, iterations=2) ^ (sea > .5)
glow = ndimage.gaussian_filter(edge.astype(np.float32), 3)[..., None]
base = np.clip(base + glow * np.array([.55, .8, .75]) * .6, 0, 1)
Image.fromarray((base * 255).astype(np.uint8)).save(os.path.join(OUT, "base.jpg"), quality=90)
lab = place(Image.open(os.path.join(IMG, "labels.png")).convert("RGBA"), BOX); lab.save(os.path.join(OUT, "labels.png"))
# ---- water layer: rivers (veins) and the flood plain, at 2x then down
sc = 2; wl = Image.new("RGBA", (W * sc, H * sc), (0, 0, 0, 0)); d = ImageDraw.Draw(wl)
fl = Image.new("L", (W * sc, H * sc), 0); df = ImageDraw.Draw(fl)
for r in V["flood"]:
    pts = [(sx(OX + r[i] / U) * sc, sy(OY + r[i + 1] / U) * sc) for i in range(0, len(r), 2)]
    if len(pts) > 2: df.polygon(pts, fill=255)
fl = fl.resize((W, H), Image.LANCZOS)
rv = Image.new("L", (W * sc, H * sc), 0); dr = ImageDraw.Draw(rv)
for r in V["river"]:
    pts = [(sx(OX + r[i] / U) * sc, sy(OY + r[i + 1] / U) * sc) for i in range(0, len(r), 2)]
    if len(pts) > 1: dr.line(pts, fill=255, width=3, joint="curve")
rv = rv.resize((W, H), Image.LANCZOS)
F = np.asarray(fl, np.float32) / 255 * (1 - sea); Rv = np.asarray(rv, np.float32) / 255 * (1 - sea)
fedge = np.clip(np.abs(ndimage.sobel(F, 0)) + np.abs(ndimage.sobel(F, 1)), 0, 1)
# RGBA: flood fill blue, flood edge light blue, rivers pale cyan
col = np.zeros((H, W, 4), np.float32)
col[..., :3] = np.array([.16, .5, .95]) * F[..., None]
a = F * .62
col[..., :3] = np.where(fedge[..., None] > .2, np.array([.65, .84, 1.0]), col[..., :3]); a = np.maximum(a, fedge * .95)
col[..., :3] = np.where(Rv[..., None] > a[..., None], np.array([.55, .82, 1.0]), col[..., :3]); a = np.maximum(a, Rv * .9)
col[..., 3] = a
Image.fromarray((col * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "water.png"))
# ---- growth field: distance inland from the sea, measured along the water itself where possible
water = (F > .15) | (Rv > .25)
dist_all = ndimage.distance_transform_edt(sea < .5)                       # straight-line distance from the sea
# geodesic-ish: water pixels grow from the coast through connected water; elsewhere fall back to straight distance
lab_w, n = ndimage.label(water | (sea > .5))
seaid = set(np.unique(lab_w[sea > .5])) - {0}
conn = np.isin(lab_w, list(seaid)) & water
g = np.where(conn, dist_all * .85, dist_all * 1.25 + 60)
rng = np.random.default_rng(3); noise = ndimage.gaussian_filter(rng.random((H, W)), 6)
g = g + (noise - .5) * 60
g = np.clip(g / np.percentile(g[water], 99) , 0, 1)
g16 = (g * 65535).astype(np.uint32)
enc = np.zeros((H, W, 3), np.uint8); enc[..., 0] = g16 >> 8; enc[..., 1] = g16 & 255
Image.fromarray(enc).save(os.path.join(OUT, "dist.png"))
pins = [{"id": s["id"], "name": s["name"], "x": round(sx(mx(s["lon"])), 1), "y": round(sy(my(s["lat"])), 1), "g": float(g[min(H-1, max(0, int(sy(my(s["lat"]))))), min(W-1, max(0, int(sx(mx(s["lon"])))))])} for s in SITES]
json.dump(pins, open(os.path.join(OUT, "pins.json"), "w"))
print("ok", n, len(seaid), round(float(sea.mean()), 3))

# satellite layer (real ground colour) for the final beat, from the landing basemap
lm = open(os.path.join(H0, "..", "..", "viz-wandile", "data", "landing-meta.js"), encoding="utf8").read()
BASEBOX = json.loads(re.search(r"const BASE = (\[[^\]]*\]);", lm).group(1))
sat = place(Image.open(os.path.join(H0, "..", "..", "viz-wandile", "assets", "basemap.jpg")).convert("RGB"), BASEBOX)
Sa = np.asarray(sat, np.float32) / 255
Sa = Sa * (1 - sea[..., None]) + ocean_col * sea[..., None]
Image.fromarray((np.clip(Sa, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, "sat.jpg"), quality=86)
print("sat ok")
