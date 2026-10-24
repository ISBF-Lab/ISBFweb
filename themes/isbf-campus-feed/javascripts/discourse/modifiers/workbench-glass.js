import { modifier } from "ember-modifier";
import { settings } from "virtual:theme";
import { mountWorkbenchGlass } from "../lib/workbench-glass";

export default modifier((element) => mountWorkbenchGlass(element, settings));
