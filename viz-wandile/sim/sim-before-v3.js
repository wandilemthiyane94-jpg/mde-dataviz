/* Simulation page. Inputs (total rain, duration, scenario) are turned into an hourly rain series and sent to the
   Gwala Street flood model (stories/gwala-orbit.html in embed mode), which re-runs and reports the camp depth and
   flooded area. Panel 1 shows the ArcGIS Pro run of the real 2022 storm at the same moment. */
(function(){
const REAL=[6.1,5.8,4.9,4.5,4.9,3.8,4.0,4.8,7.3,11.6,15.9,18.4,6.5,7.4,7.9,9.4,10.9];   // ERA5 hourly, 11 Apr 2022 09:00–
const REAL_TOTAL=Math.round(REAL.reduce((a,b)=>a+b,0)), KMAX=33;                          // model runs 09:00 to 01:30 in half-hours
const SC=[['2022 storm',REAL_TOTAL,17],['Heavier storm',200,17],['Lighter storm',50,6]];
let total=REAL_TOTAL, dur=17, k=0, playing=false, rain=REAL.slice(), last=0, frameReady=false;
const root=document.createElement('section'); root.id='sim'; root.hidden=true; root.setAttribute('aria-label','Flood simulation'); document.body.appendChild(root);
const hh=k=>{ const m=9*60+k*30, h=Math.floor(m/60)%24; return String(h).padStart(2,'0')+':'+(m%60?'30':'00'); };
const day=k=>9*60+k*30>=24*60?'12 Apr 2022':'11 Apr 2022';
/* total + duration → 17 hourly values: the real 2022 profile, squeezed into the duration and scaled to the total */
function series(){ if(total===REAL_TOTAL&&dur===17) return REAL.slice(); const out=[];
  for(let i=0;i<17;i++){ if(i>=dur){ out.push(0); continue; } const a=i/dur*17, b=(i+1)/dur*17; let s=0;
    for(let j=Math.floor(a);j<Math.ceil(b);j++){ const lo=Math.max(a,j), hi=Math.min(b,j+1); if(hi>lo) s+=REAL[j]*(hi-lo); } out.push(s); }
  const sum=out.reduce((x,y)=>x+y,0)||1; return out.map(v=>+(v*total/sum).toFixed(2)); }
function render(){
  root.innerHTML=
  '<div class="sm-head"><div class="bg"></div><div><div class="sm-k">Flood simulation</div><h1>What if it rained differently?</h1>'+
  '<p>Set how much rain falls and for how long, and see how the water moves across the land and how deep it gets at the camp.</p>'+
  '<label class="sm-site">Site <select id="smsite"><option>Gwala Street, Lamontville</option><option disabled>Other sites: coming soon</option></select></label></div>'+
  '<button class="sm-card" id="smreal" type="button"><svg width="44" height="40" viewBox="0 0 44 40" aria-hidden="true"><path d="M12 22a8 8 0 010-16 11 11 0 0121 3 7 7 0 011 13z" fill="#cbd5e1"/><path d="M14 27l-2 6M22 27l-2 6M30 27l-2 6" stroke="#60a5fa" stroke-width="2.5" stroke-linecap="round"/></svg><span><b>2022 Durban flood</b><span>'+REAL_TOTAL+' mm over 17 hours</span><small>Use this as a starting point.</small></span><span aria-hidden="true">›</span></button></div>'+
  '<div class="sm-body">'+
   '<div class="sm-ctl"><h4>1. Rainfall amount</h4><div class="sm-num"><input id="smtot" type="number" min="0" max="300" value="'+total+'" aria-label="Rainfall amount in millimetres"><span>mm</span></div>'+
    '<div class="sm-range"><input id="smtotr" type="range" min="0" max="300" value="'+total+'" aria-label="Rainfall amount"><div><span>0</span><span>300</span></div></div>'+
    '<h4>2. Duration</h4><div class="sm-num"><input id="smdur" type="number" min="1" max="17" value="'+dur+'" aria-label="Duration in hours"><span>hours</span></div>'+
    '<div class="sm-range"><input id="smdurr" type="range" min="1" max="17" value="'+dur+'" aria-label="Duration"><div><span>1</span><span>17</span></div></div>'+
    '<button class="sm-play" id="smgo" type="button">▶ Play simulation</button>'+
    '<h4 style="margin-top:4px">Or try a scenario</h4><div class="sm-sc" id="smsc">'+SC.map((s,i)=>'<button type="button" data-i="'+i+'" aria-pressed="'+(s[1]===total&&s[2]===dur)+'"><i></i><b>'+s[0]+'</b><small>'+s[1]+' mm · '+s[2]+' hours</small></button>').join('')+'</div>'+
    '<p class="sm-note">A simplified model on the LiDAR terrain (30 m grid), starting 09:00 on 11 April. The rain follows the shape of the real 2022 storm, scaled to your amount and length. Results are indicative.</p></div>'+
   '<div class="sm-stage"><div class="sm-cap"><span class="sm-k">What the water reaches</span><h2>Homes and streets around Gwala Street</h2></div>'+
    '<div class="sm-view"><img id="smarc" src="stories/gwala-arcfull/a00.jpg" alt="ArcGIS Pro flood simulation of Gwala Street in the 2022 storm">'+
    '<div class="sm-time"><b id="smt1">09:00</b><span id="smd1">11 Apr 2022</span></div>'+
    '<div class="sm-read"><div><small>Water at the camp</small><b id="smdep">0.00 m</b></div><i></i><div><small>Area under water</small><b id="smarea">0.00<em>km²</em></b></div></div>'+
    '<span class="sm-src">Imagery: ArcGIS Pro run of the 2022 storm · numbers: model with your rain</span></div>'+
    '<iframe id="smframe" class="sm-model" title="Flood model (runs in the background)" aria-hidden="true" tabindex="-1" src="stories/gwala-orbit.html#embed"></iframe></div>'+
  '</div>'+
  '<div class="sm-foot"><button class="sm-pbtn" id="smpb" type="button" aria-label="Play">▶</button>'+
   '<div class="sm-clock"><b id="smt2">09:00</b><small id="smd2">11 Apr 2022</small></div>'+
   '<div class="sm-tl"><div class="sm-bars" id="smbars"></div><input id="smk" type="range" min="0" max="'+KMAX+'" step="0.1" value="0" aria-label="Time in the storm"><div class="sm-ticks" id="smticks"></div></div>'+
   '<div style="display:flex;gap:18px"><div class="sm-stat"><small>Total rainfall so far</small><b id="smsofar">0 mm</b></div><div class="sm-stat"><small>Current time</small><b id="smt3">09:00</b></div></div></div>';
  wire(); bars(); ticks(); show(k); send();
}
function bars(){ const mx=Math.max(...rain,1); document.getElementById('smbars').innerHTML=rain.map((v,i)=>'<i style="height:'+Math.max(2,v/mx*34)+'px" class="'+(i*2<k?'past':'')+'" title="'+hh(i*2)+' · '+v+' mm"></i>').join(''); }
function ticks(){ document.getElementById('smticks').innerHTML=[0,6,12,18,24,30].map(t=>'<span style="left:'+(t/KMAX*100)+'%">'+hh(t)+'</span>').join(''); }
function show(kk){ k=Math.max(0,Math.min(KMAX,kk)); const t=hh(Math.round(k)), d=day(Math.round(k));
  ['smt1','smt2','smt3'].forEach(id=>document.getElementById(id).textContent=t); ['smd1','smd2'].forEach(id=>document.getElementById(id).textContent=d);
  document.getElementById('smk').value=k; document.getElementById('smarc').src='stories/gwala-arcfull/a'+String(Math.round(k*60/KMAX)).padStart(2,'0')+'.jpg';
  let so=0; for(let i=0;i<17;i++){ const f=Math.max(0,Math.min(1,(k/2)-i)); so+=rain[i]*f; } document.getElementById('smsofar').textContent=Math.round(so)+' mm';
  document.querySelectorAll('#smbars i').forEach((b,i)=>b.classList.toggle('past',i*2<k));
  const fr=document.getElementById('smframe'); if(fr&&fr.contentWindow&&frameReady) fr.contentWindow.postMessage({type:'gwala-time',k:k},'*'); }
function send(){ rain=series(); bars(); const fr=document.getElementById('smframe'); if(fr&&fr.contentWindow) fr.contentWindow.postMessage({type:'gwala-rain',rain:rain},'*'); }
function setInputs(t,d){ total=Math.max(0,Math.min(300,Math.round(t))); dur=Math.max(1,Math.min(17,Math.round(d)));
  ['smtot','smtotr'].forEach(id=>document.getElementById(id).value=total); ['smdur','smdurr'].forEach(id=>document.getElementById(id).value=dur);
  document.querySelectorAll('#smsc button').forEach((b,i)=>b.setAttribute('aria-pressed',SC[i][1]===total&&SC[i][2]===dur)); clearTimeout(window._smt); window._smt=setTimeout(send,120); }
function wire(){ const $=id=>document.getElementById(id);
  $('smtot').oninput=e=>setInputs(+e.target.value,dur); $('smtotr').oninput=e=>setInputs(+e.target.value,dur);
  $('smdur').oninput=e=>setInputs(total,+e.target.value); $('smdurr').oninput=e=>setInputs(total,+e.target.value);
  $('smsc').onclick=e=>{ const b=e.target.closest('button'); if(b){ const s=SC[+b.dataset.i]; setInputs(s[1],s[2]); } };
  $('smreal').onclick=()=>setInputs(REAL_TOTAL,17);
  $('smk').oninput=e=>{ playing=false; $('smpb').textContent='▶'; show(+e.target.value); };
  const toggle=()=>{ playing=!playing; $('smpb').textContent=playing?'❚❚':'▶'; if(playing&&k>=KMAX) show(0); last=performance.now(); if(playing) requestAnimationFrame(tick); };
  $('smpb').onclick=toggle; $('smgo').onclick=()=>{ send(); show(0); if(!playing) toggle(); };
  $('smframe').addEventListener('load',()=>{ frameReady=true; setTimeout(send,600); setTimeout(()=>show(k),900); }); }
function tick(now){ if(!playing||root.hidden) return; const dt=Math.min(.1,(now-last)/1000); last=now; show(k+dt*1.6); if(k>=KMAX){ playing=false; const b=document.getElementById('smpb'); if(b) b.textContent='▶'; return; } requestAnimationFrame(tick); }
addEventListener('message',e=>{ const m=e.data||{}; if(m.type!=='gwala-state'||root.hidden) return; frameReady=true;
  const dp=document.getElementById('smdep'), ar=document.getElementById('smarea'); if(dp) dp.textContent=m.camp.toFixed(2)+' m'; if(ar) ar.innerHTML=m.area.toFixed(2)+'<em>km²</em>'; });
let built=false;
function open(){ if(!built){ render(); built=true; } root.hidden=false; document.querySelectorAll('nav button').forEach(b=>b.setAttribute('aria-current',b.dataset.v==='sim'?'page':'false')); }
function close(){ root.hidden=true; playing=false; }
const nav=document.querySelector('nav'); if(nav&&!nav.querySelector('[data-v="sim"]')){ const b=document.createElement('button'); b.type='button'; b.dataset.v='sim'; b.textContent='Simulation';
  const rep=nav.querySelector('[data-v="report"]'); nav.insertBefore(b,rep);
  b.addEventListener('click',()=>{ ['news','rp'].forEach(id=>{ const el=document.getElementById(id); if(el) el.hidden=true; }); open(); }); }
document.querySelectorAll('nav button').forEach(b=>{ if(b.dataset.v!=='sim') b.addEventListener('click',close); });
if(location.hash==='#simulation') setTimeout(open,0);
})();
