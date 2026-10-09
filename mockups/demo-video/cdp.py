# Minimal Chrome DevTools Protocol client for headless Edge: launch, evaluate, click, and screencast to disk.
import json, os, subprocess, threading, time, urllib.request, base64
import websocket

EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

class Browser:
    def __init__(self, prof, port=9333, w=1536, h=752, dsf=1.25, gpu=True):
        args = [EDGE, "--headless=new", f"--remote-debugging-port={port}", f"--user-data-dir={prof}",
                f"--window-size={w},{h}", "--hide-scrollbars", "--autoplay-policy=no-user-gesture-required",
                "--no-first-run", "--mute-audio", "--remote-allow-origins=*", "about:blank"]
        if not gpu: args[1:1] = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
        self.proc = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            try:
                tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list"))
                page = [t for t in tabs if t["type"] == "page"][0]; break
            except Exception: time.sleep(.2)
        self.ws = websocket.create_connection(page["webSocketDebuggerUrl"], max_size=None)
        self.id = 0; self.pending = {}; self.frames = []; self.rec = False; self.lock = threading.Lock(); self.budget = threading.Event()
        threading.Thread(target=self._read, daemon=True).start()
        self.call("Page.enable"); self.call("Runtime.enable")
        self.call("Emulation.setDeviceMetricsOverride", width=w, height=h, deviceScaleFactor=dsf, mobile=False)
        self.w, self.h, self.dsf = w, h, dsf

    def _read(self):
        while True:
            try: m = json.loads(self.ws.recv())
            except Exception: return
            if "id" in m:
                ev = self.pending.get(m["id"])
                if ev: ev[1] = m; ev[0].set()
            elif m.get("method") == "Emulation.virtualTimeBudgetExpired":
                self.budget.set()
            elif m.get("method") == "Page.screencastFrame":
                p = m["params"]
                if self.rec: self.frames.append((time.time(), base64.b64decode(p["data"])))
                self._send("Page.screencastFrameAck", sessionId=p["sessionId"])

    def _send(self, method, **params):
        with self.lock:
            self.id += 1; i = self.id
            self.ws.send(json.dumps({"id": i, "method": method, "params": params}))
        return i

    def call(self, method, **params):
        ev = [threading.Event(), None]
        with self.lock:
            self.id += 1; i = self.id; self.pending[i] = ev
            self.ws.send(json.dumps({"id": i, "method": method, "params": params}))
        ev[0].wait(30); return (ev[1] or {}).get("result", {})

    def js(self, expr):
        r = self.call("Runtime.evaluate", expression=expr, returnByValue=True, awaitPromise=True)
        return r.get("result", {}).get("value")

    def go(self, url, wait=2.0):
        self.call("Page.navigate", url=url); time.sleep(wait)

    def center(self, sel):
        return self.js("(()=>{const e=document.querySelector(%s); if(!e) return null; e.scrollIntoView({block:'nearest',inline:'nearest'}); const r=e.getBoundingClientRect(), x=r.left+r.width/2, y=r.top+r.height/2, h=document.elementFromPoint(x,y); if(!h||!(e===h||e.contains(h)||h.contains(e))) return null; return [x,y];})()" % json.dumps(sel))

    def click_xy(self, x, y):
        for t in ("mouseMoved", "mousePressed", "mouseReleased"):
            self.call("Input.dispatchMouseEvent", type=t, x=x, y=y, button="left" if t != "mouseMoved" else "none", clickCount=1)

    def tick(self, ms):
        """Let the page's clock run for exactly ms of virtual time (paused while fetches are pending), then stop."""
        self.budget.clear()
        self.call("Emulation.setVirtualTimePolicy", policy="pauseIfNetworkFetchesPending", budget=ms)
        return self.budget.wait(60)

    def shot(self, q=92):
        return base64.b64decode(self.call("Page.captureScreenshot", format="jpeg", quality=q)["data"])

    def start(self):
        self.rec = True
        self.call("Page.startScreencast", format="jpeg", quality=92, maxWidth=int(self.w*self.dsf), maxHeight=int(self.h*self.dsf), everyNthFrame=1)

    def stop(self):
        self.call("Page.stopScreencast"); self.rec = False

    def close(self):
        try: self.call("Browser.close")
        except Exception: pass
        self.proc.kill()
