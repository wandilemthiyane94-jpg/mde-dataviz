# Composes the recorded frames into the final MP4: site on top, a caption band below (no text over the UI),
# a drawn cursor with click ripples, and fades at page changes. Usage: python compose.py <work_dir> <out.mp4> <ffmpeg>
import sys, os, json, subprocess
from PIL import Image, ImageDraw, ImageFont

WORK, OUT, FF = sys.argv[1], sys.argv[2], sys.argv[3]
M = json.load(open(os.path.join(WORK, "events.json"))); F = M["fps"]; N = M["frames"]; K = M["dsf"]
VW, VH, SH = 1920, 1080, 940; BAND = VH - SH
BG = (7, 11, 18); AMBER = (245, 165, 36); WHITE = (248, 250, 252)
FT = ImageFont.truetype(r"C:\Windows\Fonts\segoeuisb.ttf" if os.path.exists(r"C:\Windows\Fonts\segoeuisb.ttf") else r"C:\Windows\Fonts\segoeuib.ttf", 36)
FL = ImageFont.truetype(r"C:\Windows\Fonts\consola.ttf", 17)
ev = M["events"]

def ease(k): k = max(0, min(1, k)); return k * k * (3 - 2 * k)

# caption timeline: (start_frame, label, text)
caps = [(e["f"], e["label"], e["text"]) for e in ev if e["t"] == "cap"]
cuts = [e["f"] for e in ev if e["t"] == "cut"]
# cursor keyframes: the cursor appears at its first move, glides to each target, and rests there
moves = [e for e in ev if e["t"] == "move"]; clicks = [e for e in ev if e["t"] == "click"]

def cursor_at(f):
    pos = None
    for i, m in enumerate(moves):
        if f < m["f"]: break
        start = (moves[i - 1]["x"], moves[i - 1]["y"]) if i else (m["x"] + 160, m["y"] + 120)
        d = max(1, round(m["dur"] * F)); k = ease((f - m["f"]) / d)
        pos = (start[0] + (m["x"] - start[0]) * k, start[1] + (m["y"] - start[1]) * k)
    if pos is None: return None
    # hide the cursor after a page change until it moves again
    last_cut = max([c for c in cuts if c <= f], default=-1)
    last_move = max([m["f"] for m in moves if m["f"] <= f], default=-1)
    if last_cut > last_move: return None
    # tuck the cursor away shortly after a click so it never sits on what just opened
    last_click = max([c["f"] for c in clicks if c["f"] <= f], default=-1)
    if last_click >= last_move and f - last_click > 0.7 * F: return None
    return pos

ARROW = [(0, 0), (0, 25), (6.5, 19.5), (11, 29), (15, 27), (10.5, 18), (19, 18)]
def draw_cursor(im, f):
    if os.environ.get("NOCURSOR"): return
    p = cursor_at(f)
    if not p: return
    d = ImageDraw.Draw(im, "RGBA"); x, y = p[0] * K, p[1] * K
    for c in clicks:
        a = f - c["f"]
        if 0 <= a < 14:
            r = 10 + a * 3.2; al = int(200 * (1 - a / 14))
            d.ellipse([c["x"] * K - r, c["y"] * K - r, c["x"] * K + r, c["y"] * K + r], outline=(251, 201, 0, al), width=4)
    s = 1.25; pts = [(x + px * s, y + py * s) for px, py in ARROW]
    d.polygon([(px + 2, py + 3) for px, py in pts], fill=(0, 0, 0, 90))
    d.polygon(pts, fill=(255, 255, 255, 255), outline=(10, 10, 10, 255)); d.line(pts + [pts[0]], fill=(10, 10, 10, 255), width=2)

def caption_at(f):
    cur = None; start = 0
    for c in caps:
        if c[0] <= f: cur = c; start = c[0]
    return cur, start

def band(f):
    im = Image.new("RGB", (VW, BAND), BG); d = ImageDraw.Draw(im)
    c, st = caption_at(f)
    if not c or not c[2]: return im
    a = ease((f - st) / (0.45 * F))
    col = lambda rgb: tuple(int(BG[i] + (rgb[i] - BG[i]) * a) for i in range(3))
    lab = c[1].upper(); tw = d.textlength(c[2], font=FT); lw = d.textlength(lab, font=FL)
    d.text(((VW - lw) / 2, 22), lab, font=FL, fill=col(AMBER))
    d.text(((VW - tw) / 2, 52 + (1 - a) * 6), c[2], font=FT, fill=col(WHITE))
    return im

def fade(f):
    """1 = full picture; dips to black over 0.4 s either side of a page change."""
    v = 1.0; w = 0.4 * F
    for c in cuts:
        if c == 0: v = min(v, ease(f / w)); continue
        if c - w <= f < c: v = min(v, ease((c - f) / w))
        if c <= f < c + w: v = min(v, ease((f - c) / w))
    return v

last = None
p = subprocess.Popen([FF, "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{VW}x{VH}", "-r", str(F), "-i", "-",
                      "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p", "-movflags", "+faststart", OUT], stdin=subprocess.PIPE)
for f in range(N):
    fr = os.path.join(WORK, "raw", "f%05d.jpg" % f)
    site = Image.open(fr).convert("RGB") if os.path.exists(fr) else last
    last = site
    if site.size != (VW, SH): site = site.resize((VW, SH), Image.LANCZOS)
    site = site.copy(); draw_cursor(site, f)
    v = fade(f)
    if v < 1: site = Image.blend(Image.new("RGB", site.size, BG), site, v)
    out = Image.new("RGB", (VW, VH), BG); out.paste(site, (0, 0)); out.paste(band(f), (0, SH))
    p.stdin.write(out.tobytes())
    if f % 300 == 0: print("frame", f, "/", N, flush=True)
p.stdin.close(); p.wait(); print("done", OUT)
