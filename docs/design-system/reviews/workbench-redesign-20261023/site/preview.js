(() => {
  const root = document.documentElement;
  const dark =
    new URLSearchParams(window.location.search).get("theme") === "dark";
  const buttons = document.querySelectorAll(".isbf-v2-more__theme");

  function setTheme(isDark) {
    root.dataset.theme = isDark ? "dark" : "light";
    for (const button of buttons) {
      button.setAttribute("aria-pressed", String(isDark));
      button.querySelector("span").textContent = isDark
        ? "切换浅色外观"
        : "切换深色外观";
      button
        .querySelector("use")
        .setAttribute("href", isDark ? "#icon-sun" : "#icon-moon");
    }
  }

  setTheme(dark);
  for (const button of buttons) {
    button.addEventListener("click", () => {
      setTheme(root.dataset.theme !== "dark");
      button.closest("details").open = false;
    });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") {
      return;
    }
    for (const menu of document.querySelectorAll("details[open]")) {
      menu.open = false;
      menu.querySelector("summary").focus();
    }
  });

  document.addEventListener("click", (event) => {
    for (const menu of document.querySelectorAll("details[open]")) {
      if (!menu.contains(event.target)) {
        menu.open = false;
      }
    }
  });
})();
