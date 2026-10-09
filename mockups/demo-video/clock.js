/* Frame-exact clock for recording. Injected before any page script (and into same-origin iframes).
   The page's time only moves when the recorder calls __adv(ms): timers, requestAnimationFrame and
   CSS/Web animations all advance by exactly that much, so every recorded frame is evenly spaced. */
(() => {
  if (window.__adv) return;
  let T = 0, id = 1; const base = Date.now(), q = [], raf = new Map(), RD = Date;
  performance.now = () => T;
  window.Date = class extends RD { constructor(...a) { if (a.length) super(...a); else super(base + T); } static now() { return base + T; } };
  window.setTimeout = (fn, ms, ...a) => { const i = id++; q.push({ i, t: T + Math.max(0, +ms || 0), fn, a }); return i; };
  window.setInterval = (fn, ms, ...a) => { const e = Math.max(1, +ms || 0), i = id++; q.push({ i, t: T + e, fn, a, every: e }); return i; };
  window.clearTimeout = window.clearInterval = i => { const k = q.findIndex(x => x.i === i); if (k >= 0) q.splice(k, 1); };
  window.requestAnimationFrame = fn => { const i = id++; raf.set(i, fn); return i; };
  window.cancelAnimationFrame = i => raf.delete(i);
  const run = (f, a) => { try { typeof f === 'function' ? f(...a) : (0, eval)(f); } catch (e) { console.error(e); } };
  window.__adv = dt => {
    const end = T + dt;
    for (let g = 0; g < 5000; g++) {
      let n = null; for (const x of q) if (!n || x.t < n.t) n = x;
      if (!n || n.t > end) break;
      T = n.t; if (n.every) n.t += n.every; else q.splice(q.indexOf(n), 1);
      run(n.fn, n.a);
    }
    T = end;
    const cbs = [...raf]; raf.clear(); for (const [, f] of cbs) run(f, [T]);
    try { document.getAnimations().forEach(a => { a.pause(); a.currentTime = (a.currentTime || 0) + dt; }); } catch (e) {}
    for (let k = 0; k < window.frames.length; k++) { try { window.frames[k].__adv && window.frames[k].__adv(dt); } catch (e) {} }
    return T;
  };
})();
