# Exports the example chats as live HTML + scoped CSS for the Report page (viz-wandile/report/chats.js).
import re, json, os
HERE=os.path.dirname(os.path.abspath(__file__))
src=open(os.path.join(HERE,"build_light.py"),encoding="utf-8").read()
code=src.split("for name, body in S.items():")[0]
code=re.sub(r'PHOTO = .*', 'PHOTO = "assets/photos/gu_lamontville_camp_2022.jpg"', code)
ns={"__file__":os.path.join(HERE,"build_light.py")}; exec(code,ns)
out=[]
for m in re.finditer(r"([^{}]+)\{([^{}]*)\}",ns["CSS"]):
    ps=[]
    for x in [s.strip() for s in m.group(1).split(",")]:
        ps.append(".rpc *" if x=="*" else ".rpc" if x in ("html","body") else ".rpc "+x)
    out.append(",".join(ps)+"{"+m.group(2)+"}")
def inner(body):
    h=ns["phone"](body); return h[h.index('<div class="ph">'):h.rindex("</body>")]
chats=[inner(ns["S"][k]) for k in ["01-start","02-report","03-done"]]
js="/* Example chats for the Report page, drawn as live text so they stay sharp. Built by mockups/whatsapp-report/export_chats.py. */\nwindow.RP_CSS="+json.dumps("\n".join(out))+";\nwindow.RP_CHATS="+json.dumps(chats,ensure_ascii=False)+";\n"
open(os.path.join(HERE,"..","..","viz-wandile","report","chats.js"),"w",encoding="utf-8").write(js); print("ok",len(js))
