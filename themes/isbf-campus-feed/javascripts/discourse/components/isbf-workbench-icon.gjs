import dIcon from "discourse/ui-kit/helpers/d-icon";

export default <template>
  <span aria-hidden="true" class="isbf-workbench-grid__plate" />
  <span aria-hidden="true" class="isbf-workbench-grid__glass" />
  <span class="isbf-workbench-grid__face">
    <span aria-hidden="true" class="isbf-workbench-grid__glyph">{{dIcon
        @icon
      }}</span>
    <span aria-hidden="true" class="isbf-workbench-grid__mobile-icon">{{dIcon
        @mobileIcon
      }}</span>
    <span class="isbf-workbench-grid__label">{{@label}}</span>
  </span>
</template>
