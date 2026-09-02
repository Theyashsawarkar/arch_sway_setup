// Rotates the hero image "wheel" (assets/style.css's .wheel, 3 screenshots
// at 0/120/240deg around a 3D circle) as the page scrolls -- direct
// request: "on scroll the ss will rollout like rotating the wheel".
//
// Plain scroll-position -> rotation mapping, no scroll-jacking (never
// touches window.scrollTo/preventDefault) -- the page still scrolls
// completely normally, this only ever reads scrollY, never writes it.
(function () {
  const wheel = document.getElementById("wheel");
  if (!wheel) return;

  let ticking = false;

  function render() {
    // One full 360deg turn roughly every 900px scrolled -- slow enough
    // that a normal scroll shows each of the 3 faces clearly rather
    // than spinning past all of them in the first few scroll ticks.
    const angle = (window.scrollY / 900) * 360;
    wheel.style.transform = `rotateY(${angle}deg)`;
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
