# Builds the 50/50 cut: chosen story scenes from the full story recording, then the data-viz recording.
# Writes a new work dir (raw frames + merged events) for compose.py. Usage: python splice.py <story_work> <viz_work> <out_work>
import sys, os, json, shutil
ST, VZ, OUT = sys.argv[1:4]
KEEP = [1, 2, 3, 4, 6, 7, 9, 11, 12]   # her first two moves, the floods and the loss; the presenter tells the rest
M = json.load(open(os.path.join(ST, "events.json"))); F = M["fps"]; N = M["frames"]
cuts = sorted({e["f"] for e in M["events"] if e["t"] in ("click", "cut") and e["f"] > 0}); b = [0]
for c in cuts:
    if (c - b[-1]) / F >= 2.5: b.append(c)
if (N - b[-1]) / F < 2.5: b.pop()
b.append(N)
os.makedirs(os.path.join(OUT, "raw"), exist_ok=True)
ev, n = [{"t": "cap", "f": 0, "label": "Illustration", "text": "The drawn family stands for families of the Gwala Street camp. Their moves follow GroundUp’s reporting."}], 0
prev = None
for k in KEEP:
    a, z = b[k - 1], b[k]
    if prev is not None and prev != k - 1: ev.append({"t": "cut", "f": n})      # a soft dip where scenes were removed
    for e in M["events"]:
        if a <= e["f"] < z and e["t"] in ("move", "click"): ev.append(dict(e, f=e["f"] - a + n))
    for f in range(a, z):
        shutil.copyfile(os.path.join(ST, "raw", "f%05d.jpg" % f), os.path.join(OUT, "raw", "f%05d.jpg" % n)); n += 1
    prev = k
STORY_LEN = 45.0   # her story ends at 0:45; the loss frame holds until then
last = os.path.join(OUT, "raw", "f%05d.jpg" % (n - 1))
while n < round(STORY_LEN * F):
    shutil.copyfile(last, os.path.join(OUT, "raw", "f%05d.jpg" % n)); n += 1
story = n
V = json.load(open(os.path.join(VZ, "events.json")))
for e in V["events"]: ev.append(dict(e, f=e["f"] + story))
for f in range(V["frames"]):
    shutil.copyfile(os.path.join(VZ, "raw", "f%05d.jpg" % f), os.path.join(OUT, "raw", "f%05d.jpg" % n)); n += 1
json.dump(dict(M, frames=n, events=ev), open(os.path.join(OUT, "events.json"), "w"), indent=1)
print("story %.1fs  viz %.1fs  total %.1fs" % (story / F, V["frames"] / F, n / F))
