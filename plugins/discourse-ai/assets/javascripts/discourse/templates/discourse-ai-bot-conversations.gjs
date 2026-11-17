import AiBotConversations from "discourse/plugins/discourse-ai/discourse/components/ai-bot-conversations";
import AiBotConversationsPreview from "discourse/plugins/discourse-ai/discourse/components/ai-bot-conversations-preview";
import ForumAssistantWorkspace from "discourse/plugins/discourse-ai/discourse/components/forum-assistant-workspace";

export default <template>
  {{#if @controller.showForumWorkspace}}
    <ForumAssistantWorkspace @conversationId={{@controller.conversation}} />
  {{else if @controller.showPreview}}
    <AiBotConversationsPreview />
  {{else}}
    <AiBotConversations @controller={{@controller}} />
  {{/if}}
</template>
