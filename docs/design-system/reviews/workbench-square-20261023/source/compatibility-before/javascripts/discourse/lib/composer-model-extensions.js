import Composer from "discourse/models/composer";

export function extendComposerMethod(api, name, extension) {
  // Capture after proto() applies earlier plugin extensions, before replacing it.
  const original = Composer.proto()[name];
  api.addModelMethod("composer", name, function (...args) {
    return extension.call(this, original.bind(this), ...args);
  });
}
