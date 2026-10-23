(() => {
  const media = window.matchMedia("(prefers-reduced-motion: reduce)");
  const baseline = document.body.classList.contains("is-baseline");
  const animations = new Map();
  const profiles = {
    learning_resources: {
      duration: 360,
      keyframes: [
        { transform: "rotate(0deg) scale(1)", offset: 0 },
        { transform: "rotate(-8deg) scale(1.12)", offset: 0.4 },
        { transform: "rotate(0deg) scale(1)", offset: 1 },
      ],
    },
    resume: {
      duration: 320,
      keyframes: [
        { transform: "translateY(0) rotate(0deg)", offset: 0 },
        { transform: "translateY(-4px) rotate(-4deg)", offset: 0.4 },
        { transform: "translateY(0) rotate(0deg)", offset: 1 },
      ],
    },
    alumni: {
      duration: 320,
      keyframes: [
        { transform: "scale(1)", offset: 0 },
        { transform: "scale(1.14)", offset: 0.4 },
        { transform: "scale(1)", offset: 1 },
      ],
    },
    marketplace: {
      duration: 400,
      keyframes: [
        { transform: "rotate(0deg)", offset: 0 },
        { transform: "rotate(-10deg)", offset: 0.25 },
        { transform: "rotate(7deg)", offset: 0.5 },
        { transform: "rotate(-3deg)", offset: 0.75 },
        { transform: "rotate(0deg)", offset: 1 },
      ],
    },
  };

  function animate(icon, keyframes, duration) {
    animations.get(icon)?.cancel();
    const animation = icon.animate(
      keyframes.map((frame) => ({
        ...frame,
        easing: "cubic-bezier(0.2, 0.8, 0.2, 1)",
      })),
      { duration, iterations: 1 }
    );
    animations.set(icon, animation);
    animation.onfinish = () => {
      if (animations.get(icon) === animation) {
        animations.delete(icon);
      }
    };
  }

  function play(card) {
    const profile = profiles[card.dataset.service];
    const icon = card.querySelector(".isbf-v2-workbench__icon .d-icon");
    if (baseline || media.matches || !profile || !icon?.animate) {
      return;
    }
    const keyframes = profile.keyframes.map((frame) => ({ ...frame }));
    keyframes[0].transform = getComputedStyle(icon).transform;
    animate(icon, keyframes, profile.duration);
  }

  function restore(card) {
    const icon = card.querySelector(".isbf-v2-workbench__icon .d-icon");
    if (!animations.has(icon)) {
      return;
    }
    const transform = getComputedStyle(icon).transform;
    animate(icon, [{ transform }, { transform: "none" }], 120);
  }

  document.querySelectorAll("a.isbf-v2-workbench__card").forEach((card) => {
    if (baseline) {
      return;
    }

    let pointerType = "mouse";
    card.addEventListener("pointerenter", (event) => {
      if (event.pointerType === "mouse") {
        play(card);
      }
    });
    card.addEventListener(
      "pointerdown",
      (event) => {
        pointerType = event.pointerType;
      },
      { passive: true }
    );
    card.addEventListener("click", (event) => {
      const type = event.pointerType || pointerType;
      if (event.detail === 0 || type === "touch" || type === "pen") {
        play(card);
      }
    });
    card.addEventListener("pointerleave", (event) => {
      if (event.pointerType === "mouse") {
        restore(card);
      }
    });
    card.addEventListener("pointercancel", () => restore(card));
    card.addEventListener("blur", () => restore(card));
  });

  const stop = () => {
    animations.forEach((animation) => animation.cancel());
    animations.clear();
  };
  media.addEventListener("change", stop);
  window.addEventListener("pagehide", stop);
  window.addEventListener("blur", stop);
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      stop();
    }
  });

  const menus = [...document.querySelectorAll("details")];
  function closeMenus(except) {
    menus.forEach((menu) => {
      if (menu !== except) {
        menu.open = false;
      }
    });
  }
  menus.forEach((menu) =>
    menu.addEventListener("toggle", () => {
      if (menu.open) {
        closeMenus(menu);
      }
    })
  );
  document.addEventListener("click", (event) => {
    if (!event.target.closest("details")) {
      closeMenus();
    }
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      const open = menus.find((menu) => menu.open);
      closeMenus();
      open?.querySelector("summary").focus();
    }
  });

  document.querySelectorAll(".isbf-v2-more__theme").forEach((button) => {
    button.setAttribute(
      "aria-pressed",
      String(document.documentElement.dataset.theme === "dark")
    );
    button.addEventListener("click", () => {
      const dark = document.documentElement.dataset.theme !== "dark";
      document.documentElement.dataset.theme = dark ? "dark" : "light";
      document
        .querySelectorAll(".isbf-v2-more__theme")
        .forEach((toggle) => toggle.setAttribute("aria-pressed", String(dark)));
      closeMenus();
    });
  });

  if (new URLSearchParams(location.search).get("alumni") === "off") {
    document.querySelector('[data-service="alumni"]')?.remove();
  }
})();
