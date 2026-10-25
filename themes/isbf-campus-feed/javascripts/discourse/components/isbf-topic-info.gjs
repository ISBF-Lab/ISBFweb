import Component from "@glimmer/component";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import TopicFooterButtons from "discourse/components/topic-footer-buttons";
import TopicMap from "discourse/components/topic-map";
import routeAction from "discourse/helpers/route-action";
import topicDisplayTitle from "discourse/lib/topic-display-title";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFTopicInfo extends Component {
  @service currentUser;

  get controller() {
    return getOwner(this).lookup("controller:topic");
  }

  @action
  async editTitle() {
    this.args.closeModal();
    await this.controller.editTopic();
    document.querySelector("#topic-title")?.scrollIntoView({ block: "start" });
  }

  <template>
    <DModal
      class="isbf-topic-info"
      @closeModal={{@closeModal}}
      @title={{themePrefix "isbf_v2.topic_info"}}
    >
      <:body>
        <h2>{{topicDisplayTitle @model.title @model}}</h2>
        <p>{{@model.category.name}}</p>
        {{#if @model.details.can_edit}}
          <DButton
            @action={{this.editTitle}}
            @icon="pencil"
            @translatedLabel={{i18n (themePrefix "isbf_v2.topic_edit_title")}}
          />
        {{/if}}
        <div class="topic-map">
          <TopicMap
            @cancelFilter={{this.controller.cancelFilter}}
            @model={{@model}}
            @postStream={{@model.postStream}}
            @showPMMap={{false}}
            @topicDetails={{@model.details}}
          />
        </div>
        {{#if this.currentUser}}
          <TopicFooterButtons
            @convertToPrivateMessage={{this.controller.convertToPrivateMessage}}
            @convertToPublicTopic={{this.controller.convertToPublicTopic}}
            @deferTopic={{this.controller.deferTopic}}
            @deleteTopic={{this.controller.deleteTopic}}
            @editFirstPost={{this.controller.editFirstPost}}
            @recoverTopic={{this.controller.recoverTopic}}
            @replyToPost={{this.controller.replyToPost}}
            @resetBumpDate={{this.controller.resetBumpDate}}
            @showChangeTimestamp={{routeAction "showChangeTimestamp"}}
            @showCreate={{false}}
            @showFeatureTopic={{routeAction "showFeatureTopic"}}
            @showFlagTopic={{routeAction "showFlagTopic"}}
            @showTopicSlowModeUpdate={{routeAction "showTopicSlowModeUpdate"}}
            @showTopicTimerModal={{routeAction "showTopicTimerModal"}}
            @toggleArchived={{this.controller.toggleArchived}}
            @toggleBookmark={{this.controller.toggleBookmark}}
            @toggleClosed={{this.controller.toggleClosed}}
            @toggleFeaturedOnProfile={{this.controller.toggleFeaturedOnProfile}}
            @toggleMultiSelect={{this.controller.toggleMultiSelect}}
            @toggleVisibility={{this.controller.toggleVisibility}}
            @topic={{@model}}
          />
        {{/if}}
      </:body>
    </DModal>
  </template>
}
