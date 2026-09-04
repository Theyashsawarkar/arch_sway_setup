// Hero screenshot carousel -- a real layered card-deck (assets/style.css's
// .slide-img[data-offset] rules), self-contained, no page-scroll
// involvement at all. Autoplays on its own timer, pauses while the
// pointer is over it, and the dots are real click targets to jump
// straight to a screenshot.
(function () {
  const stack = document.getElementById("slide-stack");
  const dotsWrap = document.getElementById("slide-dots");
  if (!stack || !dotsWrap) return;

  const images = Array.from(stack.querySelectorAll(".slide-img"));
  if (images.length === 0) return;

  // Direct feedback: the previous 3.2s dwell + 0.5s transition felt
  // rushed. Slower dwell, and the transition itself (assets/style.css's
  // .slide-img rule) got a longer duration + gentler easing curve to
  // match -- feels like a deliberate, polished move now, not a snap.
  const INTERVAL_MS = 5000;
  let currentIndex = 0;
  let timer = null;

  const dots = images.map((_, i) => {
    const d = document.createElement("button");
    d.type = "button";
    d.className = "slide-dot";
    d.setAttribute("aria-label", "Show screenshot " + (i + 1));
    d.addEventListener("click", () => goTo(i));
    dotsWrap.appendChild(d);
    return d;
  });

  function show(index) {
    // Each image's "offset" is its distance from the active one, going
    // forward through the deck (wrapping around) -- 0 is the front/active
    // card, 1 and 2 are the next ones peeking out behind it (styled in
    // CSS), anything further back is hidden until its turn comes up.
    images.forEach((img, i) => {
      const delta = (i - index + images.length) % images.length;
      img.setAttribute("data-offset", String(delta));
    });
    dots.forEach((d, i) => d.classList.toggle("active", i === index));
    currentIndex = index;
  }

  function goTo(index) {
    show(index);
    restart();
  }

  function advance() {
    show((currentIndex + 1) % images.length);
  }

  function start() {
    stop();
    timer = window.setInterval(advance, INTERVAL_MS);
  }
  function stop() {
    if (timer) window.clearInterval(timer);
    timer = null;
  }
  function restart() {
    start();
  }

  show(0);

  // Direct feedback: a visible flash on the image changes. One real
  // cause -- img.decode() actually finishes decoding a downloaded
  // image (not just "the bytes arrived", which is all `.complete`
  // guarantees) before it's ever asked to animate in at full opacity,
  // instead of decoding-and-painting on the same frame the transition
  // starts, which is what shows up as a flash/pop. Per-image .catch so
  // one slow/failed decode can't block the others; a 2s cap either way
  // so a genuinely stuck decode doesn't delay autoplay starting
  // forever.
  const ready = Promise.race([
    Promise.all(images.map((img) => (img.decode ? img.decode().catch(() => {}) : Promise.resolve()))),
    new Promise((resolve) => window.setTimeout(resolve, 2000)),
  ]);
  ready.then(start);

  stack.addEventListener("mouseenter", stop);
  stack.addEventListener("mouseleave", start);
  dotsWrap.addEventListener("mouseenter", stop);
  dotsWrap.addEventListener("mouseleave", start);
})();
