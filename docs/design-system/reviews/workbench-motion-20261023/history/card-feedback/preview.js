(() => {
  const media = window.matchMedia("(prefers-reduced-motion: reduce)");
  const baseline = document.body.classList.contains("is-baseline");
  const animations = new Map();
  let pressedCard;
  let pointerId;

  document.documentElement.classList.toggle(
    "discourse-no-touch",
    window.matchMedia("(hover: hover)").matches ||
      navigator.maxTouchPoints === 0
  );
  document.addEventListener(
    "pointerover",
    (event) => {
      document.documentElement.classList.toggle(
        "discourse-no-touch",
        event.pointerType === "mouse"
      );
    },
    { passive: true }
  );

  function cancelRipple(card) {
    animations.get(card)?.cancel();
    animations.delete(card);
  }

  function ripple(card, clientX, clientY) {
    if (media.matches || baseline) {
      return;
    }

    cancelRipple(card);
    const bounds = card.getBoundingClientRect();
    const x = clientX ?? bounds.left + bounds.width / 2;
    const y = clientY ?? bounds.top + bounds.height / 2;
    const localX = Math.max(0, Math.min(bounds.width, x - bounds.left));
    const localY = Math.max(0, Math.min(bounds.height, y - bounds.top));
    const diameter =
      2 *
      Math.hypot(
        Math.max(localX, bounds.width - localX),
        Math.max(localY, bounds.height - localY)
      );
    const dot = card.querySelector(".isbf-v2-workbench__ripple");
    if (!dot?.animate) {
      return;
    }

    dot.style.width = `${diameter}px`;
    dot.style.height = `${diameter}px`;
    dot.style.left = `${localX - diameter / 2}px`;
    dot.style.top = `${localY - diameter / 2}px`;
    const animation = dot.animate(
      [
        { transform: "scale(0)", opacity: 0.12 },
        { transform: "scale(1)", opacity: 0 },
      ],
      { duration: 420, easing: "cubic-bezier(0.2, 0.7, 0.2, 1)" }
    );
    animations.set(card, animation);
    animation.onfinish = () => {
      if (animations.get(card) === animation) {
        animations.delete(card);
      }
    };
  }

  function release(cancel = false) {
    if (pressedCard) {
      pressedCard.classList.remove("is-pressed");
      if (cancel) {
        cancelRipple(pressedCard);
      }
    }
    pressedCard = undefined;
    pointerId = undefined;
  }

  document.querySelectorAll("a.isbf-v2-workbench__card").forEach((card) => {
    if (baseline) {
      return;
    }

    card.addEventListener(
      "pointerdown",
      (event) => {
        if (!event.isPrimary || event.button !== 0) {
          return;
        }
        release(true);
        pressedCard = card;
        pointerId = event.pointerId;
        card.classList.add("is-pressed");
        ripple(card, event.clientX, event.clientY);
      },
      { passive: true }
    );

    card.addEventListener("pointerleave", () => {
      if (pressedCard === card) {
        release(true);
      }
    });

    card.addEventListener("keydown", (event) => {
      if (event.key === "Enter" && !event.repeat) {
        release(true);
        pressedCard = card;
        card.classList.add("is-pressed");
        ripple(card);
      }
    });

    card.addEventListener("keyup", (event) => {
      if (event.key === "Enter") {
        release();
      }
    });

    card.addEventListener("blur", () => {
      if (pressedCard === card) {
        release(true);
      }
    });
  });

  document.addEventListener(
    "pointerup",
    (event) => {
      if (event.pointerId === pointerId) {
        release();
      }
    },
    { passive: true }
  );
  document.addEventListener(
    "pointercancel",
    (event) => {
      if (event.pointerId === pointerId) {
        release(true);
      }
    },
    { passive: true }
  );
  window.addEventListener("blur", () => release(true));

  const stop = () => {
    release(true);
    animations.forEach((animation) => animation.cancel());
    animations.clear();
  };
  media.addEventListener("change", stop);
  window.addEventListener("pagehide", stop);

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
