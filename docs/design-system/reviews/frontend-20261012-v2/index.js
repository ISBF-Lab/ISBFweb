const page = document.querySelector("#page");
const mode = document.querySelector("#mode");
const viewport = document.querySelector("#viewport");
const frame = document.querySelector("#preview");

function update() {
  const filename = `${page.value}-${mode.value}.html`;
  frame.src = filename;
  frame.width = viewport.value;
  frame.height = Number(viewport.value) <= 600 ? "844" : "1100";
  const link = document.createElement("a");
  link.href = filename;
  link.textContent = "单独打开当前提案";
  document.querySelector("#direct").replaceChildren(link);
}

for (const control of [page, mode, viewport]) {
  control.addEventListener("change", update);
}
update();
