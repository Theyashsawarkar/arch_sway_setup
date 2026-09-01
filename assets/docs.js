// Builds the sidebar table-of-contents from the real rendered h2 elements
// in the article -- no hand-maintained list to go stale against the 50+
// sections in docs/ARCHITECTURE.md, no Jekyll plugin needed (GitHub Pages'
// plugin whitelist doesn't include jekyll-toc), just reads what's actually
// on the page.
(function () {
  const article = document.getElementById("docs-article");
  const tocList = document.getElementById("toc-list");
  if (!article || !tocList) return;

  const headings = article.querySelectorAll("h2");
  if (headings.length === 0) {
    document.getElementById("docs-toc").style.display = "none";
    return;
  }

  const ul = document.createElement("ul");
  headings.forEach((h, i) => {
    if (!h.id) {
      h.id = "s" + i + "-" + h.textContent.toLowerCase()
        .replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
    }
    const li = document.createElement("li");
    const a = document.createElement("a");
    a.href = "#" + h.id;
    a.textContent = h.textContent;
    li.appendChild(a);
    ul.appendChild(li);
  });
  tocList.appendChild(ul);

  // Highlight whichever section is currently in view -- plain
  // IntersectionObserver, no framework needed for a page this size.
  const links = tocList.querySelectorAll("a");
  const byId = {};
  links.forEach((a) => (byId[a.getAttribute("href").slice(1)] = a));

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const link = byId[entry.target.id];
        if (!link) return;
        if (entry.isIntersecting) {
          links.forEach((a) => a.classList.remove("active"));
          link.classList.add("active");
        }
      });
    },
    { rootMargin: "0px 0px -80% 0px" }
  );
  headings.forEach((h) => observer.observe(h));
})();
