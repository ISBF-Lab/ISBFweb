import type { TemplateOnlyComponent } from "@ember/component/template-only";
import DInlineFloat from "discourse/float-kit/components/d-inline-float";
import type DMenuInstance from "discourse/float-kit/lib/d-menu-instance";
import { eq } from "discourse/truth-helpers";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";

interface DHeadlessMenuSignature {
  Args: {
    /** The menu instance to render. */
    menu: DMenuInstance;

    /** Whether to render in place instead of into the portal outlet. */
    inline?: boolean | null;
  };
}

/**
 * Renders a menu instance created through the `menu` service, whose trigger
 * lives elsewhere in the DOM rather than being owned by this component. It is
 * mounted once by `DMenus` at the app root, which iterates every registered
 * menu with a detached trigger. Compare `DMenu`, the declarative component that
 * owns both its trigger and its instance.
 */
const DHeadlessMenu: TemplateOnlyComponent<DHeadlessMenuSignature> = <template>
  <DInlineFloat
    @inline={{@inline}}
    @inlineTabOrder={{@menu.options.inlineTabOrder}}
    @innerClass={{dConcatClass
      "fk-d-menu__inner-content"
      (if (eq @menu.options.surface "menu") "d-menu-surface")
    }}
    @instance={{@menu}}
    @mainClass={{dConcatClass
      "fk-d-menu"
      (if (eq @menu.options.surface "menu") "--menu-surface")
    }}
    @menuHighlight={{eq @menu.options.surface "menu"}}
    @role={{@menu.options.contentRole}}
    @trapTab={{@menu.options.trapTab}}
  />
</template>;

export default DHeadlessMenu;
