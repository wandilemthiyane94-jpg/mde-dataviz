/* textfit.js: measurement-based text layout helpers shared by the story pages.
   Every function measures the real rendered text (getComputedTextLength / getBBox /
   getBoundingClientRect). Nothing here guesses widths from character counts. */
(function (g) {
  var NS = "http://www.w3.org/2000/svg";
  function node(x) { return x && x.node ? x.node() : x; }
  function clearT(t) { while (t.firstChild) t.removeChild(t.firstChild); }
  function addTitle(t, full) { var ti = document.createElementNS(NS, "title"); ti.textContent = full; t.appendChild(ti); }
  function tlen(t) { try { return t.getComputedTextLength(); } catch (e) { return 0; } }

  /* Shorten text until it fits maxW (binary search on measured width); adds a <title> with the full text. */
  function truncate(sel, maxW) {
    var t = node(sel), full = t.getAttribute("data-full") || t.textContent; t.setAttribute("data-full", full);
    t.textContent = full; if (tlen(t) <= maxW) return false;
    var lo = 0, hi = full.length;
    while (lo < hi) { var mid = (lo + hi + 1) >> 1; t.textContent = full.slice(0, mid).replace(/\s+$/, "") + "…"; if (tlen(t) <= maxW) lo = mid; else hi = mid - 1; }
    t.textContent = full.slice(0, lo).replace(/\s+$/, "") + "…"; addTitle(t, full); return true;
  }

  /* Wrap into <tspan> lines no wider than maxW (measured). Long single words are broken where they
     exceed the width. If maxLines is set and exceeded, the last line is truncated with a <title>. */
  function wrap(sel, maxW, opt) {
    opt = opt || {}; var t = node(sel), lh = opt.lineHeight || 1.2, full = t.getAttribute("data-full") || t.textContent;
    t.setAttribute("data-full", full); clearT(t);
    var x = t.getAttribute("x") || 0, fs = parseFloat(getComputedStyle(t).fontSize) || 12;
    var words = full.split(/\s+/).filter(Boolean), lines = [], cur = "";
    var probe = document.createElementNS(NS, "tspan"); t.appendChild(probe);
    function fits(s) { probe.textContent = s; return probe.getComputedTextLength() <= maxW; }
    words.forEach(function (w) {
      var tryS = cur ? cur + " " + w : w;
      if (fits(tryS)) { cur = tryS; return; }
      if (cur) lines.push(cur);
      if (fits(w)) { cur = w; return; }
      var piece = "";                                  // break an over-long word by measurement
      for (var i = 0; i < w.length; i++) { if (fits(piece + w[i])) piece += w[i]; else { lines.push(piece); piece = w[i]; } }
      cur = piece;
    });
    if (cur) lines.push(cur);
    t.removeChild(probe);
    var truncated = false;
    if (opt.maxLines && lines.length > opt.maxLines) { var rest = lines.slice(opt.maxLines - 1).join(" "); lines = lines.slice(0, opt.maxLines - 1); lines.push(rest); truncated = true; }
    var y0 = opt.valign === "middle" ? -((lines.length - 1) * lh * fs) / 2 : opt.valign === "bottom" ? -((lines.length - 1) * lh * fs) : 0;
    lines.forEach(function (l, i) { var ts = document.createElementNS(NS, "tspan"); ts.setAttribute("x", x); ts.setAttribute("dy", i === 0 ? y0 : lh * fs); ts.textContent = l; t.appendChild(ts); });
    if (truncated) { var last = t.lastChild, fullLast = last.textContent; last.textContent = fullLast; if (last.getComputedTextLength() > maxW) { var lo = 0, hi = fullLast.length; while (lo < hi) { var m = (lo + hi + 1) >> 1; last.textContent = fullLast.slice(0, m) + "…"; if (last.getComputedTextLength() <= maxW) lo = m; else hi = m - 1; } last.textContent = fullLast.slice(0, lo).replace(/\s+$/, "") + "…"; } addTitle(t, full); }
    return { lines: lines.length, lineHeight: lh * fs, height: lines.length * lh * fs };
  }

  /* Put wrapped text inside a rect; grows the rect to the text if needed. Returns the rect height. */
  function fitBox(rectSel, textSel, opt) {
    opt = opt || {}; var r = node(rectSel), t = node(textSel), px = opt.padX == null ? 10 : opt.padX, py = opt.padY == null ? 7 : opt.padY;
    var w = +r.getAttribute("width"), x = +r.getAttribute("x"), y = +r.getAttribute("y"), h0 = +r.getAttribute("height");
    var anchor = t.getAttribute("text-anchor") || "start";
    t.setAttribute("x", anchor === "middle" ? x + w / 2 : anchor === "end" ? x + w - px : x + px);
    t.setAttribute("y", y);
    wrap(t, w - 2 * px, { lineHeight: opt.lineHeight || 1.2, maxLines: opt.maxLines });
    var bb = t.getBBox(), h = Math.max(h0, bb.height + 2 * py);
    r.setAttribute("height", h);
    t.setAttribute("y", y + (y + (h - bb.height) / 2 - bb.y));   // centre the measured text block
    t.setAttribute("data-box", "1"); r.setAttribute("data-box-rect", "1");
    return h;
  }

  function rectOf(el) { var b = el.getBBox(); return { x: b.x, y: b.y, w: b.width, h: b.height }; }
  function hit(a, b, pad) { pad = pad || 0; return a.x < b.x + b.w + pad && b.x < a.x + a.w + pad && a.y < b.y + b.h + pad && b.y < a.y + a.h + pad; }

  /* Candidate-position labelling for point labels (map pins, city names).
     items: [{text: <text> node, ax, ay, r}] ; obstacles: [{x,y,w,h}] ; bounds {x,y,w,h}.
     Tries positions around the anchor at increasing distances; picks the first that stays inside
     bounds and clears every placed label and obstacle; draws a leader line when the label moved away. */
  function declutter(items, opt) {
    opt = opt || {}; var placed = (opt.obstacles || []).slice(), b = opt.bounds, pad = opt.pad == null ? 3 : opt.pad, leaders = opt.leaderLayer;
    var dists = opt.dists || [0, 14, 28, 44, 62, 84];
    items.forEach(function (it) {
      var t = node(it.text), r = it.r || 8, best = null;
      t.setAttribute("text-anchor", "start"); t.setAttribute("x", 0); t.setAttribute("y", 0);
      var bb0 = t.getBBox(), w = bb0.width, h = bb0.height, asc = -bb0.y;
      outer: for (var di = 0; di < dists.length; di++) {
        var d = dists[di] + r + 4;
        var cands = [[d, -h / 2], [-d - w, -h / 2], [-w / 2, -d - h], [-w / 2, d], [d * .7, -d * .7 - h], [-d * .7 - w, -d * .7 - h], [d * .7, d * .7], [-d * .7 - w, d * .7]];
        if (it.prefer === "left") cands.unshift(cands.splice(1, 1)[0]);
        for (var ci = 0; ci < cands.length; ci++) {
          var bx = it.ax + cands[ci][0], by = it.ay + cands[ci][1], box = { x: bx, y: by, w: w, h: h };
          if (b && (bx < b.x || by < b.y || bx + w > b.x + b.w || by + h > b.y + b.h)) continue;
          var ok = true; for (var k = 0; k < placed.length; k++) if (hit(box, placed[k], pad)) { ok = false; break; }
          if (ok) { best = { box: box, far: di > 0 }; break outer; }
        }
      }
      if (!best) { best = { box: { x: Math.min(Math.max(it.ax + r + 4, b ? b.x : -1e9), b ? b.x + b.w - w : 1e9), y: it.ay - h / 2, w: w, h: h }, far: false }; }
      t.setAttribute("x", best.box.x); t.setAttribute("y", best.box.y + asc);
      placed.push(best.box);
      if (best.far && leaders) {
        var cx = Math.max(best.box.x, Math.min(it.ax, best.box.x + w)), cy = Math.max(best.box.y, Math.min(it.ay, best.box.y + h));
        var ln = document.createElementNS(NS, "line"); ln.setAttribute("x1", it.ax); ln.setAttribute("y1", it.ay); ln.setAttribute("x2", cx); ln.setAttribute("y2", cy);
        ln.setAttribute("stroke", opt.leaderColor || "#888"); ln.setAttribute("stroke-width", 1); ln.setAttribute("stroke-dasharray", "2 2"); node(leaders).appendChild(ln);
      }
    });
    return placed;
  }

  /* Timeline label lanes. labels: [{text: node, x}] already created at y=0 with anchor start.
     Assigns each label to the first row (alternating above / below the axis, then further out)
     where its measured box clears everything already in that row. Returns rows used. */
  function laneTimeline(labels, opt) {
    var rows = {}, gap = opt.gap == null ? 10 : opt.gap, minX = opt.minX, maxX = opt.maxX, maxRows = opt.maxRows || 8;
    labels.forEach(function (L, i) {
      var t = node(L.text); t.setAttribute("text-anchor", "start"); t.setAttribute("x", 0);
      var bb = t.getBBox(), w = bb.width, x = Math.max(minX, Math.min(L.x - w / 2, maxX - w));
      var order = []; for (var k = 0; k < maxRows; k++) { order.push(i % 2 ? -(k + 1) : (k + 1)); order.push(i % 2 ? (k + 1) : -(k + 1)); }
      for (var j = 0; j < order.length; j++) {
        var row = order[j], list = rows[row] || (rows[row] = []), ok = true;
        for (var q = 0; q < list.length; q++) if (x < list[q].x + list[q].w + gap && list[q].x < x + w + gap) { ok = false; break; }
        if (ok) { list.push({ x: x, w: w }); L.row = row; L.lx = x; L.w = w; L.h = bb.height; L.asc = -bb.y; break; }
      }
      t.setAttribute("x", L.lx);
    });
    var up = 0, down = 0; labels.forEach(function (L) { if (L.row < 0) up = Math.max(up, -L.row); else down = Math.max(down, L.row); });
    return { up: up, down: down };
  }

  /* Automated overflow / collision audit (used for testing: ?audit in the URL). */
  function audit() {
    var out = { svgTextOutside: [], svgTextOverlap: [], svgTextOutOfBox: [], htmlOverflow: [] };
    document.querySelectorAll("svg").forEach(function (svg) {
      if (!svg.getBoundingClientRect().width || getComputedStyle(svg).display === "none") return;
      var sb = svg.getBoundingClientRect(), texts = [].slice.call(svg.querySelectorAll("text")).filter(function (t) { var r = t.getBoundingClientRect(); return r.width > 0 && t.textContent.trim() && getComputedStyle(t).opacity !== "0" && !t.closest("[style*='opacity: 0']"); });
      var rs = texts.map(function (t) { return t.getBoundingClientRect(); });
      texts.forEach(function (t, i) { var r = rs[i]; if (r.left < sb.left - 1 || r.right > sb.right + 1 || r.top < sb.top - 1 || r.bottom > sb.bottom + 1) out.svgTextOutside.push((svg.id || "svg") + ": " + t.textContent.slice(0, 50)); });
      for (var i = 0; i < texts.length; i++) for (var j = i + 1; j < texts.length; j++) { var a = rs[i], b = rs[j]; var ix = Math.min(a.right, b.right) - Math.max(a.left, b.left), iy = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top); if (ix > 2 && iy > 2) out.svgTextOverlap.push((svg.id || "svg") + ": \"" + texts[i].textContent.slice(0, 30) + "\" x \"" + texts[j].textContent.slice(0, 30) + "\""); }
    });
    document.querySelectorAll("[data-box]").forEach(function (t) { var r = t.previousElementSibling; while (r && !r.hasAttribute("data-box-rect")) r = r.previousElementSibling; if (!r) return; var a = t.getBBox(), b = r.getBBox(); if (a.x < b.x - 1 || a.y < b.y - 1 || a.x + a.width > b.x + b.width + 1 || a.y + a.height > b.y + b.height + 1) out.svgTextOutOfBox.push(t.textContent.slice(0, 50)); });
    document.querySelectorAll(".sus, .card, .step, .stat, .box, .levels li").forEach(function (c) {
      var cr = c.getBoundingClientRect(); if (!cr.width) return;
      if (c.scrollWidth > c.clientWidth + 1) out.htmlOverflow.push((c.className || c.tagName) + ": " + c.textContent.trim().slice(0, 40));
      c.querySelectorAll("*").forEach(function (k) { var r = k.getBoundingClientRect(); if (r.width && r.right > cr.right + 1) out.htmlOverflow.push("child of " + (c.className || c.tagName) + ": " + k.textContent.trim().slice(0, 40)); });
    });
    return out;
  }

  g.TF = { truncate: truncate, wrap: wrap, fitBox: fitBox, declutter: declutter, laneTimeline: laneTimeline, audit: audit, rectOf: rectOf, hit: hit };
})(window);
