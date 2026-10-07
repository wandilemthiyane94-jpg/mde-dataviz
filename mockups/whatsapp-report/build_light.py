# Light-theme WhatsApp chat screens at iPhone size (390 x 844) for the Report page. Example content only.
import os, subprocess
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
OUT = os.path.join(HERE, "light"); os.makedirs(OUT, exist_ok=True)
CSS = """
*{box-sizing:border-box}html,body{margin:0;background:#fff;font-family:-apple-system,"SF Pro Text","Segoe UI",Inter,Arial,sans-serif;overflow:hidden}
.ph{position:absolute;left:0;top:0;width:390px;height:844px;display:flex;flex-direction:column;background:#EFEAE2}
.sb{height:47px;display:flex;align-items:flex-end;justify-content:space-between;padding:0 26px 8px 34px;font-weight:600;font-size:16px;color:#000;background:#F6F6F6}
.sb .ic{display:flex;gap:6px;align-items:center}
.sb .ic i{display:block;background:#000;border-radius:2px}
.hd{height:58px;display:flex;align-items:center;gap:10px;padding:0 12px;background:#F6F6F6;border-bottom:1px solid #d8d8d8;color:#111B21}
.hd .bk{color:#007AFF;font-size:30px;line-height:1;margin-top:-4px}
.av{width:38px;height:38px;border-radius:50%;background:#FBC900;display:grid;place-items:center;flex:none}
.av svg{width:20px;height:24px}
.nm{font-weight:600;font-size:16px}.st{font-size:12px;color:#667781}
.hd .call{margin-left:auto;display:flex;gap:20px;color:#007AFF;font-size:20px}
.bd{flex:1;padding:10px 12px;display:flex;flex-direction:column;justify-content:flex-end;gap:5px;overflow:hidden;
 background:#EFEAE2 radial-gradient(rgba(0,0,0,.035) 1.2px,transparent 1.3px) 0 0/20px 20px}
.day{align-self:center;background:#fff;color:#54656F;font-size:12px;padding:5px 12px;border-radius:8px;box-shadow:0 1px .5px rgba(11,20,26,.13);margin-bottom:4px}
.enc{align-self:center;background:#FFEECD;color:#54656F;font-size:11.5px;line-height:1.35;padding:6px 10px;border-radius:8px;text-align:center;max-width:88%;margin-bottom:4px}
.b{max-width:80%;padding:6px 8px 16px 9px;border-radius:8px;font-size:15px;line-height:1.32;color:#111B21;position:relative;box-shadow:0 1px .5px rgba(11,20,26,.13);white-space:pre-line}
.b.in{background:#fff;align-self:flex-start;border-top-left-radius:0}
.b.out{background:#D9FDD3;align-self:flex-end;border-top-right-radius:0}
.b time{position:absolute;right:7px;bottom:3px;font-size:11px;color:#667781}
.b.out time::after{content:" ✓✓";color:#53BDEB;letter-spacing:-3px}
.bt{align-self:flex-start;width:80%;display:grid;gap:3px}
.bt div{background:#fff;border-radius:8px;padding:9px;text-align:center;color:#027EB5;font-size:15px;box-shadow:0 1px .5px rgba(11,20,26,.13)}
.pic{width:236px;height:160px;border-radius:6px;background:center/cover;margin-bottom:3px;position:relative}
.pic span{position:absolute;left:5px;bottom:5px;font-size:9px;background:rgba(0,0,0,.55);color:#fff;padding:1px 5px;border-radius:3px}
.vn{display:flex;align-items:center;gap:8px;width:230px;padding:2px 0 4px}
.vn b{width:30px;height:30px;border-radius:50%;background:#00A884;display:grid;place-items:center;color:#fff;font-size:12px}
.vn i{flex:1;height:22px;background:repeating-linear-gradient(90deg,#8fa59a 0 2px,transparent 2px 5px);-webkit-mask:linear-gradient(transparent 30%,#000 30%,#000 70%,transparent 70%)}
.ft{height:84px;background:#F6F6F6;display:grid;grid-template-columns:28px 1fr 28px;gap:10px;align-items:center;padding:8px 12px 34px}
.ft .pl{color:#007AFF;font-size:28px;line-height:1;text-align:center}
.ft .box{height:34px;border-radius:18px;background:#fff;border:1px solid #e1e1e1}
.ft .cam{width:24px;height:18px;border:2px solid #007AFF;border-radius:5px;position:relative;justify-self:center}
.ft .cam::after{content:"";position:absolute;left:6px;top:3px;width:8px;height:8px;border:2px solid #007AFF;border-radius:50%}
.ex{position:absolute;left:0;right:0;bottom:12px;text-align:center;font-size:10px;color:#8696A0}
.home{position:absolute;left:50%;bottom:6px;transform:translateX(-50%);width:134px;height:5px;border-radius:3px;background:#000;opacity:.85}
"""
PIN = '<svg viewBox="0 0 56 70"><path d="M28 68C28 68 4 42 4 26a24 24 0 0148 0c0 16-24 42-24 42z" fill="#0B0F19"/><circle cx="21" cy="19" r="4" fill="#FBC900"/><circle cx="35" cy="19" r="4" fill="#FBC900"/><path d="M14 38v-6a7 7 0 0114 0v6zM28 38v-6a7 7 0 0114 0v6z" fill="#FBC900"/></svg>'
B = lambda side, t, tm: f'<div class="b {side}">{t}<time>{tm}</time></div>'
def phone(body):
    return ('<!doctype html><html><head><meta charset="utf-8"><style>' + CSS + '</style></head><body><div class="ph">'
            '<div class="sb"><span>9:41</span><span class="ic"><svg width="18" height="12" viewBox="0 0 18 12"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5" width="3" height="7" rx="1"/><rect x="10" y="2.5" width="3" height="9.5" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg><svg width="16" height="12" viewBox="0 0 16 12"><path d="M8 11.5l2.4-2.6a3.4 3.4 0 00-4.8 0zM3.6 6.8a6.3 6.3 0 018.8 0l1.4-1.5a8.4 8.4 0 00-11.6 0zM.4 3.4a10.8 10.8 0 0115.2 0L17 2A12.8 12.8 0 00-1 2z"/></svg><svg width="26" height="12" viewBox="0 0 26 12"><rect x=".5" y=".5" width="22" height="11" rx="3" fill="none" stroke="#000" opacity=".4"/><rect x="2" y="2" width="17" height="8" rx="2"/><rect x="23.5" y="4" width="1.8" height="4" rx="1" opacity=".4"/></svg></span></div>'
            '<div class="hd"><span class="bk">‹</span><div class="av">' + PIN + '</div><div><div class="nm">Moved Into the Water</div><div class="st">Report line · research project</div></div><div class="call"><svg width="24" height="16" viewBox="0 0 24 16" fill="none" stroke="#007AFF" stroke-width="1.8"><rect x="1" y="2" width="15" height="12" rx="3"/><path d="M16 7l6-4v10l-6-4"/></svg><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#007AFF" stroke-width="1.8"><path d="M5 3h4l2 5-2.5 1.5a11 11 0 006 6L16 13l5 2v4a2 2 0 01-2 2A17 17 0 013 5a2 2 0 012-2z"/></svg></div></div>'
            '<div class="bd">' + body + '</div><div class="ft"><span class="pl">+</span><span class="box"></span><span class="cam"></span></div><div class="ex">Example conversation for illustration</div><div class="home"></div></div></body></html>')
PHOTO = "file:///" + os.path.join(HERE, "img", "gu_lamontville_camp_2022.jpg").replace("\\", "/")
S = {
"01-start": '<div class="day">Today</div><div class="enc">🔒 Your name is never shown on the map.</div>'
  + B("out", "Hi, I want to report conditions at my site", "10:41")
  + B("in", "Sawubona! 👋 This line is run by a student research project on Durban’s relocation sites.\n\nA researcher may call you to check your report. Type STOP any time.", "10:41")
  + '<div class="bt"><div>I agree, continue</div><div>How we use reports</div></div>'
  + B("out", "I agree, continue", "10:42")
  + B("in", "Which site do you live at?", "10:42")
  + B("out", "Lamontville riverside camp", "10:42"),
"02-report": B("in", "What is your report about?", "10:43")
  + '<div class="bt"><div>💧 Water</div><div>🚻 Toilets and washing</div><div>⚡ Electricity</div><div>🌊 Flooding</div></div>'
  + B("out", "💧 Water", "10:43")
  + B("in", "Tell us what is happening. You can send a voice note or photo.", "10:43")
  + '<div class="b out"><div class="vn"><b>▶</b><i></i><small style="font-size:12px;color:#667781">0:21</small></div><time>10:45</time></div>'
  + f'<div class="b out" style="padding:3px 3px 16px"><div class="pic" style="background-image:url({PHOTO})"><span>Example photo · N. Majola / GroundUp</span></div><time>10:46</time></div>',
"03-done": B("in", "Can a researcher call you on this number to check the details?", "10:46")
  + '<div class="bt"><div>📞 Yes, you can call me</div><div>No, just send it</div></div>'
  + B("out", "📞 Yes, you can call me", "10:47")
  + B("in", "Received ✅\nReference: <b>LMT-0412</b>\n\n1. A researcher reviews it\n2. They may call you\n3. It goes on the map, without your name\n\nThank you. Your report helps us advocate for better housing conditions.", "10:47"),
}
for name, body in S.items():
    src = os.path.join(OUT, name + ".html"); open(src, "w", encoding="utf-8").write(phone(body))
    png = os.path.join(OUT, name + ".png")
    subprocess.run([EDGE, "--headless", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files", "--window-size=520,844", "--force-device-scale-factor=2", "--virtual-time-budget=3000", "--screenshot=" + png, "file:///" + src.replace("\\", "/")], capture_output=True)
    Image.open(png).convert("RGB").crop((0, 0, 780, 1688)).save(os.path.join(OUT, name + ".jpg"), quality=85, optimize=True)
    print(name)
