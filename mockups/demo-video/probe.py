# Quick check: how many frames per second does the screencast deliver on the map page?
import sys, time, os
sys.path.insert(0, os.path.dirname(__file__))
from cdp import Browser
S = sys.argv[1]
b = Browser(os.path.join(S, "prof_probe"), gpu=("--sw" not in sys.argv))
b.go("http://localhost:8771/index.html#map", 1.0)
b.start(); time.sleep(8); b.stop()
ts = [f[0] for f in b.frames]
print("frames", len(ts), "fps %.1f" % (len(ts) / max(1e-3, ts[-1] - ts[0])) if ts else "")
if b.frames: open(os.path.join(S, "probe_last.jpg"), "wb").write(b.frames[-1][1])
b.close()
