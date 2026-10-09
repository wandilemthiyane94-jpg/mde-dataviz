# Cuts the no-cursor demo into one clip per scene, ending each where the recorder clicked "Next" (or the next
# site control), so a presenter can step through the story like the website. Clicks closer than MIN s apart merge.
# Usage: python split_scenes.py <work_dir> <full_nocursor.mp4> <out_dir> <ffmpeg>
import sys, os, json, subprocess
WORK, SRC, OUT, FF = sys.argv[1:5]
M = json.load(open(os.path.join(WORK, "events.json"))); F = M["fps"]; N = M["frames"]
MIN = 2.5
cuts = sorted({e["f"] for e in M["events"] if e["t"] in ("click", "cut") and e["f"] > 0})
bounds = [0]
for c in cuts:
    if (c - bounds[-1]) / F >= MIN: bounds.append(c)
if (N - bounds[-1]) / F < MIN: bounds.pop()
bounds.append(N)
os.makedirs(OUT, exist_ok=True)
for k in range(len(bounds) - 1):
    a, b = bounds[k], bounds[k + 1]
    out = os.path.join(OUT, "scene%02d.mp4" % (k + 1))
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", SRC, "-vf", f"trim=start_frame={a}:end_frame={b},setpts=PTS-STARTPTS",
                    "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart", out], check=True)
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", out, "-frames:v", "1", out[:-4] + "_first.jpg"], check=True)
    print("scene%02d" % (k + 1), "%.1fs" % (a / F), "->", "%.1fs" % (b / F))
