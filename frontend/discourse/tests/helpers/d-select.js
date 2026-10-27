import { find, select as selectValue } from "@ember/test-helpers";

/** Finds the submitted value carrier for a shared or native select. */
export function findSelect(selectorOrElement) {
  const element =
    typeof selectorOrElement === "string"
      ? find(selectorOrElement)
      : selectorOrElement;
  return element?.matches(".d-select__trigger")
    ? element.nextElementSibling
    : element;
}

/** Changes a field value through the existing native input/change event contract. */
export default function select(selectorOrElement, value, options = undefined) {
  return selectValue(findSelect(selectorOrElement), value, options);
}
