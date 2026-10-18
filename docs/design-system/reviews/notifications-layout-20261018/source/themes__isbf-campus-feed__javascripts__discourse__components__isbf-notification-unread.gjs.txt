import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

export default <template>
  {{#if @unread}}
    <span aria-hidden="true" class="isbf-notification-unread"></span>
    <span class="sr-only">{{i18n
        (themePrefix "isbf_v2.notifications_unread")
      }}</span>
  {{/if}}
</template>
