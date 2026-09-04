// Hero screenshot carousel -- direct feedback: the previous version read
// raw page scroll and rotated a 3D wheel, which meant the page itself kept
// moving down *while* images changed underneath it ("the page goes down so
// its a bad ux there... the page should stay put"). This version pins the
// hero in place (assets/style.css's `.hero-zone` + `position: sticky`) and
// only slides/fades between screenshots based on scroll progress *within*
// that pinned zone -- it never calls scrollTo/preventDefault, the page
// keeps scrolling completely normally, this only ever reads scrollY and
// writes CSS classes.
(function () {
  const zone = document.getElementById("hero-zone");
  const stack = document.getElementById("slide-stack");
  const dotsWrap = document.getElementById("slide-dots");
  if (!zone || !stack) return;

  const images = Array.from(stack.querySelectorAll(".slide-img"));
  if (images.length === 0) return;

  // Build the dot indicators from however many images actually exist --
  // not hardcoded to a specific count.
  const dots = images.map(() => {
    const d = document.createElement("span");
    d.className = "slide-dot";
    dotsWrap.appendChild(d);
    return d;
  });

  let ticking = false;
  let currentIndex = -1;

  function render() {
    const zoneTop = zone.offsetTop;
    const scrollableRange = zone.offsetHeight - window.innerHeight;
    const progress = scrollableRange > 0
      ? Math.min(1, Math.max(0, (window.scrollY - zoneTop) / scrollableRange))
      : 0;

    let index = Math.floor(progress * images.length);
    if (index >= images.length) index = images.length - 1;
    if (index < 0) index = 0;

    if (index !== currentIndex) {
      images.forEach((img, i) => {
        img.classList.remove("active", "prev");
        if (i < index) img.classList.add("prev");
        else if (i === index) img.classList.add("active");
      });
      dots.forEach((d, i) => d.classList.toggle("active", i === index));
      currentIndex = index;
    }
    ticking = false;
  }

  window.addEventListener(
    "scroll",
    () => {
      if (!ticking) {
        requestAnimationFrame(render);
        ticking = true;
      }
    },
    { passive: true }
  );

  render();
})();
