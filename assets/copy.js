// Adds a copy-to-clipboard button to every code block on the site
// (index.html's install snippets, and every <pre><code> the doc pages'
// real fenced code blocks render to) -- one script, works on both, no
// per-page duplication.
(function () {
  document.querySelectorAll("pre").forEach((pre) => {
    const code = pre.querySelector("code");
    if (!code) return;

    const btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.type = "button";
    btn.textContent = "Copy";
    btn.setAttribute("aria-label", "Copy to clipboard");

    btn.addEventListener("click", () => {
      navigator.clipboard.writeText(code.textContent).then(
        () => {
          btn.textContent = "Copied";
          btn.classList.add("copied");
          setTimeout(() => {
            btn.textContent = "Copy";
            btn.classList.remove("copied");
          }, 1600);
        },
        () => {
          btn.textContent = "Failed";
          setTimeout(() => (btn.textContent = "Copy"), 1600);
        }
      );
    });

    pre.style.position = "relative";
    pre.appendChild(btn);
  });
})();
