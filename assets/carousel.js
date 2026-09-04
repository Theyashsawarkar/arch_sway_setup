// Hero screenshot carousel -- fully self-contained, no page-scroll
// involvement at all. Direct feedback on the previous (scroll-pinned)
// version: it felt sluggish, and tying page scroll to the gallery was the
// wrong idea in the first place -- "let the scroll behave normally...
// if a user want to see the screenshots then he can just do something
// there." This version autoplays on its own timer, pauses while the
// pointer is over it (so it doesn't yank a screenshot away mid-look), and
// the dots are real click targets to jump straight to one -- that's the
// "do something there" the feedback asked for.
(function () {
  const stack = document.getElementById("slide-stack");
  const dotsWrap = document.getElementById("slide-dots");
  if (!stack || !dotsWrap) return;

  const images = Array.from(stack.querySelectorAll(".slide-img"));
  if (images.length === 0) return;

  const INTERVAL_MS = 3200;
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
    images.forEach((img, i) => {
      img.classList.remove("active", "prev");
      if (i < index) img.classList.add("prev");
      else if (i === index) img.classList.add("active");
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
  start();

  stack.addEventListener("mouseenter", stop);
  stack.addEventListener("mouseleave", start);
  dotsWrap.addEventListener("mouseenter", stop);
  dotsWrap.addEventListener("mouseleave", start);
})();
