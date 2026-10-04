import { i18n } from "discourse-i18n";

export default <template>
  {{#if @outletArgs.post.academy_official_post}}
    <span class="academy-official-badge" ...attributes>
      {{i18n "academy_roles.official_badge"}}
    </span>
  {{/if}}
</template>
