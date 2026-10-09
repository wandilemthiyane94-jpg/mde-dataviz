# Data-viz half of the 50/50 cut (record_viz.py), built on the helpers of record2.py.
# Version 2 of the demo: the mother's story first (the site's own illustrated film, clicked through at a
# storyteller's pace), then the film hands over to the real map, which measures her camp, then the end card.
# Usage: python record2.py <work_dir> [base_url]      (FPS=2 for a quick preview)
import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cdp import Browser

WORK = sys.argv[1]; BASE = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8771/"
HERE = os.path.dirname(os.path.abspath(__file__)); RAW = os.path.join(WORK, "raw"); os.makedirs(RAW, exist_ok=True)
F = int(os.environ.get("FPS", 30))
b = Browser(os.path.join(WORK, "prof"))
b.call("Page.addScriptToEvaluateOnNewDocument", source=open(os.path.join(HERE, "clock.js")).read())
frame = 0; ev = []; log = []; RATE = 1.0   # page-clock speed: 1.2 during the film, 1.0 on the map

def hold(sec):
    global frame
    for _ in range(round(sec * F)):
        b.js("__adv(%f)" % (1000 / F * RATE))
        open(os.path.join(RAW, "f%05d.jpg" % frame), "wb").write(b.shot())
        frame += 1

def cap(label, text): ev.append({"t": "cap", "f": frame, "label": label, "text": text})

def reveal(sel, dur=0.7):
    r = b.js("""(()=>{const e=document.querySelector(%s); if(!e) return null; let p=e.parentElement;
      while(p&&!(p.scrollHeight>p.clientHeight+2&&/(auto|scroll)/.test(getComputedStyle(p).overflowY))) p=p.parentElement;
      if(!p) return null; const er=e.getBoundingClientRect(), pr=p.getBoundingClientRect(); let d=0;
      if(er.bottom>pr.bottom-24) d=er.bottom-pr.bottom+48; else if(er.top<pr.top+8) d=er.top-pr.top-24;
      if(!d) return null; window.__sp=p; return [p.scrollTop, Math.max(0,Math.min(p.scrollHeight-p.clientHeight,p.scrollTop+d))];})()""" % json.dumps(sel))
    if not r: return
    n = max(1, round(dur * F))
    for i in range(1, n + 1):
        k = i / n; e = k * k * (3 - 2 * k)
        b.js("window.__sp.scrollTop=%f" % (r[0] + (r[1] - r[0]) * e)); hold(1 / F)

def click(sel, move=0.8, after=0.0):
    reveal(sel)
    c = b.center(sel)
    if not c: print("MISSING", sel); return False
    ev.append({"t": "move", "f": frame, "x": c[0], "y": c[1], "dur": move}); hold(move)
    ev.append({"t": "click", "f": frame, "x": c[0], "y": c[1]}); b.click_xy(*c)
    hold(after); return True

def page(url, settle=3.5):
    ev.append({"t": "cut", "f": frame}); b.go(BASE + url, settle)

def state():
    return b.js("""(()=>{const r=document.getElementById('intro'); if(!r) return {gone:true};
      const vis=e=>e&&e.getClientRects().length&&getComputedStyle(e).visibility!=='hidden';
      return {ended:r.dataset.ended==='1', cta:vis(r.querySelector('.ix-cta button')), next:vis(r.querySelector('.ix-nextb')),
        done:vis(r.querySelector('.ix-white[data-done]')), txt:(r.innerText||'').slice(0,400)};})()""")

t0 = time.time()
L = "The data"
page("index.html?rec=1#map")
b.js("try{clearTimeout(vidTimer);vidAuto=true;}catch(e){}")
cap(L, "28 temporary relocation sites, mapped against the city’s own 1-in-100-year flood line.")
hold(9)
cap(L, "11 of the 28 sit inside or within 250 m of that line.")
hold(5.5)
b.js("window.MAPANIM_P=1"); hold(1.4)
b.js("setYear(2022)")
cap("Flood years", "April 2022: the uMlazi River bursts its banks. The Lamontville camp floods.")
hold(6)
b.js("setYear(2026,true); endPulse()"); hold(0.4)
click("#acc summary", after=0.5)
click('#acc .list button[data-id="lamontville"]', after=0.3)
cap("Her camp", "Lamontville riverside camp, Gwala Street: 2021 to 2026, still “temporary”.")
hold(2.6)
click('#panel .tabs button[data-t="risk"]', after=0)
hold(1.2)
for _ in range(20): time.sleep(0.5); b.js('draw(); __adv(60)')
cap("Her camp, measured", "It sits 2 m from the city’s own 1-in-100-year flood line.")
hold(5.2)
click('#panel .tabs button[data-t="conditions"]', after=0.3)
if not click('#cstrip button[data-k="water"]', after=0): click('#panel .clist button[data-k="water"]', after=0)
cap("Her camp, measured", "About 100 households share one tap. The standard is one per 25 families.")
hold(5.5)
if not click('#cstrip button[data-k="crowd"]', after=0): click('#panel .clist button[data-k="crowd"]', after=0)
cap("Her camp, measured", "Nine people in one tin room. Even the official shelter gives 2.7 m² each, under the 3.5 m² minimum.")
hold(6.5)
click('nav button[data-v="sim"]', after=0.3)
cap("Her camp, measured", "Same rain as 2022. This is where the water goes.")
hold(1.5)
b.js("(()=>{const s=document.getElementById('smk'); s.value=8; s.dispatchEvent(new Event('input'));})()")
click("#smpb", after=0)
hold(7.5)
click('nav button[data-v="stories"]', after=0.3)
cap("A tool for advocates", "Every site is backed by real reporting, linked to the camps.")
hold(4.5)
click('nav button[data-v="report"]', after=0.3)
cap("A tool for advocates", "Residents report conditions over WhatsApp. Their reports become evidence.")
hold(6.5)
page("end/index.html", settle=4.5)
cap("", "")
hold(7)
json.dump({"fps": F, "frames": frame, "css_w": b.w, "css_h": b.h, "dsf": b.dsf, "events": ev, "log": log}, open(os.path.join(WORK, "events.json"), "w"), indent=1)
print("frames", frame, "seconds", frame / F, "real min", round((time.time() - t0) / 60, 1))
b.close()
