import { apiInitializer } from "discourse/lib/api";

const nativePlacement = new WeakMap();

export default apiInitializer((api) => {
  api.modifyClass("component:category-chooser", {
    pluginId: "isbf-ui-composer-category-menu",

    updateFloatingUiPosition() {
      const header = this.getHeader();
      const menu = this.selectKit
        .mainElement()
        ?.querySelector(".select-kit-body");
      const composer = header?.closest("#reply-control.open");
      const scoped =
        window.matchMedia("(max-width: 600px)").matches &&
        composer?.querySelector(".isbf-v2-composer");

      if (scoped && menu) {
        const options = this.selectKit.options;
        if (!nativePlacement.has(this)) {
          nativePlacement.set(this, {
            placement: options.placement,
            mobilePlacement: options.mobilePlacement,
            placementStrategy: options.placementStrategy,
          });
        }
        options.setProperties({
          placement: "top-start",
          mobilePlacement: "top-start",
          placementStrategy: "fixed",
        });
        const viewportTop = window.visualViewport?.offsetTop || 0;
        const availableHeight = Math.max(
          0,
          header.getBoundingClientRect().top - viewportTop - 8
        );
        menu.classList.add("isbf-v2-composer-category-menu");
        menu.style.setProperty(
          "--isbf-v2-category-menu-max-height",
          `${availableHeight}px`
        );
      } else {
        const original = nativePlacement.get(this);
        if (original) {
          this.selectKit.options.setProperties(original);
          nativePlacement.delete(this);
        }
        menu?.classList.remove("isbf-v2-composer-category-menu");
        menu?.style.removeProperty("--isbf-v2-category-menu-max-height");
      }

      return this._super(...arguments);
    },
  });
});
