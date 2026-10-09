# Records the 2-minute demo: drives the live site beat by beat with an injected frame clock, saving one
# screenshot per 1/30 s plus an event log (captions, cursor moves, clicks, cuts) for compose.py.
# Usage: python record.py <work_dir> [base_url]
import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cdp import Browser

WORK = sys.argv[1]; BASE = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8771/"
HERE = os.path.dirname(os.path.abspath(__file__)); RAW = os.path.join(WORK, "raw"); os.makedirs(RAW, exist_ok=True)
F = int(os.environ.get("FPS", 30))
b = Browser(os.path.join(WORK, "prof"))
b.call("Page.addScriptToEvaluateOnNewDocument", source=open(os.path.join(HERE, "clock.js")).read())
frame = 0; ev = []

def hold(sec):
    global frame
    for _ in range(round(sec * F)):
        b.js("__adv(1000/%d)" % F)
        open(os.path.join(RAW, "f%05d.jpg" % frame), "wb").write(b.shot())
        frame += 1

def cap(label, text): ev.append({"t": "cap", "f": frame, "label": label, "text": text})

def reveal(sel, dur=0.7):
    """Scroll the element's scrolling parent so it is fully in view, eased over dur seconds of recorded frames."""
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

t0 = time.time()
# 1 · The question (intro)
page("index.html")
cap("01 · The question", "When floods take a home in Durban, families are sent to “temporary” camps.")
hold(12)
# 2 · The pattern (opening map animation)
page("index.html?rec=1#map")
b.js("try{clearTimeout(vidTimer);vidAuto=true;}catch(e){}")      # keep the news video from autoplaying mid-shot
cap("02 · The pattern", "28 relocation sites. We mapped 12 against the city’s own flood line.")
hold(20)
# 3 · One camp
cap("03 · One camp", "Lulama Dingiswayo lost three children here in February 2025.")
hold(5)
click("#acc summary", after=1.0)
click('#acc .list button[data-id="lamontville"]', after=0.5)
cap("03 · One camp", "Her family was moved here in 2021. It is still “temporary” in 2026.")
hold(6.5)
# 4 · How people live
click('#panel .tabs button[data-t="conditions"]', after=0.3)
cap("04 · How people live", "Space per person, against the minimum humanitarian standard.")
hold(2.2)
if not click('#cstrip button[data-k="crowd"]', after=0):
    click('#panel .clist button[data-k="crowd"]', after=0)
hold(9)
# 5 · Will it flood again?
click('#panel .tabs button[data-t="risk"]', after=0.3)
cap("05 · Will it flood again?", "How far the camp sits from the city’s own flood line and the nearest stream.")
hold(6.5)
click('nav button[data-v="sim"]', after=0.3)
cap("05 · Will it flood again?", "Same rain as 2022. This is where the water goes.")
hold(2.5)
b.js("(()=>{const s=document.getElementById('smk'); s.value=6; s.dispatchEvent(new Event('input'));})()")
click("#smpb", after=0)
hold(13)
# 6 · What you can do
click('nav button[data-v="stories"]', after=0.3)
cap("06 · What you can do", "Every site is backed by real reporting.")
hold(4.5)
click('nav button[data-v="report"]', after=0.3)
cap("06 · What you can do", "Your report helps us advocate for better housing conditions.")
hold(8.5)
# 7 · Who it is for (end card; its own text, no caption)
page("end/index.html")
cap("", "")
hold(10)

json.dump({"fps": F, "frames": frame, "css_w": b.w, "css_h": b.h, "dsf": b.dsf, "events": ev}, open(os.path.join(WORK, "events.json"), "w"), indent=1)
print("frames", frame, "seconds", frame / F, "real min", round((time.time() - t0) / 60, 1))
b.close()
