import { hash } from "@ember/helper";
import { notEq } from "discourse/truth-helpers";
import dMenuHighlight from "discourse/ui-kit/modifiers/d-menu-highlight";
import dRovingFocus from "discourse/ui-kit/modifiers/d-roving-focus";

const DropdownItem = <template>
  <li class="dropdown-menu__item" ...attributes>{{yield}}</li>
</template>;

const DropdownDivider = <template>
  <li ...attributes><hr class="dropdown-menu__divider" /></li>
</template>;

const DropdownSubheader = <template>
  <li class="dropdown-menu__subheader" ...attributes>{{yield}}</li>
</template>;

const DDropdownMenu = <template>
  <ul
    class="dropdown-menu"
    ...attributes
    {{(if
      (notEq @manageFocus false)
      (modifier
        dRovingFocus
        itemSelector=".dropdown-menu__item button, .dropdown-menu__item a[href], .dropdown-menu__item input[type='checkbox']"
        orientation="vertical"
        typeAhead=true
      )
    )}}
    {{dMenuHighlight}}
  >
    {{yield
      (hash
        item=DropdownItem divider=DropdownDivider subheader=DropdownSubheader
      )
    }}
  </ul>
</template>;

export default DDropdownMenu;
