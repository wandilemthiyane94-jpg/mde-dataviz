# Debug: after opening Flood Risk for the camp, are the live satellite tiles present, loaded and visible?
import sys, os, time, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cdp import Browser
S = sys.argv[1]; HERE = os.path.dirname(os.path.abspath(__file__))
b = Browser(os.path.join(S, "prof_probe3"), port=9341)
b.call("Page.addScriptToEvaluateOnNewDocument", source=open(os.path.join(HERE, "clock.js")).read())
b.go("http://localhost:8771/index.html?rec=1#map", 3)
for _ in range(200): b.js("__adv(100)")
b.js("select('lamontville',true)")
for _ in range(30): b.js("__adv(100)")
b.js("document.querySelector('#panel .tabs button[data-t=\"risk\"]').click()")
for _ in range(30): b.js("__adv(100)")
for _ in range(16): time.sleep(0.5); b.js("__adv(60)")
print(json.dumps(b.js("""(()=>{const t=document.getElementById('tiles'), im=[...t.querySelectorAll('img')];
 const cs=getComputedStyle(t), cv=getComputedStyle(document.getElementById('cvbg'));
 return {mode:typeof mode!=='undefined'?mode:null, z:view.z, n:im.length, loaded:im.filter(i=>i.complete&&i.naturalWidth).length,
   hidden:im.filter(i=>i.style.visibility==='hidden').length, display:cs.display, zt:cs.zIndex, zbg:cv.zIndex, op:cs.opacity,
   src:[...document.querySelectorAll('canvas')].map(c=>(c.id||c.className||'?')+':'+getComputedStyle(c).opacity+':'+getComputedStyle(c).filter)};})()"""), indent=1))
open(os.path.join(S, "probe3.jpg"), "wb").write(b.shot()); b.js("draw()"); b.js("__adv(50)"); open(os.path.join(S, "probe3b.jpg"), "wb").write(b.shot()); print(b.js("[...document.querySelectorAll('#tiles img')].slice(0,3).map(i=>i.style.cssText+' '+i.naturalWidth)"))
b.close()
