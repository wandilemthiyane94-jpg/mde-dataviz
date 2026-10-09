# Check: with the injected clock, how fast can frames be captured, and does the map animation progress?
import sys, time, os
sys.path.insert(0, os.path.dirname(__file__))
from cdp import Browser
S = sys.argv[1]; HERE = os.path.dirname(os.path.abspath(__file__))
b = Browser(os.path.join(S, "prof_probe2"))
b.call("Page.addScriptToEvaluateOnNewDocument", source=open(os.path.join(HERE, "clock.js")).read())
b.go("http://localhost:8771/index.html#map", 3)
t0 = time.time()
for i in range(90):
    b.js("__adv(1000/30)")
    img = b.shot()
    if i in (0, 89): open(os.path.join(S, f"probe2_{i}.jpg"), "wb").write(img)
print("real s", round(time.time() - t0, 1), "page ms", b.js("performance.now()"))
b.close()
