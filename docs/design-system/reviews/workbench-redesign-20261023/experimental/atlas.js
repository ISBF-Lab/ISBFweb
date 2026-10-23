(() => {
  const index = document.querySelector(".wb-atlas");
  const links = index.querySelectorAll(".wb-atlas__launch");

  for (const link of links) {
    for (const event of ["pointerenter", "focus"]) {
      link.addEventListener(event, () => {
        index.dataset.focus = link.dataset.direction;
      });
    }
  }

  index.addEventListener("pointerleave", () => {
    const focused = document.activeElement.closest(".wb-atlas__launch");
    index.dataset.focus = focused?.dataset.direction || "learn";
  });
})();
