/* Report page. The WhatsApp line is shown as a preview until the project has a WhatsApp Business number;
   the web form below it is live (reportHTML / sendReport in index.html). */
(function(){
if (typeof reportHTML !== 'function') return;
const root=document.createElement('section'); root.id='rp'; root.hidden=true; root.setAttribute('aria-label','Report'); document.body.appendChild(root);
const qr=()=>{ let r=7,c='',n=25; const R=()=>(r=(r*16807)%2147483647)/2147483647; for(let i=0;i<n;i++)for(let j=0;j<n;j++){ if((i<7&&j<7)||(i<7&&j>n-8)||(i>n-8&&j<7)) continue; if(R()<.48) c+='<rect x="'+j*4+'" y="'+i*4+'" width="4.2" height="4.2"/>'; }
  const f=(x,y)=>'<rect x="'+x+'" y="'+y+'" width="28" height="28"/><rect x="'+(x+4)+'" y="'+(y+4)+'" width="20" height="20" fill="#fff"/><rect x="'+(x+8)+'" y="'+(y+8)+'" width="12" height="12"/>';
  return '<svg viewBox="0 0 100 100" fill="#0B0F19" aria-hidden="true">'+c+f(0,0)+f(72,0)+f(0,72)+'</svg>'; };
function render(){
  root.innerHTML=
  '<div class="rp-top"><div class="bg"></div><div class="rp-l"><div class="rp-k">Report</div><h1>Report what’s happening at your site</h1>'+
  '<p class="lede">Live in or near a temporary relocation site? Tell us about the conditions. <b style="color:#fff">Your report helps us advocate for better housing conditions.</b></p>'+
  '<div class="rp-wa"><div><h2>Report via WhatsApp</h2><p>Scan the code with your phone camera to start a conversation.</p><div class="rp-qr">'+qr()+'<span>WhatsApp line<br>coming soon</span></div><div class="rp-soon">Preview · number not live yet</div></div>'+
  '<div class="rp-feats"><div><i>💬</i><span><b>No app to download</b><small>Just WhatsApp</small></span></div><div><i>🔒</i><span><b>Your name stays private</b><small>Reports are reviewed before anything appears on the map</small></span></div><div><i>📞</i><span><b>A researcher may call</b><small>To check the details. Your number is never shown</small></span></div></div></div></div>'+
  '<div class="rp-steps">'+[['1','Start the conversation','Scan the code and say hello. You agree to how your report is used.','02-chat-start'],['2','Choose a topic and share','Pick your site and what it’s about, then type, send a voice note or a photo.','03-chat-report'],['3','Get a reference','A researcher reviews it and may call. Then it shows on the map, without your name.','04-chat-done']]
    .map(s=>'<div class="rp-step"><h3><b>'+s[0]+'</b>'+s[1]+'</h3><p>'+s[2]+'</p><div class="rp-phone"><img src="report/'+s[3]+'.jpg" alt="Example WhatsApp chat: '+s[1]+'" loading="lazy"></div></div>').join('')+'</div></div>'+
  '<div class="rp-help"><h2>Your report helps us advocate for better housing conditions<span>Every checked report becomes evidence.</span></h2>'+
    [['👁','Show real conditions'],['⚠','Highlight urgent needs'],['🏛','Inform government and partners'],['⚖','Hold decision-makers accountable'],['🏠','Push for safer housing']].map(h=>'<div><i aria-hidden="true">'+h[0]+'</i>'+h[1]+'</div>').join('')+'</div>'+
  '<div class="rp-form"><div class="side"><div class="rp-k">Or report here</div><h2>Use the web form</h2><p>Works now, on any phone or computer. Do not write your name or anyone else’s.</p><p style="font-size:12px;color:#64748B">Chat screens above are examples for illustration. The WhatsApp line needs a WhatsApp Business number and research-ethics approval before it goes live.</p></div><div class="box" id="rpbox"></div></div>';
  document.getElementById('rpbox').innerHTML=reportHTML();
  const f=document.getElementById('rep'); if(f && typeof sendReport==='function') f.onsubmit=sendReport;
}
function open(){ render(); root.hidden=false; root.scrollTop=0; document.querySelectorAll('nav button').forEach(b=>b.setAttribute('aria-current',b.dataset.v==='report'?'page':'false')); }
function close(){ root.hidden=true; }
document.querySelectorAll('nav button').forEach(b=>b.addEventListener('click',()=>{ if(b.dataset.v==='report') setTimeout(open,0); else close(); }));
window.openReport=open;
if(location.hash==='#report') setTimeout(open,0);
})();
