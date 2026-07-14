/* Animated sparkle field — a web port of the app's SparkleField (MeowUI):
   4-point concave-diamond sparkles that twinkle, tumble, and drift, white on
   the gradient. A glowing sprite is pre-rendered once, then transformed per
   frame (cheap). Honors prefers-reduced-motion. Needs a <canvas id="sparkles">. */
(function () {
  var c = document.getElementById('sparkles');
  if (!c || !c.getContext) return;
  var ctx = c.getContext('2d');
  var dpr = Math.min(window.devicePixelRatio || 1, 2);
  var BASE = 48, sprite = null, sparks = [], raf = 0;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function makeSprite() {
    var off = document.createElement('canvas');
    off.width = off.height = BASE;
    var o = off.getContext('2d');
    var r = BASE * 0.30, cx = BASE / 2, cy = BASE / 2, inner = r * 0.34;
    o.shadowColor = 'rgba(255,255,255,0.95)';
    o.shadowBlur = BASE * 0.17;
    o.fillStyle = '#fff';
    o.beginPath();
    o.moveTo(cx, cy - r);
    o.lineTo(cx + inner, cy - inner);
    o.lineTo(cx + r, cy);
    o.lineTo(cx + inner, cy + inner);
    o.lineTo(cx, cy + r);
    o.lineTo(cx - inner, cy + inner);
    o.lineTo(cx - r, cy);
    o.lineTo(cx - inner, cy - inner);
    o.closePath();
    o.fill();
    return off;
  }

  function rand(a, b) { return a + Math.random() * (b - a); }

  function build() {
    var w = window.innerWidth, h = window.innerHeight;
    c.width = Math.floor(w * dpr); c.height = Math.floor(h * dpr);
    c.style.width = w + 'px'; c.style.height = h + 'px';
    var n = Math.round(Math.min(90, Math.max(34, (w * h) / 15000)));
    sparks = [];
    for (var i = 0; i < n; i++) {
      sparks.push({
        x: Math.random() * w, y: Math.random() * h,
        size: rand(10, 24),
        twP: rand(0.7, 2.0), twPh: Math.random() * 6.283,   // twinkle
        spP: rand(2.5, 6.0), spPh: Math.random() * 6.283,   // tumble
        drA: rand(4, 14), drP: rand(2.5, 5.0), drPh: Math.random() * 6.283 // drift
      });
    }
  }

  function frame(ms) {
    var t = ms / 1000, w = window.innerWidth, h = window.innerHeight;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);
    for (var i = 0; i < sparks.length; i++) {
      var s = sparks[i];
      var tw = 0.1 + 0.9 * (0.5 + 0.5 * Math.sin(t * (6.283 / s.twP) + s.twPh)); // 0.1..1
      var yo = Math.sin(t * (6.283 / s.drP) + s.drPh) * s.drA;
      var spin = t * (6.283 / s.spP) + s.spPh;
      var sx = 0.25 + 0.75 * Math.abs(Math.cos(spin)); // fake 3D foreshorten
      var k = s.size / BASE;
      ctx.save();
      ctx.globalAlpha = tw;
      ctx.translate(s.x, s.y + yo);
      ctx.rotate(spin * 0.5);
      ctx.scale(k * sx, k);
      ctx.drawImage(sprite, -BASE / 2, -BASE / 2);
      ctx.restore();
    }
    if (!reduce) raf = window.requestAnimationFrame(frame);
  }

  function start() {
    sprite = makeSprite();
    build();
    window.cancelAnimationFrame(raf);
    if (reduce) frame(0); else raf = window.requestAnimationFrame(frame);
  }
  var rt;
  window.addEventListener('resize', function () {
    window.clearTimeout(rt);
    rt = window.setTimeout(function () { build(); if (reduce) frame(0); }, 150);
  });
  start();
})();
