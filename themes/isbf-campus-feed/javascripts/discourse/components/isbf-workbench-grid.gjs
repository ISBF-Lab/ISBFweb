import workbenchGlass from "../modifiers/workbench-glass";
import ISBFWorkbenchIcon from "./isbf-workbench-icon";

export default <template>
  <div class="isbf-workbench-grid" {{workbenchGlass @cards}}>
    <div class="isbf-workbench-grid__items">
      <canvas aria-hidden="true" class="isbf-workbench-grid__canvas" />
      {{#each @cards key="key" as |card|}}
        {{#if card.href}}
          <a
            class="isbf-workbench-grid__item"
            data-workbench-key={{card.key}}
            data-workbench-tone={{card.tone}}
            href={{card.href}}
          >
            <ISBFWorkbenchIcon
              @icon={{card.icon}}
              @label={{card.label}}
              @mobileIcon={{card.mobileIcon}}
            />
          </a>
        {{else}}
          <div
            class="isbf-workbench-grid__item"
            data-workbench-key={{card.key}}
            data-workbench-tone={{card.tone}}
          >
            <ISBFWorkbenchIcon
              @icon={{card.icon}}
              @label={{card.label}}
              @mobileIcon={{card.mobileIcon}}
            />
          </div>
        {{/if}}
      {{/each}}
    </div>
  </div>
</template>
