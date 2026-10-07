# Story-intro mockups (design only; not part of the website). Writes src/*.html and renders frames/*.png with headless Edge.
import json, os, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
os.makedirs(os.path.join(HERE, "src"), exist_ok=True); os.makedirs(os.path.join(HERE, "frames"), exist_ok=True)
SAT = json.load(open(os.path.join(HERE, "img", "sat_meta.json")))
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

CSS = """
:root{--bg:#070B12;--ink:#F8FAFC;--txt:#E2E8F0;--mut:#9AA6B8;--dim:#64748B;--line:rgba(255,255,255,.14);--amber:#F5A524;--site:#FBC900;--red:#E5484D;
 --sans:Inter,"Helvetica Neue",Arial,sans-serif;--serif:Newsreader,Georgia,serif;--mono:"IBM Plex Mono",Consolas,monospace}
*{box-sizing:border-box}html,body{margin:0;height:100%;background:var(--bg);color:var(--txt);font:15px/1.45 var(--sans);overflow:hidden}
.stage{position:fixed;inset:0;overflow:hidden}
.full{position:absolute;inset:0;background-size:cover;background-position:center}
.film{position:absolute;inset:0;background-color:#1B2626;background-size:100% auto;background-position:center;background-repeat:no-repeat}
.vig{position:absolute;inset:0;background:radial-gradient(ellipse at 50% 45%,transparent 40%,rgba(3,6,12,.75) 100%)}
.top{position:absolute;left:0;right:0;top:0;height:64px;display:flex;align-items:center;padding:0 32px;gap:24px;z-index:5;background:linear-gradient(rgba(5,8,14,.75),transparent)}
.brand{font:700 18px var(--sans);color:#fff;letter-spacing:-.01em}
.prog{margin:0 auto;display:flex;align-items:center;gap:10px;font:500 11px var(--mono);letter-spacing:.14em;text-transform:uppercase;color:rgba(255,255,255,.8)}
.prog i{width:30px;height:4px;border-radius:2px;background:rgba(255,255,255,.22)}
.prog i.on{background:var(--amber)}.prog i.now{background:linear-gradient(90deg,var(--amber) 50%,rgba(255,255,255,.22) 50%)}
.skip{font-size:13px;color:rgba(255,255,255,.85);border:1px solid rgba(255,255,255,.3);border-radius:999px;padding:6px 14px}
.credit{position:absolute;left:32px;bottom:20px;font:10.5px var(--mono);color:rgba(255,255,255,.55);z-index:5}
.note{position:absolute;right:28px;bottom:20px;font:600 10px var(--mono);letter-spacing:.12em;text-transform:uppercase;color:#0B0F19;background:var(--site);padding:4px 8px;border-radius:3px;z-index:6}
.glass{background:rgba(10,15,24,.72);backdrop-filter:blur(16px);-webkit-backdrop-filter:blur(16px);border:1px solid var(--line);border-radius:14px}
.kick{font:600 11px var(--mono);letter-spacing:.2em;text-transform:uppercase;color:var(--amber)}
.btnred{display:inline-flex;align-items:center;gap:14px;background:var(--red);color:#fff;font:700 22px var(--sans);padding:20px 34px;border-radius:999px;box-shadow:0 0 0 10px rgba(229,72,77,.18),0 0 0 22px rgba(229,72,77,.08),0 18px 50px rgba(0,0,0,.5)}
.btnw{display:inline-flex;align-items:center;gap:12px;background:#fff;color:#0B0F19;font:600 18px var(--sans);padding:16px 28px;border-radius:12px}
.pin{position:absolute;width:56px;height:70px;transform:translate(-50%,-100%)}
.ring{position:absolute;border:2px solid var(--site);border-radius:50%;transform:translate(-50%,-50%)}
.lab{position:absolute;transform:translate(-50%,10px);font:600 12px var(--sans);color:#0B0F19;background:var(--site);padding:3px 9px;border-radius:4px;white-space:nowrap}
.lab.g{background:rgba(10,15,24,.85);color:#fff;border:1px solid var(--line)}
"""
FONTS = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Newsreader:ital,opsz,wght@0,6..72,400;0,6..72,500;1,6..72,400;1,6..72,500&family=IBM+Plex+Mono:wght@400;500;600&display=swap">'
PIN = '<svg class="pin" viewBox="0 0 56 70" style="left:{x}px;top:{y}px"><defs><filter id="sh" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="6" stdDeviation="5" flood-opacity=".45"/></filter></defs><path d="M28 68C28 68 4 42 4 26a24 24 0 0148 0c0 16-24 42-24 42z" fill="#FBC900" filter="url(#sh)"/><circle cx="21" cy="19" r="4" fill="#0B0F19"/><circle cx="35" cy="19" r="4" fill="#0B0F19"/><circle cx="28" cy="31" r="3" fill="#0B0F19"/><path d="M14 38v-6a7 7 0 0114 0v6zM28 38v-6a7 7 0 0114 0v6z" fill="#0B0F19"/><path d="M23 44v-4a5 5 0 0110 0v4z" fill="#0B0F19"/></svg>'

def top(step, label):
    bars = "".join('<i class="%s"></i>' % ("on" if i < step else ("now" if i == step else "")) for i in range(4))
    return f'<div class="top"><div class="brand">Moved Into the Water</div><div class="prog">{bars}<span>{label}</span></div><div class="skip">Skip story →</div></div>'
CRED = '<div class="credit">Illustration from our animation · the family\'s moves follow GroundUp\'s reporting (June 2022)</div>'
def page(body, w=1600, h=1000):
    return f'<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width={w}">{FONTS}<style>{CSS}</style></head><body><div class="stage">{body}</div></body></html>'
def sat(cx_pt, sx, sy, scale):
    px, py = SAT["pts"][cx_pt]
    return f'background-image:url(../img/sat_umlazi.jpg);background-size:{SAT["w"]*scale}px {SAT["h"]*scale}px;background-position:{sx-px*scale}px {sy-py*scale}px;background-repeat:no-repeat', (lambda k: (sx + (SAT["pts"][k][0]-px)*scale, sy + (SAT["pts"][k][1]-py)*scale))

F = {}
# 01 · the question
F["01-question"] = page(f"""
<div class="full" style="background-image:url(../img/city.jpg);filter:saturate(.85) brightness(.82)"></div><div class="vig"></div>
<div style="position:absolute;inset:0;background:linear-gradient(90deg,rgba(5,8,14,.92) 0%,rgba(5,8,14,.6) 42%,transparent 70%)"></div>
<div class="top"><div class="brand">Moved Into the Water</div><div style="margin-left:auto" class="skip">Skip to the map →</div></div>
<div style="position:absolute;left:96px;top:190px;width:640px">
 <div class="kick">Durban · a story in four moves</div>
 <h1 style="font:800 76px/0.98 var(--sans);letter-spacing:-.035em;color:#fff;margin:18px 0 22px">Where would the city move you?</h1>
 <p style="font:22px/1.45 var(--serif);color:#dbe3ee;margin:0 0 34px;max-width:540px">When floods take a home in Durban, families are sent to "temporary" camps. Pick a township to follow one family's journey.</p>
 <div class="glass" style="padding:8px 8px 8px 22px;display:flex;align-items:center;gap:14px;width:560px;border-radius:16px">
  <svg width="20" height="20" viewBox="0 0 16 16"><circle cx="7" cy="7" r="5.5" fill="none" stroke="#9AA6B8" stroke-width="1.6"/><path d="M11 11L15 15" stroke="#9AA6B8" stroke-width="1.6"/></svg>
  <span style="font-size:19px;color:#fff;flex:1">uMlazi<span style="display:inline-block;width:2px;height:22px;background:var(--amber);vertical-align:-4px;margin-left:2px"></span></span>
  <span class="btnw" style="font-size:16px;padding:13px 20px">Follow →</span></div>
 <div class="glass" style="width:560px;margin-top:8px;padding:6px;border-radius:14px">
  <div style="display:flex;justify-content:space-between;padding:11px 16px;border-radius:9px;background:rgba(255,255,255,.08);color:#fff"><span><b>uMlazi</b> · Mega Village</span><span style="color:var(--amber);font:500 12px var(--mono)">where the story starts</span></div>
  <div style="display:flex;justify-content:space-between;padding:11px 16px;color:#cbd5e1"><span>Lamontville</span><span style="color:var(--dim);font:12px var(--mono)">2 camps</span></div>
  <div style="display:flex;justify-content:space-between;padding:11px 16px;color:#cbd5e1"><span>Isipingo</span><span style="color:var(--dim);font:12px var(--mono)">1 camp</span></div></div>
</div>
<div class="glass" style="position:absolute;right:56px;top:300px;width:200px;padding:22px 18px;text-align:center">
 <div style="position:relative;height:74px">{PIN.format(x=82,y=72)}</div>
 <div style="font-weight:600;color:#fff;margin-top:10px">Or drag the family</div><div style="font-size:13px;color:var(--mut)">onto any part of the map</div></div>
<div style="position:absolute;left:96px;bottom:34px;font-size:12.5px;color:rgba(255,255,255,.6);max-width:720px">This is a story built from news reports, not an emergency service. If you are in danger now, contact your local emergency services.</div>
<div class="note">01 · Landing</div>""")

# 02 · the drop
st, P = sat("mega", 760, 560, 1.35)
mx_, my_ = P("mega")
F["02-drop"] = page(f"""
<div class="full" style="{st}"></div><div class="vig"></div>
<div class="ring" style="left:{mx_}px;top:{my_}px;width:150px;height:150px;opacity:.35"></div><div class="ring" style="left:{mx_}px;top:{my_}px;width:90px;height:90px;opacity:.7"></div>
<div style="position:absolute;left:{mx_-3}px;top:{my_-330}px;width:6px;height:250px;background:linear-gradient(transparent,rgba(251,201,0,.55));border-radius:3px;filter:blur(1px)"></div>
<div style="position:absolute;left:{mx_}px;top:{my_}px;width:46px;height:14px;transform:translate(-50%,-50%);background:rgba(0,0,0,.45);border-radius:50%;filter:blur(3px)"></div>
{PIN.format(x=mx_, y=my_-38)}
<div class="lab" style="left:{mx_}px;top:{my_+14}px">Mega Village, uMlazi</div>
{top(0, "Before · 2019")}
<div class="glass" style="position:absolute;left:56px;bottom:72px;width:470px;padding:24px 26px">
 <div class="kick">uMlazi, Durban</div>
 <div style="font:500 34px/1.1 var(--serif);color:#fff;margin:10px 0 8px">This is where one family's story starts.</div>
 <div style="color:var(--mut);font-size:14.5px">Mega Village sits on low ground beside a river. The camera dives in…</div></div>
<div style="position:absolute;right:56px;top:96px;font:500 11px var(--mono);color:rgba(255,255,255,.7)">ZOOMING IN · 1 : 4,000</div>
<div class="credit">Imagery: Esri, Maxar · pin placement approximate</div><div class="note">02 · The drop</div>""")

# 03 · ordinary life
F["03-home"] = page(f"""
<div class="film" style="background-image:url(../img/film_1.jpg)"></div>
{top(0, "Before · 2019")}
<div class="glass" style="position:absolute;right:56px;top:110px;width:330px;padding:18px 20px">
 <div class="kick">Ordinary life</div><div style="color:#fff;font-size:15px;margin-top:8px">Washing on the line, the dog in the yard. Nothing yet tells you this ground floods.</div>
 <div style="display:flex;align-items:center;gap:8px;margin-top:14px;font:500 11px var(--mono);color:var(--mut)"><span style="width:8px;height:8px;border-radius:50%;background:#4ade80"></span>SCROLL OR WAIT · RAIN IN 4 S</div></div>
{CRED}<div class="note">03 · Home</div>""")

# 04 · the rain
drops = "".join(f'<i style="position:absolute;left:{(i*137)%1600}px;top:{(i*263)%1000}px;width:1.6px;height:{22+(i*7)%26}px;background:rgba(220,235,255,.45);transform:rotate(14deg)"></i>' for i in range(170))
F["04-rain"] = page(f"""
<div class="film" style="background-image:url(../img/film_4.jpg)"></div><div class="full" style="background:rgba(20,30,45,.25)"></div>{drops}
{top(0, "April 2019")}
<div class="glass" style="position:absolute;left:56px;top:110px;width:360px;padding:20px 22px">
 <div class="kick">The storm</div>
 <div style="font:800 64px/1 var(--sans);color:#fff;margin:10px 0 4px;letter-spacing:-.03em">245 mm</div>
 <div style="color:var(--mut)">of rain in three days, April 2019<br><span style="font:11px var(--mono);color:var(--dim)">ERA5 daily (Open-Meteo)</span></div></div>
{CRED}<div class="note">04 · The rain</div>""")

# 05 · the button
F["05-button"] = page(f"""
<div class="film" style="background-image:url(../img/film_5.5.jpg);filter:brightness(.55) saturate(.8)"></div>
<div class="full" style="background:linear-gradient(transparent 35%,rgba(5,8,14,.85))"></div>
{top(0, "April 2019")}
<div style="position:absolute;left:0;right:0;bottom:120px;text-align:center">
 <div style="font:italic 500 40px/1.15 var(--serif);color:#fff;margin-bottom:34px">The water is at the roof.</div>
 <span class="btnred">They called for help <span style="font-size:26px">→</span></span>
 <div style="color:rgba(255,255,255,.65);font-size:14px;margin-top:30px">Click to see where the city sent them.</div></div>
{CRED}<div class="note">05 · The button</div>""")

# 06 · the move
st, P = sat("tehuis", 900, 470, 1.1)
a, b, c = P("mega"), P("tehuis"), P("lamont")
F["06-move"] = page(f"""
<div class="full" style="{st}"></div><div class="vig"></div>
<svg style="position:absolute;inset:0" width="1600" height="1000"><path d="M{a[0]} {a[1]} Q {(a[0]+b[0])/2} {a[1]-120} {b[0]} {b[1]}" fill="none" stroke="#F5A524" stroke-width="4" stroke-dasharray="10 8"/>
<path d="M{b[0]} {b[1]} Q {(b[0]+c[0])/2} {c[1]-40} {c[0]} {c[1]}" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="2" stroke-dasharray="3 7"/></svg>
<div class="ring" style="left:{a[0]}px;top:{a[1]}px;width:22px;height:22px;background:rgba(255,255,255,.25);border-color:#fff"></div><div class="lab g" style="left:{a[0]}px;top:{a[1]+6}px">Mega Village · flooded</div>
{PIN.format(x=b[0], y=b[1]-4)}<div class="lab" style="left:{b[0]}px;top:{b[1]+12}px">Tents at Tehuis Hostel</div>
<div class="ring" style="left:{c[0]}px;top:{c[1]}px;width:18px;height:18px;border-style:dashed;opacity:.7"></div><div class="lab g" style="left:{c[0]}px;top:{c[1]+4}px;opacity:.75">next: Lamontville camp</div>
{top(1, "Move 1 of 4 · 2019")}
<div style="position:absolute;left:56px;top:104px"><div style="font:800 120px/0.9 var(--sans);color:#fff;letter-spacing:-.05em">1<span style="color:rgba(255,255,255,.3)">/4</span></div><div class="kick" style="margin-top:10px">moves</div></div>
<div class="glass" style="position:absolute;right:48px;bottom:64px;width:440px;overflow:hidden;padding:0">
 <div style="height:220px;background:url(../img/film_7.jpg) center/cover"></div>
 <div style="padding:16px 20px 18px"><div class="kick">2019 · Tehuis Hostel</div><div style="font:500 26px/1.15 var(--serif);color:#fff;margin:8px 0 6px">Tents. "Temporary." Two years.</div><div style="color:var(--mut);font-size:14px">The sun comes back. For now, everything is fine.</div></div></div>
<div class="credit">Imagery: Esri, Maxar · route drawn between reported locations, not a surveyed path</div><div class="note">06 · The move</div>""")

# 07 · it happens again
F["07-again"] = page(f"""
<div class="film" style="background-image:url(../img/film_13.jpg);filter:brightness(.6)"></div>
<div class="full" style="background:linear-gradient(transparent 40%,rgba(5,8,14,.85))"></div>
{top(2, "Move 2 of 4 · April 2022")}
<div style="position:absolute;left:56px;top:110px" class="glass"><div style="padding:16px 20px;display:flex;gap:18px;align-items:center">
 <div style="font:800 54px/1 var(--sans);color:#fff">2<span style="color:rgba(255,255,255,.3)">/4</span></div><div style="color:var(--mut);font-size:13.5px;line-height:1.35">Lamontville riverside camp<br><b style="color:#fff">Flooded again</b>, April 2022</div></div></div>
<div style="position:absolute;left:0;right:0;bottom:110px;text-align:center">
 <span class="btnred">They called for help again <span style="font-size:26px">→</span></span>
 <div style="color:rgba(255,255,255,.65);font-size:14px;margin-top:28px">Each loop runs a little faster. By the fourth, you know what's coming.</div></div>
{CRED}<div class="note">07 · Again</div>""")

# 08 · the question
F["08-question"] = page(f"""
<div class="film" style="background-image:url(../img/film_30.8.jpg)"></div>
<div style="position:absolute;left:0;right:0;top:640px;text-align:center">
 <div style="display:flex;justify-content:center;gap:48px;margin-bottom:40px;font:600 13px var(--mono);letter-spacing:.14em;text-transform:uppercase;color:rgba(255,255,255,.75)">
  <span><b style="display:block;font:800 44px var(--sans);color:#fff;letter-spacing:-.02em">4</b>moves</span>
  <span><b style="display:block;font:800 44px var(--sans);color:var(--red);letter-spacing:-.02em">3</b>floods</span>
  <span><b style="display:block;font:800 44px var(--sans);color:#fff;letter-spacing:-.02em">6</b>years</span></div>
 <span class="btnw">Explore the map <span>→</span></span></div>
<div class="note">08 · The question</div>""")

# 09 · into the tool
F["09-into-map"] = page(f"""
<div class="full" style="background-image:url(../img/landing_now.png);transform:scale(1.18);filter:blur(5px) brightness(.8)"></div>
<div class="full" style="background-image:url(../img/landing_now.png);transform:scale(.9);transform-origin:50% 50%;border-radius:14px;box-shadow:0 30px 90px rgba(0,0,0,.6);background-size:cover;inset:50px 80px"></div>
<div class="glass" style="position:absolute;left:50%;top:22px;transform:translateX(-50%);padding:10px 18px;border-radius:999px;font-size:14px;color:#fff;white-space:nowrap">The camera pulls out to the city, and you land on the interactive map</div>
<div class="note">09 · Into the tool</div>""")

# mobile versions of 01 and 05
F["m01-question"] = (page(f"""
<div class="full" style="background-image:url(../img/city.jpg);background-position:62% 50%;filter:saturate(.75) brightness(.5)"></div>
<div style="position:absolute;inset:0;background:linear-gradient(rgba(5,8,14,.2),rgba(5,8,14,.92) 60%)"></div>
<div class="top" style="padding:0 18px"><div class="brand" style="font-size:15px">Moved Into the Water</div><div class="skip" style="margin-left:auto;font-size:11.5px;padding:5px 11px">Skip →</div></div>
<div style="position:absolute;left:20px;right:20px;bottom:40px">
 <div class="kick">Durban · a story in four moves</div>
 <h1 style="font:800 44px/1 var(--sans);letter-spacing:-.035em;color:#fff;margin:14px 0 14px">Where would the city move you?</h1>
 <p style="font:17px/1.45 var(--serif);color:#dbe3ee;margin:0 0 22px">Pick a township to follow one family's journey.</p>
 <div class="glass" style="padding:6px 6px 6px 16px;display:flex;align-items:center;gap:10px;border-radius:14px"><span style="font-size:17px;color:#fff;flex:1">uMlazi</span><span class="btnw" style="font-size:15px;padding:12px 16px">Follow →</span></div>
 <div style="font-size:11px;color:rgba(255,255,255,.55);margin-top:16px">A story built from news reports, not an emergency service.</div></div>
<div class="note" style="right:14px;bottom:auto;top:70px">M01</div>""", 390, 844), (390, 844))
F["m05-button"] = (page(f"""
<div class="film" style="background-image:url(../img/film_5.5.jpg);background-position:46% 50%;filter:brightness(.55)"></div>
<div class="full" style="background:linear-gradient(transparent 30%,rgba(5,8,14,.9))"></div>
<div class="top" style="padding:0 18px;gap:10px"><div class="prog" style="margin:0;gap:6px"><i class="now" style="width:22px"></i><i style="width:22px"></i><i style="width:22px"></i><i style="width:22px"></i></div><div class="skip" style="margin-left:auto;font-size:11.5px;padding:5px 11px">Skip →</div></div>
<div style="position:absolute;left:20px;right:20px;bottom:56px;text-align:center">
 <div style="font:italic 500 30px/1.15 var(--serif);color:#fff;margin-bottom:28px">The water is at the roof.</div>
 <span class="btnred" style="font-size:19px;padding:17px 26px">They called for help →</span>
 <div style="color:rgba(255,255,255,.6);font-size:12.5px;margin-top:24px">Tap to see where the city sent them.</div></div>
<div class="note" style="right:14px;bottom:auto;top:70px">M05</div>""", 390, 844), (390, 844))

for name, v in F.items():
    html, (w, h) = (v if isinstance(v, tuple) else (v, (1600, 1000)))
    src = os.path.join(HERE, "src", name + ".html"); open(src, "w", encoding="utf-8").write(html)
    out = os.path.join(HERE, "frames", name + ".png")
    dpr = "2" if w < 600 else "1"
    subprocess.run([EDGE, "--headless", "--disable-gpu", "--hide-scrollbars", f"--window-size={w},{h}", f"--force-device-scale-factor={dpr}",
                    "--virtual-time-budget=4000", f"--screenshot={out}", "file:///" + src.replace("\\", "/")], capture_output=True)
    print(name, os.path.exists(out))
