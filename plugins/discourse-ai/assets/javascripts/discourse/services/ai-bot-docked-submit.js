import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { getUploadMarkdown } from "discourse/lib/uploads";
import { i18n } from "discourse-i18n";

export default class AiBotDockedSubmit extends Service {
  @service appEvents;
  @service dialog;
  @service forumAssistant;
  @service siteSettings;

  @tracked loading = false;

  async submitReply({
    topicId,
    raw,
    uploads,
    inProgressUploadsCount,
    isForumAssistant = false,
  }) {
    if (this.loading) {
      return null;
    }
    if (this.forumAssistant.restricted || isForumAssistant) {
      const status = await this.forumAssistant.refresh();
      if (!status?.can_ask) {
        this.dialog.alert({ message: this.forumAssistant.message });
        return null;
      }
      if (uploads?.length || inProgressUploadsCount > 0) {
        this.dialog.alert({
          message: i18n("discourse_ai.forum_assistant.attachments_disabled"),
        });
        return null;
      }
      if (
        raw?.length > this.siteSettings.ai_forum_assistant_max_question_chars
      ) {
        this.dialog.alert({
          message: i18n("discourse_ai.forum_assistant.question_length"),
        });
        return null;
      }
    }
    if (!topicId) {
      return null;
    }

    if (inProgressUploadsCount > 0) {
      this.dialog.alert({
        message: i18n("discourse_ai.ai_bot.conversations.uploads_in_progress"),
      });
      return null;
    }

    const hasUploads = uploads?.length > 0;

    if (!raw && !hasUploads) {
      return null;
    }

    const minLength =
      this.forumAssistant.restricted || isForumAssistant
        ? 1
        : this.siteSettings.min_personal_message_post_length;
    if (!hasUploads && raw.trim().length < minLength) {
      this.dialog.alert({
        message: i18n(
          "discourse_ai.ai_bot.conversations.min_input_length_message",
          { count: minLength }
        ),
      });
      return null;
    }

    let rawContent = raw || "";
    if (hasUploads) {
      if (rawContent.length) {
        rawContent += "\n\n";
      }
      uploads.forEach((upload) => {
        rawContent += getUploadMarkdown(upload) + "\n";
      });
    }

    this.loading = true;
    try {
      // Streaming state is not marked here: the message bus delivers
      // the first chunk (with a real post_id) within ~100ms and the
      // streaming service arms its idle timer off that. Marking with a
      // null postId would render a stop button that can't call
      // /stop-streaming.
      const response = await ajax("/posts.json", {
        method: "POST",
        data: {
          raw: rawContent,
          topic_id: topicId,
          nested_post: true,
        },
      });

      this.appEvents.trigger("discourse-ai:bot-pm-reply-created", {
        topicId,
        postId: response?.post?.id,
      });

      return response;
    } finally {
      this.loading = false;
      if (this.forumAssistant.restricted || isForumAssistant) {
        await this.forumAssistant.refresh();
      }
    }
  }
}
