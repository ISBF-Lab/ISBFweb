import DEmptyState from "discourse/ui-kit/d-empty-state";
import { i18n } from "discourse-i18n";

export default <template>
  <div class="user-content user-profile-hidden" id="user-content">
    {{#if @controller.model.profile_hidden}}
      <DEmptyState
        @body={{i18n "user.profile_hidden"}}
        @identifier="profile-hidden"
        @title={{i18n "isbf_profile_visibility.profile_hidden_title"}}
      />
    {{else}}
      <DEmptyState
        @body={{i18n "isbf_profile_visibility.sections_hidden.body"}}
        @identifier="profile-sections-hidden"
        @title={{i18n "isbf_profile_visibility.sections_hidden.title"}}
      />
    {{/if}}
  </div>
</template>
