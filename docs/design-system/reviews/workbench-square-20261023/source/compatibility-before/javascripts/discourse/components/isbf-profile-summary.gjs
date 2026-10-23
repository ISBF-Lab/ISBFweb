import Component from "@glimmer/component";
import UserSummaryTopic from "discourse/components/user-summary-topic";
import UserSummaryUser from "discourse/components/user-summary-user";
import ISBFProfileSummarySection from "./isbf-profile-summary-section";

export default class ISBFProfileSummary extends Component {
  get profiles() {
    return this.summary && this.user?.id != null ? [this.user] : [];
  }

  get summary() {
    return this.args.outletArgs?.model;
  }

  get user() {
    return this.args.outletArgs?.user;
  }

  <template>
    {{#each this.profiles key="id" as |profileUser|}}
      <div class="isbf-profile-summary">
        <ISBFProfileSummarySection
          @emptyKey="user.summary.no_replies"
          @items={{this.summary.replies}}
          @moreLabel="user.summary.more_replies"
          @moreRoute="userActivity.replies"
          @title="top_replies"
          @user={{profileUser}}
          as |reply|
        >
          <UserSummaryTopic
            @createdAt={{reply.createdAt}}
            @likes={{reply.like_count}}
            @topic={{reply.topic}}
            @url={{reply.url}}
          />
        </ISBFProfileSummarySection>

        <ISBFProfileSummarySection
          @emptyKey="user.summary.no_topics"
          @items={{this.summary.topics}}
          @moreLabel="user.summary.more_topics"
          @moreRoute="userActivity.topics"
          @title="top_topics"
          @user={{profileUser}}
          as |topic|
        >
          <UserSummaryTopic
            @createdAt={{topic.created_at}}
            @likes={{topic.like_count}}
            @topic={{topic}}
            @url={{topic.url}}
          />
        </ISBFProfileSummarySection>

        <ISBFProfileSummarySection
          @emptyKey="user.summary.no_replies"
          @isUserList={{true}}
          @items={{this.summary.most_replied_to_users}}
          @title="most_replied_to_users"
          as |user|
        >
          <UserSummaryUser @countClass="replies" @icon="reply" @user={{user}} />
        </ISBFProfileSummarySection>

        <ISBFProfileSummarySection
          @emptyKey="user.summary.no_likes"
          @isUserList={{true}}
          @items={{this.summary.most_liked_by_users}}
          @title="most_liked_by"
          as |user|
        >
          <UserSummaryUser @countClass="likes" @icon="heart" @user={{user}} />
        </ISBFProfileSummarySection>

        <ISBFProfileSummarySection
          @emptyKey="user.summary.no_likes"
          @isUserList={{true}}
          @items={{this.summary.most_liked_users}}
          @title="most_liked_users"
          as |user|
        >
          <UserSummaryUser @countClass="likes" @icon="heart" @user={{user}} />
        </ISBFProfileSummarySection>
      </div>
    {{/each}}
  </template>
}
