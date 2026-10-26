import { array } from "@ember/helper";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import { or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dRovingFocus from "discourse/ui-kit/modifiers/d-roving-focus";
import { i18n } from "discourse-i18n";

const ISBFFeedCardMenu = <template>
  {{#if (or @canManageHomePin @canFlag)}}
    <div class="isbf-feed-card__menu-wrap">
      <DMenu
        aria-haspopup="menu"
        @ariaLabel={{i18n (themePrefix "isbf_v2.more_actions")}}
        @autofocus={{true}}
        @contentClass="isbf-feed-card-menu"
        @contentRole="presentation"
        @fallbackPlacements={{array "top-end" "bottom-start" "top-start"}}
        @groupIdentifier="isbf-feed-card-actions"
        @icon="ellipsis"
        @modalForMobile={{false}}
        @onRegisterApi={{@onRegisterApi}}
        @placement="bottom-end"
        @triggerClass="btn-flat isbf-feed-card__menu-trigger"
      >
        <:content>
          <DDropdownMenu
            aria-label={{i18n (themePrefix "isbf_v2.more_actions")}}
            class="isbf-feed-card__menu"
            role="menu"
            @manageFocus={{false}}
            {{dRovingFocus
              itemSelector="[role='menuitem']"
              itemsKey=(array
                @canManageHomePin @canFlag @pinned @isPinning @isFlagging
              )
              orientation="vertical"
              wrap=true
            }}
            as |dropdown|
          >
            {{#if @canManageHomePin}}
              <dropdown.item role="presentation">
                <DButton
                  class="btn-flat isbf-feed-card__pin-action"
                  role="menuitem"
                  @action={{@onPin}}
                  @disabled={{@isPinning}}
                  @icon="thumbtack"
                  @label={{themePrefix
                    (if @pinned "isbf_v2.pin_update" "isbf_v2.pin")
                  }}
                />
              </dropdown.item>
              {{#if @pinned}}
                <dropdown.item role="presentation">
                  <DButton
                    class="btn-flat isbf-feed-card__pin-action"
                    role="menuitem"
                    @action={{@onUnpin}}
                    @disabled={{@isPinning}}
                    @icon="thumbtack"
                    @label={{themePrefix "isbf_v2.pin_cancel"}}
                  />
                </dropdown.item>
              {{/if}}
            {{/if}}
            {{#if @canFlag}}
              <dropdown.item role="presentation">
                <DButton
                  class="btn-flat"
                  role="menuitem"
                  @action={{@onFlag}}
                  @disabled={{@isFlagging}}
                  @icon="flag"
                  @label={{themePrefix "isbf_v2.report"}}
                />
              </dropdown.item>
            {{/if}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    </div>
  {{/if}}
</template>;

export default ISBFFeedCardMenu;
