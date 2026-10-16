import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import getURL from "discourse/lib/get-url";
import { iconHTML } from "discourse/lib/icon-library";
import { categoryBadgeHTML } from "discourse/ui-kit/helpers/d-category-link";
import I18n, { i18n } from "discourse-i18n";

export default class BrowseMore extends Component {
  @service currentUser;
  @service pmTopicTrackingState;
  @service site;
  @service topicTrackingState;
  @service siteSettings;

  get privateMessageBrowseMoreMessage() {
    const suggestedGroupName = this.args.topic.get("suggested_group_name");
    const inboxFilter = suggestedGroupName ? "group" : "user";

    const unreadCount = this.pmTopicTrackingState.lookupCount("unread", {
      inboxFilter,
      groupName: suggestedGroupName,
    });

    const newCount = this.pmTopicTrackingState.lookupCount("new", {
      inboxFilter,
      groupName: suggestedGroupName,
    });

    if (unreadCount + newCount > 0) {
      const hasBoth = unreadCount > 0 && newCount > 0;

      if (suggestedGroupName) {
        return I18n.messageFormat("user.messages.read_more_group_pm_MF", {
          HAS_UNREAD_AND_NEW: hasBoth,
          UNREAD: unreadCount,
          NEW: newCount,
          username: this.currentUser.username,
          groupName: suggestedGroupName,
          groupLink: this.groupLink(suggestedGroupName),
          basePath: getURL(""),
        });
      } else {
        return I18n.messageFormat("user.messages.read_more_personal_pm_MF", {
          HAS_UNREAD_AND_NEW: hasBoth,
          UNREAD: unreadCount,
          NEW: newCount,
          username: this.currentUser.username,
          basePath: getURL(""),
        });
      }
    } else if (suggestedGroupName) {
      return i18n("user.messages.read_more_in_group", {
        groupLink: this.groupLink(suggestedGroupName),
      });
    } else {
      return i18n("user.messages.read_more", {
        basePath: getURL(""),
        username: this.currentUser.username,
      });
    }
  }

  get topicBrowseMoreData() {
    this.topicTrackingState.get("messageCount");

    let category = this.args.topic.get("category");

    if (category && category.id === this.site.uncategorized_category_id) {
      category = null;
    }

    let unreadTopics = 0;
    let newTopics = 0;

    if (this.currentUser) {
      unreadTopics = this.topicTrackingState.countUnread();
      newTopics = this.topicTrackingState.countNew();
    }

    return {
      category,
      newTopics,
      unreadTopics,
      newUrl: this.siteSettings.enable_unified_new
        ? getURL("/new?subset=topics")
        : getURL("/new"),
      unreadUrl: this.siteSettings.enable_unified_new
        ? getURL("/new?subset=replies")
        : getURL("/unread"),
      latestUrl: getURL("/latest"),
      categoriesUrl: getURL("/categories"),
    };
  }

  get topicBrowseMoreMessage() {
    const {
      category,
      newTopics,
      unreadTopics,
      newUrl,
      unreadUrl,
      latestUrl,
      categoriesUrl,
    } = this.topicBrowseMoreData;

    if (newTopics + unreadTopics > 0) {
      return I18n.messageFormat("topic.read_more_MF", {
        HAS_UNREAD_AND_NEW: unreadTopics > 0 && newTopics > 0,
        UNREAD: unreadTopics,
        NEW: newTopics,
        HAS_CATEGORY: !!category,
        categoryLink: category ? categoryBadgeHTML(category) : null,
        basePath: getURL(""),
        unreadUrl,
        newUrl,
      });
    } else if (category) {
      return i18n("topic.read_more_in_category", {
        categoryLink: categoryBadgeHTML(category),
        latestLink: latestUrl,
      });
    } else {
      return i18n("topic.read_more", {
        categoryLink: categoriesUrl,
        latestLink: latestUrl,
      });
    }
  }

  groupLink(groupName) {
    return `<a class="group-link" href="${getURL(
      `/u/${this.currentUser.username}/messages/group/${groupName}`
    )}">${iconHTML("users")} ${groupName}</a>`;
  }

  <template>
    <h3 class="more-topics__browse-more">
      {{#if @topic.isPrivateMessage}}
        {{trustHTML this.privateMessageBrowseMoreMessage}}
      {{else}}
        {{trustHTML this.topicBrowseMoreMessage}}
      {{/if}}
    </h3>
  </template>
}
