import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import { frameName } from "discourse/plugins/discourse-avatar-frames/discourse/lib/avatar-frames";

export default <template>
  <DBreadcrumbsItem
    @label={{i18n "avatar_frames.admin.frames"}}
    @route="adminPlugins.show.avatar-frames"
  />
  <div class="avatar-frame-admin">
    <DPageSubheader
      @descriptionLabel={{i18n "avatar_frames.admin.description"}}
      @titleLabel={{i18n "avatar_frames.admin.frames"}}
    >
      <:actions as |actions|>
        <actions.Primary
          @label="avatar_frames.admin.new"
          @route="adminPlugins.show.avatar-frames.new"
        />
      </:actions>
    </DPageSubheader>
    <table class="d-table avatar-frame-admin__table">
      <thead>
        <tr>
          <th>{{i18n "avatar_frames.admin.name"}}</th>
          <th>{{i18n "avatar_frames.admin.access"}}</th>
          <th>{{i18n "avatar_frames.admin.status"}}</th>
          <th>{{i18n "avatar_frames.admin.owners"}}</th>
          <th>{{i18n "avatar_frames.admin.actions"}}</th>
        </tr>
      </thead>
      <tbody>
        {{#each @data.frames as |frame|}}
          <tr class="d-table__row">
            <td
              class="d-table__cell"
              data-label={{i18n "avatar_frames.admin.name"}}
            >
              <span class="avatar-frame-admin__name"><img
                  alt=""
                  class="avatar-frame-admin__thumbnail"
                  src={{frame.static_url}}
                />{{frameName frame}}</span>
            </td>
            <td
              class="d-table__cell"
              data-label={{i18n "avatar_frames.admin.access"}}
            >{{if
                (eq frame.access_mode "public")
                (i18n "avatar_frames.admin.public")
                (i18n "avatar_frames.admin.granted")
              }}</td>
            <td
              class="d-table__cell"
              data-label={{i18n "avatar_frames.admin.status"}}
            >{{if
                frame.enabled
                (i18n "avatar_frames.admin.enabled")
                (i18n "avatar_frames.admin.disabled")
              }}</td>
            <td
              class="d-table__cell"
              data-label={{i18n "avatar_frames.admin.owners"}}
            >{{frame.grants_count}}</td>
            <td
              class="d-table__cell"
              data-label={{i18n "avatar_frames.admin.actions"}}
            >
              <div class="avatar-frame-admin__actions">
                <LinkTo
                  class="btn btn-default btn-small"
                  @model={{frame.id}}
                  @route="adminPlugins.show.avatar-frames.edit"
                >{{i18n "avatar_frames.admin.edit"}}</LinkTo>
                {{#if (eq frame.access_mode "granted")}}
                  <LinkTo
                    class="btn btn-default btn-small"
                    @model={{frame.id}}
                    @route="adminPlugins.show.avatar-frames.grants"
                  >{{i18n "avatar_frames.admin.manage_grants"}}</LinkTo>
                {{/if}}
              </div>
            </td>
          </tr>
        {{else}}
          <tr><td colspan="5">{{i18n "avatar_frames.admin.empty"}}</td></tr>
        {{/each}}
      </tbody>
    </table>
  </div>
</template>
