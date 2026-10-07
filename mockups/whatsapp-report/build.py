# WhatsApp reporting mockups (design only; not part of the website). Writes src/*.html and renders frames/*.png with headless Edge.
import os, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
FONTS = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Newsreader:ital,opsz,wght@0,6..72,400;1,6..72,400&family=IBM+Plex+Mono:wght@400;500;600&display=swap">'
CSS = """
:root{--bg:#070B12;--ink:#F8FAFC;--txt:#E2E8F0;--mut:#9AA6B8;--dim:#64748B;--line:rgba(255,255,255,.12);--amber:#F5A524;--site:#FBC900;--red:#E5484D;--green:#25D366;
 --sans:Inter,"Helvetica Neue",Arial,sans-serif;--serif:Newsreader,Georgia,serif;--mono:"IBM Plex Mono",Consolas,monospace}
*{box-sizing:border-box}html,body{margin:0;height:100%;background:var(--bg);color:var(--txt);font:15px/1.45 var(--sans);overflow:hidden}
.kick{font:600 11px var(--mono);letter-spacing:.2em;text-transform:uppercase;color:var(--amber)}
.note{position:absolute;right:20px;bottom:16px;font:600 10px var(--mono);letter-spacing:.12em;text-transform:uppercase;color:#0B0F19;background:var(--site);padding:4px 8px;border-radius:3px;z-index:9}
.ex{position:absolute;left:20px;bottom:16px;font:10.5px var(--mono);color:rgba(255,255,255,.55);z-index:9}
/* phone */
.wa{position:absolute;left:0;top:0;width:390px;height:844px;background:#0B141A;display:flex;flex-direction:column;font-family:var(--sans)}
.wa-top{height:92px;padding:40px 14px 0;background:#202C33;display:flex;align-items:center;gap:10px;color:#E9EDEF}
.wa-av{width:38px;height:38px;border-radius:50%;background:#FBC900;display:grid;place-items:center}
.wa-av svg{width:22px;height:26px}
.wa-name{font-weight:600;font-size:16px}.wa-sub{font-size:12px;color:#8696A0}
.wa-body{flex:1;padding:12px 10px;display:flex;flex-direction:column;justify-content:flex-end;gap:6px;overflow:hidden;background:#0B141A radial-gradient(rgba(255,255,255,.025) 1px,transparent 1px) 0 0/18px 18px}
.b{max-width:82%;padding:7px 9px 18px;border-radius:8px;font-size:14px;line-height:1.38;color:#E9EDEF;position:relative;white-space:pre-line}
.b.in{background:#202C33;align-self:flex-start;border-top-left-radius:2px}
.b.out{background:#005C4B;align-self:flex-end;border-top-right-radius:2px}
.b time{position:absolute;right:8px;bottom:3px;font-size:10.5px;color:rgba(233,237,239,.6)}
.b b{font-weight:700}
.list{align-self:flex-start;max-width:82%;background:#202C33;border-radius:8px;overflow:hidden;font-size:14px;color:#53BDEB}
.list div{padding:9px 12px;border-top:1px solid rgba(255,255,255,.07);text-align:center}
.btns{align-self:flex-start;display:grid;gap:4px;max-width:82%;width:82%}
.btns div{background:#202C33;border-radius:8px;padding:9px;text-align:center;color:#53BDEB;font-size:14px}
.ph{width:220px;height:150px;border-radius:6px;background:repeating-linear-gradient(135deg,#2A3942 0 10px,#24323A 10px 20px);display:grid;place-items:center;color:#8696A0;font:500 11px var(--mono);margin-bottom:4px}
.day{align-self:center;background:#182229;color:#8696A0;font-size:12px;padding:4px 10px;border-radius:6px;margin:4px 0}
.sys{align-self:center;background:#182229;color:#FFD279;font-size:11.5px;padding:6px 10px;border-radius:6px;text-align:center;max-width:90%}
.wa-in{height:62px;background:#202C33;display:flex;align-items:center;gap:10px;padding:0 10px 8px}
.wa-in span{flex:1;background:#2A3942;border-radius:20px;padding:10px 14px;color:#8696A0;font-size:14px}
.wa-in i{width:42px;height:42px;border-radius:50%;background:#00A884;display:block}
"""
PIN = '<svg viewBox="0 0 56 70"><path d="M28 68C28 68 4 42 4 26a24 24 0 0148 0c0 16-24 42-24 42z" fill="#0B0F19"/><circle cx="21" cy="19" r="4" fill="#FBC900"/><circle cx="35" cy="19" r="4" fill="#FBC900"/><circle cx="28" cy="31" r="3" fill="#FBC900"/><path d="M14 38v-6a7 7 0 0114 0v6zM28 38v-6a7 7 0 0114 0v6z" fill="#FBC900"/></svg>'
def page(body, w, h): return f'<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width={w}">{FONTS}<style>{CSS}</style></head><body>{body}</body></html>'
def qr(size=220, seed=7):
    # decorative QR-like pattern (not a working code) with the three finder squares
    import random; r = random.Random(seed); n = 29; c = size / n; cells = []
    def finder(x, y): return f'<rect x="{x*c}" y="{y*c}" width="{7*c}" height="{7*c}" fill="#0B0F19"/><rect x="{(x+1)*c}" y="{(y+1)*c}" width="{5*c}" height="{5*c}" fill="#fff"/><rect x="{(x+2)*c}" y="{(y+2)*c}" width="{3*c}" height="{3*c}" fill="#0B0F19"/>'
    for i in range(n):
        for j in range(n):
            if (i < 8 and j < 8) or (i < 8 and j > n-9) or (i > n-9 and j < 8): continue
            if r.random() < .48: cells.append(f'<rect x="{j*c:.2f}" y="{i*c:.2f}" width="{c+.3:.2f}" height="{c+.3:.2f}" fill="#0B0F19"/>')
    return f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}"><rect width="{size}" height="{size}" fill="#fff"/>{"".join(cells)}{finder(0,0)}{finder(n-7,0)}{finder(0,n-7)}</svg>'
def phone(chat, note):
    return page(f'<div class="wa"><div class="wa-top"><span style="font-size:20px">‹</span><div class="wa-av">{PIN}</div><div><div class="wa-name">Moved Into the Water</div><div class="wa-sub">Report line · research project</div></div></div><div class="wa-body">{chat}</div><div class="wa-in"><span>Message</span><i></i></div></div>', 390, 844)
B = lambda side, txt, t="10:42": f'<div class="b {side}">{txt}<time>{t}</time></div>'

F = {}
F["01-poster"] = (page(f"""
<div style="position:absolute;inset:0;background:linear-gradient(180deg,#8B9AA1,#6D7C83);"></div>
<div style="position:absolute;inset:0;background:repeating-linear-gradient(90deg,rgba(0,0,0,.08) 0 2px,transparent 2px 70px)"></div>
<div style="position:absolute;left:50%;top:50%;width:520px;height:735px;transform:translate(-50%,-50%) rotate(-1.2deg);background:#F7F4EC;box-shadow:0 30px 70px rgba(0,0,0,.45);padding:44px 44px 36px;color:#0B0F19;display:flex;flex-direction:column">
 <div style="display:flex;align-items:center;gap:10px"><div style="width:34px;height:42px">{PIN.replace('#0B0F19','#111').replace('#FBC900','#FBC900')}</div><div style="font:700 15px var(--sans)">Moved Into the Water</div><div style="margin-left:auto;font:600 10px var(--mono);letter-spacing:.14em;color:#8a6a00">RESEARCH PROJECT</div></div>
 <div style="font:800 52px/0.98 var(--sans);letter-spacing:-.03em;margin:34px 0 14px">How are things at your site?</div>
 <div style="font:18px/1.45 var(--serif);color:#333;margin-bottom:26px">Tell us about water, toilets, power, safety or flooding. Scan with your phone camera to open WhatsApp.</div>
 <div style="display:flex;gap:24px;align-items:center"><div style="padding:10px;background:#fff;border:3px solid #0B0F19;border-radius:10px">{qr(190)}</div>
  <div style="display:grid;gap:12px;font-size:14px;color:#222"><div><b style="display:block;font-size:22px;color:#0B0F19">1</b>Scan the code</div><div><b style="display:block;font-size:22px;color:#0B0F19">2</b>Answer a few questions</div><div><b style="display:block;font-size:22px;color:#0B0F19">3</b>A researcher may call you</div></div></div>
 <div style="margin-top:auto;border-top:2px solid #0B0F19;padding-top:14px;font-size:12.5px;line-height:1.45;color:#333"><b>Your name is never shown.</b> Your number is only used by researchers to check your report. Free to send on WhatsApp data. This is not an emergency line: in danger, call emergency services.<br><span style="font:600 11px var(--mono);color:#666">Translate with residents: isiZulu · English</span></div>
</div>
<div style="position:absolute;right:170px;bottom:40px;width:250px;height:500px;border-radius:38px;background:#111;border:6px solid #2a2a2a;transform:rotate(8deg);box-shadow:0 30px 60px rgba(0,0,0,.5);overflow:hidden">
 <div style="position:absolute;inset:0;background:#2b2b2b;display:grid;place-items:center"><div style="width:170px;height:170px;border:3px solid #FBC900;border-radius:14px;display:grid;place-items:center;background:rgba(255,255,255,.05)"><div style="transform:scale(.62)">{qr(220)}</div></div></div>
 <div style="position:absolute;left:14px;right:14px;bottom:24px;background:rgba(255,255,255,.92);border-radius:12px;padding:10px 12px;font:600 12.5px var(--sans);color:#111">Open in WhatsApp<div style="font-weight:400;color:#555;font-size:11.5px">wa.me/27··· · "Hi, I want to report…"</div></div></div>
<div class="ex">Poster mockup · QR pattern is decorative, not a working code · number to be set</div><div class="note">01 · Poster at the site</div>""", 1600, 1000), (1600, 1000))

F["02-chat-start"] = (phone(
 '<div class="day">Today</div>' + B("out", "Hi, I want to report conditions at my site", "10:41") +
 B("in", "Sawubona! Thank you for reaching out. 🙏\n\nThis line is run by a student research project about temporary relocation sites in Durban.\n\n<b>Your name will never be published.</b> A researcher may call you to check your report. You can stop at any time by typing STOP.", "10:41") +
 '<div class="btns"><div>✅ I agree, continue</div><div>Read how we use reports</div></div>' +
 B("out", "✅ I agree, continue", "10:42") +
 B("in", "Which site do you live at?", "10:42") +
 '<div class="list"><div>📍 Choose your site</div></div>' +
 B("out", "Lamontville riverside camp (Gwala Street)", "10:42"),
 "02 · Consent and site"), (390, 844))

F["03-chat-report"] = (phone(
 B("in", "What is your report about?", "10:43") +
 '<div class="btns"><div>💧 Water</div><div>🚻 Toilets and washing</div><div>⚡ Electricity</div><div>🌊 Flooding</div><div>More options</div></div>' +
 B("out", "💧 Water", "10:43") +
 B("in", "Tell us what is happening, in your own words. You can send a voice note too.", "10:43") +
 B("out", "[Example message] The tap has not worked since Monday. We are carrying water from the next street.", "10:45") +
 B("in", "Thank you. Do you have a photo or video? (Please avoid faces.)", "10:45") +
 '<div class="b out" style="padding:4px 4px 18px"><div style="position:relative;width:230px;height:154px;border-radius:6px;overflow:hidden;margin-bottom:4px;background:url(../img/gu_lamontville_camp_2022.jpg) center/cover"><span style="position:absolute;left:5px;bottom:5px;font:500 8.5px var(--mono);background:rgba(0,0,0,.6);color:#ddd;padding:1px 5px;border-radius:3px">Example photo · Nokulunga Majola / GroundUp</span></div><time>10:46</time></div>' + B("out", "[Example] This is our part of the camp", "10:46"),
 "03 · Topic, words, photo"), (390, 844))

F["04-chat-done"] = (phone(
 B("in", "Can a researcher call you on this number to check the details?", "10:46") +
 '<div class="btns"><div>📞 Yes, you can call me</div><div>No, just send the report</div></div>' +
 B("out", "📞 Yes, you can call me", "10:47") +
 B("in", "Received ✅\nYour reference: <b>LMT-0412</b>\n\nWhat happens next:\n1. A researcher reviews it, usually within 3 days.\n2. They may call you to check.\n3. Once checked, the condition is shown on the map for your site, without your name or number.\n\nType NEW to send another report.", "10:47") +
 '<div class="sys">🔒 Your number is stored privately and only seen by the research team.</div>',
 "04 · Confirmation"), (390, 844))

REV = """
<div style="position:absolute;inset:0;display:grid;grid-template-columns:240px 420px 1fr;background:#0B1018">
 <aside style="border-right:1px solid var(--line);padding:22px 18px;display:grid;gap:6px;align-content:start">
  <div style="font:700 16px var(--sans);color:#fff;margin-bottom:14px">Review queue</div>
  {nav}
  <div style="margin-top:24px" class="kick">Sources</div>
  <div style="font-size:13px;color:var(--mut)">WhatsApp <b style="color:#fff">8</b> · Web form <b style="color:#fff">3</b></div>
  <div style="margin-top:24px;font-size:11.5px;color:var(--dim);line-height:1.5">Visible to the research team only. Phone numbers are never published.</div>
 </aside>
 <section style="border-right:1px solid var(--line);padding:18px 0;overflow:hidden">
  <div style="padding:0 18px 12px;display:flex;gap:8px"><span style="flex:1;background:#121a26;border:1px solid var(--line);border-radius:8px;padding:8px 12px;color:var(--dim);font-size:13px">Search reports</span><span style="border:1px solid var(--line);border-radius:8px;padding:8px 12px;font-size:13px">All sites ▾</span></div>
  {rows}
 </section>
 <main style="padding:24px 30px;display:grid;gap:16px;align-content:start">
  <div style="display:flex;align-items:center;gap:12px"><div><div class="kick">LMT-0412 · via WhatsApp · today 10:47</div><div style="font:700 26px var(--sans);color:#fff;margin-top:6px">Water · Lamontville riverside camp</div></div><span style="margin-left:auto;font:600 12px var(--sans);padding:5px 11px;border-radius:999px;background:rgba(245,165,36,.15);color:#F5A524;border:1px solid rgba(245,165,36,.5)">New</span></div>
  <div style="display:flex;gap:6px;font:500 12px var(--mono)">{steps}</div>
  <div style="display:grid;grid-template-columns:1fr 260px;gap:16px">
   <div style="background:#121a26;border:1px solid var(--line);border-radius:10px;padding:16px 18px;display:grid;gap:10px">
    <div class="kick" style="color:var(--mut)">Resident's words</div>
    <div style="font:19px/1.45 var(--serif);color:#fff">"[Example message] The tap has not worked since Monday. We are carrying water from the next street."</div>
    <div style="font-size:12.5px;color:var(--mut)">Language: English · voice note: none · call-back: <b style="color:#4ade80">yes</b></div>
   </div>
   <div style="border-radius:10px;overflow:hidden;border:1px solid var(--line)"><div style="height:170px;background:repeating-linear-gradient(135deg,#1c2733 0 12px,#18222d 12px 24px);display:grid;place-items:center;color:var(--dim);font:500 11px var(--mono)">PHOTO · EXAMPLE</div><div style="padding:8px 10px;font-size:12px;color:var(--mut)">☐ Faces checked and blurred</div></div>
  </div>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
   <div style="background:#121a26;border:1px solid var(--line);border-radius:10px;padding:14px 18px">
    <div class="kick" style="color:var(--mut)">Contact (private)</div>
    <div style="display:flex;align-items:center;gap:12px;margin-top:10px"><span style="font:600 18px var(--mono);color:#fff">+27 •• ••• •• 37</span><span style="border:1px solid var(--line);border-radius:8px;padding:6px 10px;font-size:12.5px">Reveal to call</span></div>
    <div style="font-size:12px;color:var(--dim);margin-top:8px">Revealing is logged. Never shared outside the team.</div></div>
   <div style="background:#121a26;border:1px solid var(--line);border-radius:10px;padding:14px 18px">
    <div class="kick" style="color:var(--mut)">Researcher notes</div>
    <div style="font-size:13.5px;color:var(--dim);margin-top:10px">Add notes from the call…</div></div>
  </div>
  <div style="display:flex;gap:10px"><span style="background:#fff;color:#0B0F19;font-weight:600;border-radius:8px;padding:11px 18px">Mark verified after call</span><span style="border:1px solid var(--line);border-radius:8px;padding:11px 18px">Publish to map</span><span style="border:1px solid rgba(229,72,77,.5);color:#ff7b75;border-radius:8px;padding:11px 18px;margin-left:auto">Reject</span></div>
 </main>
</div>"""
nav = "".join(f'<div style="display:flex;justify-content:space-between;padding:9px 12px;border-radius:8px;font-size:14px;{"background:rgba(255,255,255,.07);color:#fff" if i==0 else "color:var(--mut)"}"><span>{a}</span><b>{b}</b></div>' for i,(a,b) in enumerate([("New","5"),("Calling","3"),("Verified","2"),("Published","14"),("Rejected","1")]))
rowsd = [("LMT-0412","Water","Lamontville riverside camp","WhatsApp · 10:47",True),("LMT-0409","Flooding","Lamontville riverside camp","WhatsApp · yesterday",False),("KWD-0118","Toilets","KwaDabeka hall","Web form · yesterday",False),("UMB-0061","Safety","Umbilo residence","WhatsApp · Mon",False),("GWL-0233","Electricity","Larger Gwala Street camp","WhatsApp · Mon",False)]
rows = "".join(f'<div style="padding:13px 18px;border-top:1px solid var(--line);{"background:rgba(251,201,0,.06);box-shadow:inset 3px 0 0 #FBC900" if sel else ""}"><div style="display:flex;justify-content:space-between;font:500 11.5px var(--mono);color:var(--mut)"><span>{r}</span><span>{src}</span></div><div style="color:#fff;font-weight:600;margin-top:4px">{t} · {s}</div><div style="font-size:12.5px;color:var(--dim);margin-top:2px">Example report text…</div></div>' for r,t,s,src,sel in rowsd)
steps = "".join(f'<span style="padding:5px 10px;border-radius:999px;{"background:#F5A524;color:#0B0F19" if i==0 else "border:1px solid var(--line);color:var(--mut)"}">{x}</span>{"<span style=color:var(--dim)>→</span>" if i<3 else ""}' for i,x in enumerate(["New","Called","Verified","Published"]))
F["05-review"] = (page(REV.format(nav=nav, rows=rows, steps=steps) + '<div class="ex">Example data for design only · no real residents or reports</div><div class="note">05 · Researcher review</div>', 1600, 1000), (1600, 1000))

F["06-on-map"] = (page("""
<div style="position:absolute;inset:0;background:url(../img/conditions.png) center/cover;filter:brightness(.55)"></div>
<div style="position:absolute;right:22px;top:88px;width:430px;background:rgba(12,17,27,.95);border:1px solid var(--line);border-radius:12px;padding:20px 22px;display:grid;gap:12px;box-shadow:0 20px 60px rgba(0,0,0,.5)">
 <div class="kick">Community reports · Lamontville riverside camp</div>
 <div style="font:700 24px/1.15 var(--sans);color:#fff">What residents are reporting</div>
 <div style="border:1px solid rgba(255,255,255,.14);border-radius:10px;padding:14px 16px;display:grid;gap:8px">
  <div style="display:flex;align-items:center;gap:8px"><span style="width:9px;height:9px;border-radius:50%;background:#ff6b5e"></span><b style="color:#fff">Water</b><span style="margin-left:auto;font:600 11px var(--mono);color:#4ade80;border:1px solid rgba(74,222,128,.5);border-radius:999px;padding:2px 8px">✓ Verified by phone</span></div>
  <div style="font:17px/1.45 var(--serif);color:#E2E8F0">"[Example] The tap has not worked since Monday. We are carrying water from the next street."</div>
  <div style="font:12px var(--mono);color:var(--dim)">A resident · via WhatsApp · Oct 2026</div></div>
 <div style="border:1px solid rgba(255,255,255,.1);border-radius:10px;padding:12px 16px;display:flex;align-items:center;gap:8px;color:var(--mut);font-size:13.5px"><span style="width:9px;height:9px;border-radius:50%;background:#F5A524"></span>Flooding · 2 reports this month <span style="margin-left:auto">›</span></div>
 <div style="font-size:12px;color:var(--dim);line-height:1.45">Reports are checked by the research team before they appear. Names and numbers are never shown.</div>
 <div style="display:flex;align-items:center;gap:14px;border-top:1px solid var(--line);padding-top:12px">
  <div style="width:64px;height:64px;padding:4px;background:#fff;border-radius:6px">QR</div>
  <div style="font-size:13px;color:var(--txt)"><b style="color:#fff">Live at this site?</b><br>Scan to report on WhatsApp</div></div>
</div>
<div style="position:absolute;left:340px;top:140px;background:rgba(10,15,24,.85);border:1px solid var(--line);border-radius:999px;padding:8px 14px;color:#fff;font-size:13px;display:flex;gap:8px;align-items:center"><span style="width:8px;height:8px;border-radius:50%;background:#25D366"></span>New layer: community reports</div>
<div class="ex">Example report for design only · background: current Conditions page</div><div class="note">06 · On the map</div>""".replace('<div style="width:64px;height:64px;padding:4px;background:#fff;border-radius:6px">QR</div>', '<div style="width:64px;height:64px;padding:3px;background:#fff;border-radius:6px">'+qr(58,3)+'</div>'), 1600, 1000), (1600, 1000))

for name, (html, (w, h)) in F.items():
    src = os.path.join(HERE, "src", name + ".html"); open(src, "w", encoding="utf-8").write(html)
    out = os.path.join(HERE, "frames", name + ".png")
    subprocess.run([EDGE, "--headless", "--disable-gpu", "--hide-scrollbars", f"--window-size={max(w,520)},{h}", f"--force-device-scale-factor={2 if w < 600 else 1}",
                    "--virtual-time-budget=4000", f"--screenshot={out}", "file:///" + src.replace("\\", "/")], capture_output=True)
    if w < 600:
        from PIL import Image
        im = Image.open(out); im.crop((0, 0, w * 2, h * 2)).save(out)
    print(name, os.path.exists(out))
