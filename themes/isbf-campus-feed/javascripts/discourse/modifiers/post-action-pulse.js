import { modifier } from "ember-modifier";

export default modifier((element, [pulse]) => pulse.mount(element));
