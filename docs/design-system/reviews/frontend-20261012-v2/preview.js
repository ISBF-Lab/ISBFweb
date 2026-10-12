function updateViewport() {
  const mobile = window.innerWidth <= 600;
  document.documentElement.classList.toggle("mobile-view", mobile);
  document.documentElement.classList.toggle("desktop-view", !mobile);
}

window.addEventListener("resize", updateViewport);
updateViewport();
document.addEventListener("click", (event) => {
  if (event.target.closest('a[href="#"]')) {
    event.preventDefault();
  }
});
