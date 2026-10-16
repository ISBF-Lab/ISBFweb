import { array, concat, fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { trustHTML } from "@ember/template";
import AddCategoryTagClasses from "discourse/components/add-category-tag-classes";
import AddTopicStatusClasses from "discourse/components/add-topic-status-classes";
import AnonymousTopicFooterButtons from "discourse/components/anonymous-topic-footer-buttons";
import DiscourseBanner from "discourse/components/discourse-banner";
import DiscourseTopic from "discourse/components/discourse-topic";
import EmbedModeComposer from "discourse/components/embed-mode-composer";
import EmbedTopicFooter from "discourse/components/embed-topic-footer";
import MoreTopics from "discourse/components/more-topics";
import Nested from "discourse/components/nested";
import PluginOutlet from "discourse/components/plugin-outlet";
import PostStream from "discourse/components/post-stream";
import PostTextSelection from "discourse/components/post-text-selection";
import PrivateMessageGlyph from "discourse/components/private-message-glyph";
import ReviewableCreatedBy from "discourse/components/reviewable-created-by";
import ReviewableCreatedByName from "discourse/components/reviewable-created-by-name";
import SelectedPosts from "discourse/components/selected-posts";
import SharedDraftControls from "discourse/components/shared-draft-controls";
import SignupCta from "discourse/components/signup-cta";
import SlowModeInfo from "discourse/components/slow-mode-info";
import TopicAdminMenu from "discourse/components/topic-admin-menu";
import TopicCategory from "discourse/components/topic-category";
import TopicContentLanguagePreferences from "discourse/components/topic-content-language-preferences";
import TopicFooterButtons from "discourse/components/topic-footer-buttons";
import TopicMap from "discourse/components/topic-map/index";
import TopicMetadata from "discourse/components/topic-metadata";
import TopicNavigation from "discourse/components/topic-navigation";
import TopicProgress from "discourse/components/topic-progress";
import TopicSkipLinks from "discourse/components/topic-skip-links";
import TopicStatus from "discourse/components/topic-status";
import TopicTimeline from "discourse/components/topic-timeline";
import TopicTimerInfo from "discourse/components/topic-timer-info";
import TopicTitle from "discourse/components/topic-title";
import TopicTitleEditor from "discourse/components/topic-title-editor";
import bodyClass from "discourse/helpers/body-class";
import hideApplicationFooter from "discourse/helpers/hide-application-footer";
import hideScrollableContent from "discourse/helpers/hide-scrollable-content";
import lazyHash from "discourse/helpers/lazy-hash";
import routeAction from "discourse/helpers/route-action";
import { and, eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DCookText from "discourse/ui-kit/d-cook-text";
import dAgeWithTooltip from "discourse/ui-kit/helpers/d-age-with-tooltip";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import booleanString from "../helpers/boolean-string";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
export default setComponentTemplate(createTemplateFactory(
/*
  {{#unless @controller.shouldRenderNestedView}}
  {{#let @controller.model.postStream as |postStream|}}
    {{#unless (and postStream.loaded postStream.loadedAllPosts)}}
      {{hideApplicationFooter}}
    {{/unless}}
  {{/let}}
{{/unless}}

<DiscourseTopic
  @enteredAt={{@controller.enteredAt}}
  @hasScrolled={{@controller.hasScrolled}}
  @multiSelect={{@controller.multiSelect}}
  @topic={{@controller.model}}
>
  <TopicSkipLinks
    @postStream={{@controller.model.postStream}}
    @topic={{@controller.model}}
  />
  {{#if @controller.model}}
    <AddCategoryTagClasses
      @category={{@controller.model.category}}
      @tags={{@controller.model.tags}}
    />
    <AddTopicStatusClasses @topic={{@controller.model}} />
    {{bodyClass (concat "archetype-" @controller.model.archetype)}}
    {{#if @controller.shouldRenderNestedView}}
      {{#let @controller.nestedController as |nested|}}
        <PostTextSelection
          @buildQuoteMarkdown={{nested.buildQuoteMarkdown}}
          @editPost={{nested.editPost}}
          @quoteState={{nested.quoteState}}
          @selectText={{nested.selectText}}
          @topic={{@controller.model}}
        />

        <div
          class="selected-posts nested-view__selected-posts
            {{unless nested.multiSelect 'hidden'}}"
        >
          <SelectedPosts
            @canChangeOwner={{nested.canChangeOwner}}
            @canDeleteSelected={{nested.canDeleteSelected}}
            @canDeselectAll={{nested.canDeselectAll}}
            @canMergePosts={{nested.canMergePosts}}
            @canMergeTopic={{nested.canMergeTopic}}
            @canSelectAll={{nested.canSelectAll}}
            @deleteSelected={{nested.deleteSelected}}
            @deselectAll={{nested.deselectAll}}
            @mergePosts={{nested.mergePosts}}
            @selectAll={{nested.selectAll}}
            @selectedPostsCount={{nested.selectedPostsCount}}
            @toggleMultiSelect={{nested.toggleMultiSelect}}
          />
        </div>

        <Nested
          @ancestorsTruncated={{nested.ancestorsTruncated}}
          @buffered={{nested.buffered}}
          @cancelEditingTopic={{nested.cancelEditingTopic}}
          @canEditTags={{nested.canEditTags}}
          @changeNotice={{nested.changeNotice}}
          @changePostOwner={{nested.changePostOwner}}
          @changeSort={{nested.changeSort}}
          @clearScrollAnchor={{nested.clearScrollAnchor}}
          @collapseReplies={{nested.collapseReplies}}
          @contextMode={{nested.contextMode}}
          @contextNoAncestors={{nested.contextNoAncestors}}
          @deletePost={{nested.deletePost}}
          @editingTopic={{nested.editingTopic}}
          @editPost={{nested.editPost}}
          @effectiveSort={{nested.effectiveSort}}
          @expansionState={{nested.expansionState}}
          @fetchedChildrenCache={{nested.fetchedChildrenCache}}
          @finishedEditingTopic={{nested.finishedEditingTopic}}
          @firstRootPage={{nested.firstRootPage}}
          @grantBadge={{nested.grantBadge}}
          @hasMoreRoots={{nested.hasMoreRoots}}
          @initialFocusedPath={{nested.initialFocusedPath}}
          @loadingMore={{nested.loadingMore}}
          @loadingPreviousRoots={{nested.loadingPreviousRoots}}
          @loadMoreRoots={{nested.loadMoreRoots}}
          @loadNewRoots={{nested.loadNewRoots}}
          @loadPreviousRoots={{nested.loadPreviousRoots}}
          @lockPost={{nested.lockPost}}
          @minimumRequiredTags={{nested.minimumRequiredTags}}
          @multiSelect={{nested.multiSelect}}
          @newRootPostCount={{nested.newRootPostCount}}
          @opPost={{nested.opPost}}
          @permanentlyDeletePost={{nested.permanentlyDeletePost}}
          @pinnedPostIds={{nested.pinnedPostIds}}
          @postNumber={{nested.postNumber}}
          @postSelected={{nested.postSelected}}
          @rebakePost={{nested.rebakePost}}
          @recoverPost={{nested.recoverPost}}
          @replyToPost={{nested.replyToPost}}
          @rootNodes={{nested.rootNodes}}
          @saveScrollPosition={{nested.saveScrollPosition}}
          @scrollAnchor={{nested.scrollAnchor}}
          @selectBelow={{nested.selectBelow}}
          @selectReplies={{nested.selectReplies}}
          @setFocusedPostNumber={{nested.setFocusedPostNumber}}
          @showActivityLog={{nested.showActivityLog}}
          @showCategoryChooser={{nested.showCategoryChooser}}
          @showFlags={{nested.showFlags}}
          @showHistory={{nested.showHistory}}
          @showPagePublish={{nested.showPagePublish}}
          @sort={{nested.sort}}
          @startEditingTopic={{nested.startEditingTopic}}
          @targetPostNumber={{nested.targetPostNumber}}
          @togglePostSelection={{nested.togglePostSelection}}
          @togglePostType={{nested.togglePostType}}
          @toggleWiki={{nested.toggleWiki}}
          @topic={{@controller.model}}
          @topicCategoryChanged={{nested.topicCategoryChanged}}
          @topicTagsChanged={{nested.topicTagsChanged}}
          @unhidePost={{nested.unhidePost}}
          @unlockPost={{nested.unlockPost}}
          @viewFullThread={{nested.viewFullThread}}
          @viewParentContext={{nested.viewParentContext}}
        />
      {{/let}}
    {{else}}

      {{#unless @controller.shouldHideScrollableContentAbove}}
        <div class="container">
          <DiscourseBanner
            @hide={{@controller.model.errorLoading}}
            @overlay={{@controller.hasScrolled}}
          />
        </div>
      {{/unless}}

      {{#unless @controller.shouldHideScrollableContentAbove}}
        {{#if @controller.showSharedDraftControls}}
          <SharedDraftControls @topic={{@controller.model}} />
        {{/if}}

        <span>
          <PluginOutlet
            @connectorTagName="div"
            @name="topic-above-post-stream"
            @outletArgs={{lazyHash
              model=@controller.model
              editFirstPost=@controller.editFirstPost
            }}
          />
        </span>
      {{/unless}}

      {{#if @controller.model.postStream.loaded}}
        {{#if @controller.model.postStream.firstPostPresent}}
          <TopicTitle
            @cancelled={{@controller.cancelEditingTopic}}
            @model={{@controller.model}}
            @save={{@controller.finishedEditingTopic}}
          >
            {{#if @controller.editingTopic}}
              <div class="edit-topic-title">
                <PrivateMessageGlyph
                  @shouldShow={{@controller.model.isPrivateMessage}}
                />

                <TopicTitleEditor
                  @buffered={{@controller.buffered}}
                  @bufferedTitle={{@controller.buffered.title}}
                  @isEditingLocalization={{@controller.editingTopicLocalization}}
                  @model={{@controller.model}}
                  @translationLocale={{@controller.translationLocale}}
                  @translationTitle={{@controller.translationTitle}}
                />

                <TopicMetadata
                  @buffered={{@controller.buffered}}
                  @canEditTags={{@controller.canEditTags}}
                  @minimumRequiredTags={{@controller.minimumRequiredTags}}
                  @model={{@controller.model}}
                  @onCancel={{@controller.cancelEditingTopic}}
                  @onSave={{@controller.finishedEditingTopic}}
                  @showCategoryChooser={{@controller.showCategoryChooser}}
                  @topicCategoryChanged={{@controller.topicCategoryChanged}}
                  @topicTagsChanged={{@controller.topicTagsChanged}}
                >
                  {{#if @controller.canRemoveTopicFeaturedLink}}
                    <a
                      class="remove-featured-link"
                      href
                      title={{i18n "composer.remove_featured_link"}}
                      {{on "click" @controller.removeFeaturedLink}}
                    >
                      {{dIcon "circle-xmark"}}
                      {{@controller.featuredLinkDomain}}
                    </a>
                  {{/if}}
                </TopicMetadata>
              </div>

            {{else}}
              <h1
                {{! Prevent duplicating the topic title heading on screen readers when the header is displaying the title
              in the header }}
                aria-hidden={{booleanString
                  @controller.titleIsVisibleOnHeader
                }}
                data-topic-id={{@controller.model.id}}
              >
                {{#unless @controller.model.is_warning}}
                  {{#if @controller.canSendPms}}
                    <PrivateMessageGlyph
                      @ariaLabel="user.messages.inbox"
                      @href={{@controller.pmPath}}
                      @shouldShow={{@controller.model.isPrivateMessage}}
                      @title="topic_statuses.personal_message.title"
                    />
                  {{else}}
                    <PrivateMessageGlyph
                      @shouldShow={{@controller.model.isPrivateMessage}}
                    />
                  {{/if}}
                {{/unless}}

                {{#if @controller.model.details.loaded}}
                  <TopicStatus @topic={{@controller.model}} />
                  <a
                    class="fancy-title"
                    href={{@controller.model.url}}
                    {{on "click" @controller.handleTitleClick}}
                  >
                    {{trustHTML @controller.model.fancyTitle~}}
                    {{~#if @controller.model.details.can_edit~}}
                      <span class="edit-topic__wrapper">
                        {{dIcon "pencil" class="edit-topic"}}
                      </span>
                    {{~/if}}
                  </a>
                {{/if}}

                <PluginOutlet
                  @name="topic-title-suffix"
                  @outletArgs={{lazyHash model=@controller.model}}
                />
              </h1>

              <PluginOutlet
                @name="topic-category-wrapper"
                @outletArgs={{lazyHash topic=@controller.model}}
              >
                <TopicCategory
                  class="topic-category"
                  @topic={{@controller.model}}
                />
              </PluginOutlet>

            {{/if}}
          </TopicTitle>

          {{#if @controller.model.publishedPage}}
            <div class="published-page-notice">
              <div class="details">
                {{#if @controller.model.publishedPage.public}}
                  <span class="is-public">{{i18n
                      "topic.publish_page.public"
                    }}</span>
                {{/if}}
                {{i18n "topic.publish_page.topic_published"}}
                <div>
                  <a
                    href={{@controller.model.publishedPage.url}}
                    rel="noopener noreferrer"
                    target="_blank"
                  >{{@controller.model.publishedPage.url}}</a>
                </div>
              </div>
              <div class="controls">
                <DButton
                  @action={{routeAction "showPagePublish"}}
                  @icon="file"
                  @label="topic.publish_page.publishing_settings"
                />
              </div>
            </div>
          {{/if}}

        {{/if}}

        <div class="container posts">
          <div
            class="selected-posts {{unless @controller.multiSelect 'hidden'}}"
          >
            <SelectedPosts
              @canChangeOwner={{@controller.canChangeOwner}}
              @canDeleteSelected={{@controller.canDeleteSelected}}
              @canDeselectAll={{@controller.canDeselectAll}}
              @canMergePosts={{@controller.canMergePosts}}
              @canMergeTopic={{@controller.canMergeTopic}}
              @canSelectAll={{@controller.canSelectAll}}
              @deleteSelected={{@controller.deleteSelected}}
              @deselectAll={{@controller.deselectAll}}
              @mergePosts={{@controller.mergePosts}}
              @selectAll={{@controller.selectAll}}
              @selectedPostsCount={{@controller.selectedPostsCount}}
              @toggleMultiSelect={{@controller.toggleMultiSelect}}
            />
          </div>

          {{#if
            (and @controller.showBottomTopicMap @controller.loadedAllPosts)
          }}
            <div class="topic-map --bottom">
              <TopicMap
                @model={{@controller.model}}
                @postStream={{@controller.model.postStream}}
                @removeAllowedGroup={{@controller.removeAllowedGroup}}
                @removeAllowedUser={{@controller.removeAllowedUser}}
                @showInvite={{routeAction "showInvite"}}
                @showPMMap={{eq
                  @controller.model.archetype
                  "private_message"
                }}
                @topicDetails={{@controller.model.details}}
              />
            </div>
          {{/if}}

          <PluginOutlet @connectorTagName="div" @name="above-timeline" />

          <TopicNavigation
            class="topic-navigation"
            @jumpToDate={{@controller.jumpToDate}}
            @jumpToIndex={{@controller.jumpToIndex}}
            @topic={{@controller.model}}
            as |info toggleProgressExpansion|
          >
            <PluginOutlet
              @connectorTagName="div"
              @name="topic-navigation"
              @outletArgs={{lazyHash
                topic=@controller.model
                renderTimeline=info.renderTimeline
                topicProgressExpanded=info.topicProgressExpanded
              }}
            />

            {{#if info.renderTimeline}}
              <TopicTimeline
                @convertToPrivateMessage={{@controller.convertToPrivateMessage}}
                @convertToPublicTopic={{@controller.convertToPublicTopic}}
                @deleteTopic={{@controller.deleteTopic}}
                @enteredIndex={{@controller.enteredIndex}}
                @fullscreen={{info.topicProgressExpanded}}
                @info={{info}}
                @jumpBottom={{@controller.jumpBottom}}
                @jumpEnd={{@controller.jumpEnd}}
                @jumpToIndex={{@controller.jumpToIndex}}
                @jumpTop={{@controller.jumpTop}}
                @jumpToPostPrompt={{@controller.jumpToPostPrompt}}
                @model={{@controller.model}}
                @prevEvent={{info.prevEvent}}
                @recoverTopic={{@controller.recoverTopic}}
                @replyToPost={{@controller.replyToPost}}
                @resetBumpDate={{@controller.resetBumpDate}}
                @showChangeTimestamp={{routeAction "showChangeTimestamp"}}
                @showFeatureTopic={{routeAction "showFeatureTopic"}}
                @showTopicSlowModeUpdate={{routeAction
                  "showTopicSlowModeUpdate"
                }}
                @showTopicTimerModal={{routeAction "showTopicTimerModal"}}
                @showTopReplies={{@controller.showTopReplies}}
                @toggleArchived={{@controller.toggleArchived}}
                @toggleClosed={{@controller.toggleClosed}}
                @toggleMultiSelect={{@controller.toggleMultiSelect}}
                @toggleVisibility={{@controller.toggleVisibility}}
              />
            {{else}}
              <TopicProgress
                @jumpToPost={{@controller.jumpToPost}}
                @onExpandToggle={{toggleProgressExpansion}}
                @prevEvent={{info.prevEvent}}
                @topic={{@controller.model}}
              >
                <PluginOutlet
                  @connectorTagName="div"
                  @name="before-topic-progress"
                  @outletArgs={{lazyHash
                    model=@controller.model
                    jumpToPost=@controller.jumpToPost
                  }}
                />
                <TopicAdminMenu
                  @convertToPrivateMessage={{@controller.convertToPrivateMessage}}
                  @convertToPublicTopic={{@controller.convertToPublicTopic}}
                  @deleteTopic={{@controller.deleteTopic}}
                  @recoverTopic={{@controller.recoverTopic}}
                  @resetBumpDate={{@controller.resetBumpDate}}
                  @showChangeTimestamp={{routeAction "showChangeTimestamp"}}
                  @showFeatureTopic={{routeAction "showFeatureTopic"}}
                  @showTopicSlowModeUpdate={{routeAction
                    "showTopicSlowModeUpdate"
                  }}
                  @showTopicTimerModal={{routeAction "showTopicTimerModal"}}
                  @toggleArchived={{@controller.toggleArchived}}
                  @toggleClosed={{@controller.toggleClosed}}
                  @toggleMultiSelect={{@controller.toggleMultiSelect}}
                  @toggleVisibility={{@controller.toggleVisibility}}
                  @topic={{@controller.model}}
                />
                {{#if @controller.model.has_localized_content}}
                  <TopicContentLanguagePreferences />
                {{/if}}
              </TopicProgress>
            {{/if}}

            <PluginOutlet
              @connectorTagName="div"
              @name="topic-navigation-bottom"
              @outletArgs={{lazyHash model=@controller.model}}
            />
          </TopicNavigation>

          <div class="row">
            <section
              class="topic-area"
              data-topic-id={{@controller.model.id}}
              id="topic"
            >
              <div class="posts-wrapper">
                <span>
                  <PluginOutlet
                    @connectorTagName="div"
                    @name="topic-above-posts"
                    @outletArgs={{lazyHash model=@controller.model}}
                  />
                </span>

                {{#if @controller.model.postStream.firstPostNotLoaded}}
                  {{hideScrollableContent "above"}}
                {{/if}}

                {{#unless @controller.model.postStream.loadingFilter}}
                  <PostStream
                    @bottomVisibleChanged={{@controller.bottomVisibleChanged}}
                    @cancelFilter={{@controller.cancelFilter}}
                    @canCreatePost={{@controller.model.details.can_create_post}}
                    @changeNotice={{@controller.changeNotice}}
                    @changePostOwner={{@controller.changePostOwner}}
                    @currentPostChanged={{@controller.currentPostChanged}}
                    @currentPostScrolled={{@controller.currentPostScrolled}}
                    @deletePost={{@controller.deletePost}}
                    @editPost={{@controller.editPost}}
                    @expandHidden={{@controller.expandHidden}}
                    @fillGapAfter={{@controller.fillGapAfter}}
                    @fillGapBefore={{@controller.fillGapBefore}}
                    @filteredPostsCount={{@controller.model.postStream.filteredPostsCount}}
                    @filteringRepliesToPostNumber={{@controller.replies_to_post_number}}
                    @gaps={{@controller.model.postStream.gaps}}
                    @grantBadge={{@controller.grantBadge}}
                    @highestPostNumber={{@controller.highestPostNumber}}
                    @lastReadPostNumber={{@controller.userLastReadPostNumber}}
                    @lockPost={{@controller.lockPost}}
                    @multiSelect={{@controller.multiSelect}}
                    @permanentlyDeletePost={{@controller.permanentlyDeletePost}}
                    @postSelected={{@controller.postSelected}}
                    @postStream={{@controller.model.postStream}}
                    @rebakePost={{@controller.rebakePost}}
                    @recoverPost={{@controller.recoverPost}}
                    @removeAllowedGroup={{@controller.removeAllowedGroup}}
                    @removeAllowedUser={{@controller.removeAllowedUser}}
                    @replyToPost={{@controller.replyToPost}}
                    @selectBelow={{@controller.selectBelow}}
                    @selectedPostsCount={{@controller.selectedPostsCount}}
                    @selectedQuery={{@controller.selectedQuery}}
                    @selectReplies={{@controller.selectReplies}}
                    @showFlags={{@controller.showPostFlags}}
                    @showHistory={{routeAction "showHistory"}}
                    @showInvite={{routeAction "showInvite"}}
                    @showLogin={{routeAction "showLogin"}}
                    @showPagePublish={{routeAction "showPagePublish"}}
                    @showRawEmail={{routeAction "showRawEmail"}}
                    @showReadIndicator={{@controller.model.show_read_indicator}}
                    @showTopReplies={{@controller.showTopReplies}}
                    @streamFilters={{@controller.model.postStream.streamFilters}}
                    @toggleBookmark={{@controller.toggleBookmark}}
                    @togglePostSelection={{@controller.togglePostSelection}}
                    @togglePostType={{@controller.togglePostType}}
                    @toggleWiki={{@controller.toggleWiki}}
                    @topic={{@controller.model}}
                    @topicPageQueryParams={{@controller.topicPageQueryParams}}
                    @topVisibleChanged={{@controller.topVisibleChanged}}
                    @unhidePost={{@controller.unhidePost}}
                    @unlockPost={{@controller.unlockPost}}
                    @updateTopicPageQueryParams={{@controller.updateTopicPageQueryParams}}
                  />
                {{/unless}}

                {{#if @controller.model.postStream.lastPostNotLoaded}}
                  {{hideScrollableContent "below"}}
                {{/if}}
              </div>
              <div id="topic-bottom"></div>

              <DConditionalLoadingSpinner
                @condition={{@controller.model.postStream.loadingFilter}}
              >
                {{#if @controller.loadedAllPosts}}

                  {{#if @controller.model.pending_posts}}
                    <div class="pending-posts">
                      {{#each @controller.model.pending_posts as |pending|}}
                        <div
                          class="reviewable-item"
                          data-reviewable-id={{pending.id}}
                        >
                          <div class="reviewable-meta-data">
                            <span class="reviewable-type">
                              {{i18n "review.awaiting_approval"}}
                            </span>
                            <span class="created-at">
                              {{dAgeWithTooltip pending.created_at}}
                            </span>
                          </div>
                          <div class="post-contents-wrapper">
                            <ReviewableCreatedBy
                              @user={{@controller.currentUser}}
                            />
                            <div class="post-contents">
                              <ReviewableCreatedByName
                                @user={{@controller.currentUser}}
                              />
                              <div class="post-body">
                                <DCookText @rawText={{pending.raw}} />
                              </div>
                            </div>
                          </div>
                          <div class="reviewable-actions">
                            <PluginOutlet
                              @name="topic-additional-reviewable-actions"
                              @outletArgs={{lazyHash pending=pending}}
                            />
                            <DButton
                              class="btn-danger"
                              @action={{fn @controller.deletePending pending}}
                              @icon="trash-can"
                              @label="review.delete"
                            />
                          </div>
                        </div>
                      {{/each}}
                    </div>
                  {{/if}}

                  {{#if @controller.model.queued_posts_count}}
                    <div class="has-pending-posts">
                      <div>
                        {{trustHTML
                          (i18n
                            "review.topic_has_pending"
                            count=@controller.model.queued_posts_count
                          )
                        }}
                      </div>

                      <LinkTo
                        @query={{hash
                          topic_id=@controller.model.id
                          type="ReviewableQueuedPost"
                          status="pending"
                        }}
                        @route="review"
                      >
                        {{i18n "review.view_pending"}}
                      </LinkTo>
                    </div>
                  {{/if}}

                  <SlowModeInfo
                    @topic={{@controller.model}}
                    @user={{@controller.currentUser}}
                  />

                  <TopicTimerInfo
                    @basedOnLastPost={{@controller.model.topic_timer.based_on_last_post}}
                    @categoryId={{@controller.model.topic_timer.category_id}}
                    @durationMinutes={{@controller.model.topic_timer.duration_minutes}}
                    @executeAt={{@controller.model.topic_timer.execute_at}}
                    @removeTopicTimer={{fn
                      @controller.removeTopicTimer
                      @controller.model.topic_timer.status_type
                      "topic_timer"
                    }}
                    @showTopicTimerModal={{routeAction "showTopicTimerModal"}}
                    @statusType={{@controller.model.topic_timer.status_type}}
                    @statusUpdate={{@controller.model.topic_status_update}}
                    @topicClosed={{@controller.model.closed}}
                  />

                  {{#if @controller.showSelectedPostsAtBottom}}
                    <div
                      class="selected-posts
                        {{unless @controller.multiSelect 'hidden'}}
                        {{if @controller.showSelectedPostsAtBottom 'hidden'}}"
                    >
                      <SelectedPosts
                        @canChangeOwner={{@controller.canChangeOwner}}
                        @canDeleteSelected={{@controller.canDeleteSelected}}
                        @canDeselectAll={{@controller.canDeselectAll}}
                        @canMergePosts={{@controller.canMergePosts}}
                        @canMergeTopic={{@controller.canMergeTopic}}
                        @canSelectAll={{@controller.canSelectAll}}
                        @deleteSelected={{@controller.deleteSelected}}
                        @deselectAll={{@controller.deselectAll}}
                        @mergePosts={{@controller.mergePosts}}
                        @selectAll={{@controller.selectAll}}
                        @selectedPostsCount={{@controller.selectedPostsCount}}
                        @toggleMultiSelect={{@controller.toggleMultiSelect}}
                      />
                    </div>
                  {{/if}}

                {{/if}}
              </DConditionalLoadingSpinner>

              <PluginOutlet
                @connectorTagName="div"
                @name="topic-area-bottom"
                @outletArgs={{lazyHash model=@controller.model}}
              />
            </section>
          </div>

        </div>
        {{#if @controller.loadedAllPosts}}
          {{#if @controller.session.showSignupCta}}
            {{! replace "Log In to Reply" with the infobox }}
            <SignupCta />
          {{else}}
            {{#if @controller.currentUser}}
              <span>
                <PluginOutlet
                  @connectorTagName="div"
                  @name="topic-above-footer-buttons"
                  @outletArgs={{lazyHash model=@controller.model}}
                />
              </span>

              {{#if @controller.showTopicFooterButtons}}
                <TopicFooterButtons
                  @convertToPrivateMessage={{@controller.convertToPrivateMessage}}
                  @convertToPublicTopic={{@controller.convertToPublicTopic}}
                  @deferTopic={{@controller.deferTopic}}
                  @deleteTopic={{@controller.deleteTopic}}
                  @editFirstPost={{@controller.editFirstPost}}
                  @recoverTopic={{@controller.recoverTopic}}
                  @replyToPost={{@controller.replyToPost}}
                  @resetBumpDate={{@controller.resetBumpDate}}
                  @showChangeTimestamp={{routeAction "showChangeTimestamp"}}
                  @showFeatureTopic={{routeAction "showFeatureTopic"}}
                  @showFlagTopic={{routeAction "showFlagTopic"}}
                  @showTopicSlowModeUpdate={{routeAction
                    "showTopicSlowModeUpdate"
                  }}
                  @showTopicTimerModal={{routeAction "showTopicTimerModal"}}
                  @toggleArchived={{@controller.toggleArchived}}
                  @toggleArchiveMessage={{@controller.toggleArchiveMessage}}
                  @toggleBookmark={{@controller.toggleBookmark}}
                  @toggleClosed={{@controller.toggleClosed}}
                  @toggleMultiSelect={{@controller.toggleMultiSelect}}
                  @toggleVisibility={{@controller.toggleVisibility}}
                  @topic={{@controller.model}}
                />
              {{/if}}
            {{else}}
              <AnonymousTopicFooterButtons @topic={{@controller.model}} />
            {{/if}}
          {{/if}}

          <br />

          <span>
            <PluginOutlet
              @connectorTagName="div"
              @name="topic-above-suggested"
              @outletArgs={{lazyHash model=@controller.model}}
            />
          </span>

          <MoreTopics @topic={{@controller.model}} />
          <PluginOutlet
            @name="topic-below-suggested"
            @outletArgs={{lazyHash model=@controller.model}}
          />
        {{/if}}
        <EmbedTopicFooter @topic={{@controller.model}} />
        <EmbedModeComposer @topic={{@controller.model}} />
      {{else}}
        <div class="container">
          <DConditionalLoadingSpinner @condition={{@controller.noErrorYet}}>
            {{#if @controller.model.errorHtml}}
              <div class="not-found">{{trustHTML
                  @controller.model.errorHtml
                }}</div>
            {{else}}
              <div class="topic-error">
                <div>{{@controller.model.errorMessage}}</div>
                {{#if @controller.model.noRetry}}
                  {{#unless @controller.currentUser}}
                    <DButton
                      class="btn-primary topic-retry"
                      @action={{routeAction "showLogin"}}
                      @icon="user"
                      @label="log_in"
                    />
                  {{/unless}}
                {{else}}
                  <DButton
                    class="btn-primary topic-retry"
                    @action={{@controller.retryLoading}}
                    @icon="arrows-rotate"
                    @label="errors.buttons.again"
                  />
                {{/if}}
              </div>
              <DConditionalLoadingSpinner
                @condition={{@controller.retrying}}
              />
            {{/if}}
          </DConditionalLoadingSpinner>
        </div>
      {{/if}}

      {{#each (array @controller.model) as |topic|}}
        <PostTextSelection
          @buildQuoteMarkdown={{@controller.buildQuoteMarkdown}}
          @editPost={{@controller.editPost}}
          @quoteState={{@controller.quoteState}}
          @selectText={{@controller.selectText}}
          @topic={{topic}}
        />
      {{/each}}
    {{/if}}
  {{/if}}
</DiscourseTopic>
*/
{
  "id": null,
  "block": "[[[41,[51,[30,1,[\"shouldRenderNestedView\"]]],[[[44,[[30,1,[\"model\",\"postStream\"]]],[[[41,[51,[28,[32,0],[[30,2,[\"loaded\"]],[30,2,[\"loadedAllPosts\"]]],null]],[[[1,\"      \"],[1,[32,1]],[1,\"\\n\"]],[]],null]],[2]]]],[]],null],[1,\"\\n\"],[8,[32,2],null,[[\"@enteredAt\",\"@hasScrolled\",\"@multiSelect\",\"@topic\"],[[30,1,[\"enteredAt\"]],[30,1,[\"hasScrolled\"]],[30,1,[\"multiSelect\"]],[30,1,[\"model\"]]]],[[\"default\"],[[[[1,\"\\n  \"],[8,[32,3],null,[[\"@postStream\",\"@topic\"],[[30,1,[\"model\",\"postStream\"]],[30,1,[\"model\"]]]],null],[1,\"\\n\"],[41,[30,1,[\"model\"]],[[[1,\"    \"],[8,[32,4],null,[[\"@category\",\"@tags\"],[[30,1,[\"model\",\"category\"]],[30,1,[\"model\",\"tags\"]]]],null],[1,\"\\n    \"],[8,[32,5],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n    \"],[1,[28,[32,6],[[28,[32,7],[\"archetype-\",[30,1,[\"model\",\"archetype\"]]],null]],null]],[1,\"\\n\"],[41,[30,1,[\"shouldRenderNestedView\"]],[[[44,[[30,1,[\"nestedController\"]]],[[[1,\"        \"],[8,[32,8],null,[[\"@buildQuoteMarkdown\",\"@editPost\",\"@quoteState\",\"@selectText\",\"@topic\"],[[30,3,[\"buildQuoteMarkdown\"]],[30,3,[\"editPost\"]],[30,3,[\"quoteState\"]],[30,3,[\"selectText\"]],[30,1,[\"model\"]]]],null],[1,\"\\n\\n        \"],[10,0],[15,0,[29,[\"selected-posts nested-view__selected-posts\\n            \",[52,[51,[30,3,[\"multiSelect\"]]],\"hidden\"]]]],[12],[1,\"\\n          \"],[8,[32,9],null,[[\"@canChangeOwner\",\"@canDeleteSelected\",\"@canDeselectAll\",\"@canMergePosts\",\"@canMergeTopic\",\"@canSelectAll\",\"@deleteSelected\",\"@deselectAll\",\"@mergePosts\",\"@selectAll\",\"@selectedPostsCount\",\"@toggleMultiSelect\"],[[30,3,[\"canChangeOwner\"]],[30,3,[\"canDeleteSelected\"]],[30,3,[\"canDeselectAll\"]],[30,3,[\"canMergePosts\"]],[30,3,[\"canMergeTopic\"]],[30,3,[\"canSelectAll\"]],[30,3,[\"deleteSelected\"]],[30,3,[\"deselectAll\"]],[30,3,[\"mergePosts\"]],[30,3,[\"selectAll\"]],[30,3,[\"selectedPostsCount\"]],[30,3,[\"toggleMultiSelect\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\\n        \"],[8,[32,10],null,[[\"@ancestorsTruncated\",\"@buffered\",\"@cancelEditingTopic\",\"@canEditTags\",\"@changeNotice\",\"@changePostOwner\",\"@changeSort\",\"@clearScrollAnchor\",\"@collapseReplies\",\"@contextMode\",\"@contextNoAncestors\",\"@deletePost\",\"@editingTopic\",\"@editPost\",\"@effectiveSort\",\"@expansionState\",\"@fetchedChildrenCache\",\"@finishedEditingTopic\",\"@firstRootPage\",\"@grantBadge\",\"@hasMoreRoots\",\"@initialFocusedPath\",\"@loadingMore\",\"@loadingPreviousRoots\",\"@loadMoreRoots\",\"@loadNewRoots\",\"@loadPreviousRoots\",\"@lockPost\",\"@minimumRequiredTags\",\"@multiSelect\",\"@newRootPostCount\",\"@opPost\",\"@permanentlyDeletePost\",\"@pinnedPostIds\",\"@postNumber\",\"@postSelected\",\"@rebakePost\",\"@recoverPost\",\"@replyToPost\",\"@rootNodes\",\"@saveScrollPosition\",\"@scrollAnchor\",\"@selectBelow\",\"@selectReplies\",\"@setFocusedPostNumber\",\"@showActivityLog\",\"@showCategoryChooser\",\"@showFlags\",\"@showHistory\",\"@showPagePublish\",\"@sort\",\"@startEditingTopic\",\"@targetPostNumber\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@topic\",\"@topicCategoryChanged\",\"@topicTagsChanged\",\"@unhidePost\",\"@unlockPost\",\"@viewFullThread\",\"@viewParentContext\"],[[30,3,[\"ancestorsTruncated\"]],[30,3,[\"buffered\"]],[30,3,[\"cancelEditingTopic\"]],[30,3,[\"canEditTags\"]],[30,3,[\"changeNotice\"]],[30,3,[\"changePostOwner\"]],[30,3,[\"changeSort\"]],[30,3,[\"clearScrollAnchor\"]],[30,3,[\"collapseReplies\"]],[30,3,[\"contextMode\"]],[30,3,[\"contextNoAncestors\"]],[30,3,[\"deletePost\"]],[30,3,[\"editingTopic\"]],[30,3,[\"editPost\"]],[30,3,[\"effectiveSort\"]],[30,3,[\"expansionState\"]],[30,3,[\"fetchedChildrenCache\"]],[30,3,[\"finishedEditingTopic\"]],[30,3,[\"firstRootPage\"]],[30,3,[\"grantBadge\"]],[30,3,[\"hasMoreRoots\"]],[30,3,[\"initialFocusedPath\"]],[30,3,[\"loadingMore\"]],[30,3,[\"loadingPreviousRoots\"]],[30,3,[\"loadMoreRoots\"]],[30,3,[\"loadNewRoots\"]],[30,3,[\"loadPreviousRoots\"]],[30,3,[\"lockPost\"]],[30,3,[\"minimumRequiredTags\"]],[30,3,[\"multiSelect\"]],[30,3,[\"newRootPostCount\"]],[30,3,[\"opPost\"]],[30,3,[\"permanentlyDeletePost\"]],[30,3,[\"pinnedPostIds\"]],[30,3,[\"postNumber\"]],[30,3,[\"postSelected\"]],[30,3,[\"rebakePost\"]],[30,3,[\"recoverPost\"]],[30,3,[\"replyToPost\"]],[30,3,[\"rootNodes\"]],[30,3,[\"saveScrollPosition\"]],[30,3,[\"scrollAnchor\"]],[30,3,[\"selectBelow\"]],[30,3,[\"selectReplies\"]],[30,3,[\"setFocusedPostNumber\"]],[30,3,[\"showActivityLog\"]],[30,3,[\"showCategoryChooser\"]],[30,3,[\"showFlags\"]],[30,3,[\"showHistory\"]],[30,3,[\"showPagePublish\"]],[30,3,[\"sort\"]],[30,3,[\"startEditingTopic\"]],[30,3,[\"targetPostNumber\"]],[30,3,[\"togglePostSelection\"]],[30,3,[\"togglePostType\"]],[30,3,[\"toggleWiki\"]],[30,1,[\"model\"]],[30,3,[\"topicCategoryChanged\"]],[30,3,[\"topicTagsChanged\"]],[30,3,[\"unhidePost\"]],[30,3,[\"unlockPost\"]],[30,3,[\"viewFullThread\"]],[30,3,[\"viewParentContext\"]]]],null],[1,\"\\n\"]],[3]]]],[]],[[[1,\"\\n\"],[41,[51,[30,1,[\"shouldHideScrollableContentAbove\"]]],[[[1,\"        \"],[10,0],[14,0,\"container\"],[12],[1,\"\\n          \"],[8,[32,11],null,[[\"@hide\",\"@overlay\"],[[30,1,[\"model\",\"errorLoading\"]],[30,1,[\"hasScrolled\"]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[51,[30,1,[\"shouldHideScrollableContentAbove\"]]],[[[41,[30,1,[\"showSharedDraftControls\"]],[[[1,\"          \"],[8,[32,12],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n        \"],[10,1],[12],[1,\"\\n          \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-post-stream\",[28,[32,14],null,[[\"model\",\"editFirstPost\"],[[30,1,[\"model\"]],[30,1,[\"editFirstPost\"]]]]]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,1,[\"model\",\"postStream\",\"loaded\"]],[[[41,[30,1,[\"model\",\"postStream\",\"firstPostPresent\"]],[[[1,\"          \"],[8,[32,15],null,[[\"@cancelled\",\"@model\",\"@save\"],[[30,1,[\"cancelEditingTopic\"]],[30,1,[\"model\"]],[30,1,[\"finishedEditingTopic\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"editingTopic\"]],[[[1,\"              \"],[10,0],[14,0,\"edit-topic-title\"],[12],[1,\"\\n                \"],[8,[32,16],null,[[\"@shouldShow\"],[[30,1,[\"model\",\"isPrivateMessage\"]]]],null],[1,\"\\n\\n                \"],[8,[32,17],null,[[\"@buffered\",\"@bufferedTitle\",\"@isEditingLocalization\",\"@model\",\"@translationLocale\",\"@translationTitle\"],[[30,1,[\"buffered\"]],[30,1,[\"buffered\",\"title\"]],[30,1,[\"editingTopicLocalization\"]],[30,1,[\"model\"]],[30,1,[\"translationLocale\"]],[30,1,[\"translationTitle\"]]]],null],[1,\"\\n\\n                \"],[8,[32,18],null,[[\"@buffered\",\"@canEditTags\",\"@minimumRequiredTags\",\"@model\",\"@onCancel\",\"@onSave\",\"@showCategoryChooser\",\"@topicCategoryChanged\",\"@topicTagsChanged\"],[[30,1,[\"buffered\"]],[30,1,[\"canEditTags\"]],[30,1,[\"minimumRequiredTags\"]],[30,1,[\"model\"]],[30,1,[\"cancelEditingTopic\"]],[30,1,[\"finishedEditingTopic\"]],[30,1,[\"showCategoryChooser\"]],[30,1,[\"topicCategoryChanged\"]],[30,1,[\"topicTagsChanged\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"canRemoveTopicFeaturedLink\"]],[[[1,\"                    \"],[11,3],[24,0,\"remove-featured-link\"],[24,6,\"\"],[16,\"title\",[28,[32,19],[\"composer.remove_featured_link\"],null]],[4,[32,20],[\"click\",[30,1,[\"removeFeaturedLink\"]]],null],[12],[1,\"\\n                      \"],[1,[28,[32,21],[\"circle-xmark\"],null]],[1,\"\\n                      \"],[1,[30,1,[\"featuredLinkDomain\"]]],[1,\"\\n                    \"],[13],[1,\"\\n\"]],[]],null],[1,\"                \"]],[]]]]],[1,\"\\n              \"],[13],[1,\"\\n\\n\"]],[]],[[[1,\"              \"],[10,\"h1\"],[15,\"aria-hidden\",[28,[32,22],[[30,1,[\"titleIsVisibleOnHeader\"]]],null]],[15,\"data-topic-id\",[30,1,[\"model\",\"id\"]]],[12],[1,\"\\n\"],[41,[51,[30,1,[\"model\",\"is_warning\"]]],[[[41,[30,1,[\"canSendPms\"]],[[[1,\"                    \"],[8,[32,16],null,[[\"@ariaLabel\",\"@href\",\"@shouldShow\",\"@title\"],[\"user.messages.inbox\",[30,1,[\"pmPath\"]],[30,1,[\"model\",\"isPrivateMessage\"]],\"topic_statuses.personal_message.title\"]],null],[1,\"\\n\"]],[]],[[[1,\"                    \"],[8,[32,16],null,[[\"@shouldShow\"],[[30,1,[\"model\",\"isPrivateMessage\"]]]],null],[1,\"\\n\"]],[]]]],[]],null],[1,\"\\n\"],[41,[30,1,[\"model\",\"details\",\"loaded\"]],[[[1,\"                  \"],[8,[32,23],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n                  \"],[11,3],[24,0,\"fancy-title\"],[16,6,[30,1,[\"model\",\"url\"]]],[4,[32,20],[\"click\",[30,1,[\"handleTitleClick\"]]],null],[12],[1,\"\\n                    \"],[1,[28,[32,24],[[30,1,[\"model\",\"fancyTitle\"]]],null]],[41,[30,1,[\"model\",\"details\",\"can_edit\"]],[[[10,1],[14,0,\"edit-topic__wrapper\"],[12],[1,\"\\n                        \"],[1,[28,[32,21],[\"pencil\"],[[\"class\"],[\"edit-topic\"]]]],[1,\"\\n                      \"],[13]],[]],null],[1,\"                  \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n                \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"topic-title-suffix\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n              \"],[13],[1,\"\\n\\n              \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"topic-category-wrapper\",[28,[32,14],null,[[\"topic\"],[[30,1,[\"model\"]]]]]]],[[\"default\"],[[[[1,\"\\n                \"],[8,[32,25],[[24,0,\"topic-category\"]],[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n              \"]],[]]]]],[1,\"\\n\\n\"]],[]]],[1,\"          \"]],[]]]]],[1,\"\\n\\n\"],[41,[30,1,[\"model\",\"publishedPage\"]],[[[1,\"            \"],[10,0],[14,0,\"published-page-notice\"],[12],[1,\"\\n              \"],[10,0],[14,0,\"details\"],[12],[1,\"\\n\"],[41,[30,1,[\"model\",\"publishedPage\",\"public\"]],[[[1,\"                  \"],[10,1],[14,0,\"is-public\"],[12],[1,[28,[32,19],[\"topic.publish_page.public\"],null]],[13],[1,\"\\n\"]],[]],null],[1,\"                \"],[1,[28,[32,19],[\"topic.publish_page.topic_published\"],null]],[1,\"\\n                \"],[10,0],[12],[1,\"\\n                  \"],[10,3],[15,6,[30,1,[\"model\",\"publishedPage\",\"url\"]]],[14,\"rel\",\"noopener noreferrer\"],[14,\"target\",\"_blank\"],[12],[1,[30,1,[\"model\",\"publishedPage\",\"url\"]]],[13],[1,\"\\n                \"],[13],[1,\"\\n              \"],[13],[1,\"\\n              \"],[10,0],[14,0,\"controls\"],[12],[1,\"\\n                \"],[8,[32,26],null,[[\"@action\",\"@icon\",\"@label\"],[[28,[32,27],[\"showPagePublish\"],null],\"file\",\"topic.publish_page.publishing_settings\"]],null],[1,\"\\n              \"],[13],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"]],[]],null],[1,\"\\n        \"],[10,0],[14,0,\"container posts\"],[12],[1,\"\\n          \"],[10,0],[15,0,[29,[\"selected-posts \",[52,[51,[30,1,[\"multiSelect\"]]],\"hidden\"]]]],[12],[1,\"\\n            \"],[8,[32,9],null,[[\"@canChangeOwner\",\"@canDeleteSelected\",\"@canDeselectAll\",\"@canMergePosts\",\"@canMergeTopic\",\"@canSelectAll\",\"@deleteSelected\",\"@deselectAll\",\"@mergePosts\",\"@selectAll\",\"@selectedPostsCount\",\"@toggleMultiSelect\"],[[30,1,[\"canChangeOwner\"]],[30,1,[\"canDeleteSelected\"]],[30,1,[\"canDeselectAll\"]],[30,1,[\"canMergePosts\"]],[30,1,[\"canMergeTopic\"]],[30,1,[\"canSelectAll\"]],[30,1,[\"deleteSelected\"]],[30,1,[\"deselectAll\"]],[30,1,[\"mergePosts\"]],[30,1,[\"selectAll\"]],[30,1,[\"selectedPostsCount\"]],[30,1,[\"toggleMultiSelect\"]]]],null],[1,\"\\n          \"],[13],[1,\"\\n\\n\"],[41,[28,[32,0],[[30,1,[\"showBottomTopicMap\"]],[30,1,[\"loadedAllPosts\"]]],null],[[[1,\"            \"],[10,0],[14,0,\"topic-map --bottom\"],[12],[1,\"\\n              \"],[8,[32,28],null,[[\"@model\",\"@postStream\",\"@removeAllowedGroup\",\"@removeAllowedUser\",\"@showInvite\",\"@showPMMap\",\"@topicDetails\"],[[30,1,[\"model\"]],[30,1,[\"model\",\"postStream\"]],[30,1,[\"removeAllowedGroup\"]],[30,1,[\"removeAllowedUser\"]],[28,[32,27],[\"showInvite\"],null],[28,[32,29],[[30,1,[\"model\",\"archetype\"]],\"private_message\"],null],[30,1,[\"model\",\"details\"]]]],null],[1,\"\\n            \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n          \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\"],[\"div\",\"above-timeline\"]],null],[1,\"\\n\\n          \"],[8,[32,30],[[24,0,\"topic-navigation\"]],[[\"@jumpToDate\",\"@jumpToIndex\",\"@topic\"],[[30,1,[\"jumpToDate\"]],[30,1,[\"jumpToIndex\"]],[30,1,[\"model\"]]]],[[\"default\"],[[[[1,\"\\n            \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-navigation\",[28,[32,14],null,[[\"topic\",\"renderTimeline\",\"topicProgressExpanded\"],[[30,1,[\"model\"]],[30,4,[\"renderTimeline\"]],[30,4,[\"topicProgressExpanded\"]]]]]]],null],[1,\"\\n\\n\"],[41,[30,4,[\"renderTimeline\"]],[[[1,\"              \"],[8,[32,31],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@enteredIndex\",\"@fullscreen\",\"@info\",\"@jumpBottom\",\"@jumpEnd\",\"@jumpToIndex\",\"@jumpTop\",\"@jumpToPostPrompt\",\"@model\",\"@prevEvent\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@showTopReplies\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\"],[[30,1,[\"convertToPrivateMessage\"]],[30,1,[\"convertToPublicTopic\"]],[30,1,[\"deleteTopic\"]],[30,1,[\"enteredIndex\"]],[30,4,[\"topicProgressExpanded\"]],[30,4],[30,1,[\"jumpBottom\"]],[30,1,[\"jumpEnd\"]],[30,1,[\"jumpToIndex\"]],[30,1,[\"jumpTop\"]],[30,1,[\"jumpToPostPrompt\"]],[30,1,[\"model\"]],[30,4,[\"prevEvent\"]],[30,1,[\"recoverTopic\"]],[30,1,[\"replyToPost\"]],[30,1,[\"resetBumpDate\"]],[28,[32,27],[\"showChangeTimestamp\"],null],[28,[32,27],[\"showFeatureTopic\"],null],[28,[32,27],[\"showTopicSlowModeUpdate\"],null],[28,[32,27],[\"showTopicTimerModal\"],null],[30,1,[\"showTopReplies\"]],[30,1,[\"toggleArchived\"]],[30,1,[\"toggleClosed\"]],[30,1,[\"toggleMultiSelect\"]],[30,1,[\"toggleVisibility\"]]]],null],[1,\"\\n\"]],[]],[[[1,\"              \"],[8,[32,32],null,[[\"@jumpToPost\",\"@onExpandToggle\",\"@prevEvent\",\"@topic\"],[[30,1,[\"jumpToPost\"]],[30,5],[30,4,[\"prevEvent\"]],[30,1,[\"model\"]]]],[[\"default\"],[[[[1,\"\\n                \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"before-topic-progress\",[28,[32,14],null,[[\"model\",\"jumpToPost\"],[[30,1,[\"model\"]],[30,1,[\"jumpToPost\"]]]]]]],null],[1,\"\\n                \"],[8,[32,33],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@recoverTopic\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\",\"@topic\"],[[30,1,[\"convertToPrivateMessage\"]],[30,1,[\"convertToPublicTopic\"]],[30,1,[\"deleteTopic\"]],[30,1,[\"recoverTopic\"]],[30,1,[\"resetBumpDate\"]],[28,[32,27],[\"showChangeTimestamp\"],null],[28,[32,27],[\"showFeatureTopic\"],null],[28,[32,27],[\"showTopicSlowModeUpdate\"],null],[28,[32,27],[\"showTopicTimerModal\"],null],[30,1,[\"toggleArchived\"]],[30,1,[\"toggleClosed\"]],[30,1,[\"toggleMultiSelect\"]],[30,1,[\"toggleVisibility\"]],[30,1,[\"model\"]]]],null],[1,\"\\n\"],[41,[30,1,[\"model\",\"has_localized_content\"]],[[[1,\"                  \"],[8,[32,34],null,null,null],[1,\"\\n\"]],[]],null],[1,\"              \"]],[]]]]],[1,\"\\n\"]],[]]],[1,\"\\n            \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-navigation-bottom\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n          \"]],[4,5]]]]],[1,\"\\n\\n          \"],[10,0],[14,0,\"row\"],[12],[1,\"\\n            \"],[10,\"section\"],[14,0,\"topic-area\"],[15,\"data-topic-id\",[30,1,[\"model\",\"id\"]]],[14,1,\"topic\"],[12],[1,\"\\n              \"],[10,0],[14,0,\"posts-wrapper\"],[12],[1,\"\\n                \"],[10,1],[12],[1,\"\\n                  \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-posts\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n                \"],[13],[1,\"\\n\\n\"],[41,[30,1,[\"model\",\"postStream\",\"firstPostNotLoaded\"]],[[[1,\"                  \"],[1,[28,[32,35],[\"above\"],null]],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[51,[30,1,[\"model\",\"postStream\",\"loadingFilter\"]]],[[[1,\"                  \"],[8,[32,36],null,[[\"@bottomVisibleChanged\",\"@cancelFilter\",\"@canCreatePost\",\"@changeNotice\",\"@changePostOwner\",\"@currentPostChanged\",\"@currentPostScrolled\",\"@deletePost\",\"@editPost\",\"@expandHidden\",\"@fillGapAfter\",\"@fillGapBefore\",\"@filteredPostsCount\",\"@filteringRepliesToPostNumber\",\"@gaps\",\"@grantBadge\",\"@highestPostNumber\",\"@lastReadPostNumber\",\"@lockPost\",\"@multiSelect\",\"@permanentlyDeletePost\",\"@postSelected\",\"@postStream\",\"@rebakePost\",\"@recoverPost\",\"@removeAllowedGroup\",\"@removeAllowedUser\",\"@replyToPost\",\"@selectBelow\",\"@selectedPostsCount\",\"@selectedQuery\",\"@selectReplies\",\"@showFlags\",\"@showHistory\",\"@showInvite\",\"@showLogin\",\"@showPagePublish\",\"@showRawEmail\",\"@showReadIndicator\",\"@showTopReplies\",\"@streamFilters\",\"@toggleBookmark\",\"@togglePostSelection\",\"@togglePostType\",\"@toggleWiki\",\"@topic\",\"@topicPageQueryParams\",\"@topVisibleChanged\",\"@unhidePost\",\"@unlockPost\",\"@updateTopicPageQueryParams\"],[[30,1,[\"bottomVisibleChanged\"]],[30,1,[\"cancelFilter\"]],[30,1,[\"model\",\"details\",\"can_create_post\"]],[30,1,[\"changeNotice\"]],[30,1,[\"changePostOwner\"]],[30,1,[\"currentPostChanged\"]],[30,1,[\"currentPostScrolled\"]],[30,1,[\"deletePost\"]],[30,1,[\"editPost\"]],[30,1,[\"expandHidden\"]],[30,1,[\"fillGapAfter\"]],[30,1,[\"fillGapBefore\"]],[30,1,[\"model\",\"postStream\",\"filteredPostsCount\"]],[30,1,[\"replies_to_post_number\"]],[30,1,[\"model\",\"postStream\",\"gaps\"]],[30,1,[\"grantBadge\"]],[30,1,[\"highestPostNumber\"]],[30,1,[\"userLastReadPostNumber\"]],[30,1,[\"lockPost\"]],[30,1,[\"multiSelect\"]],[30,1,[\"permanentlyDeletePost\"]],[30,1,[\"postSelected\"]],[30,1,[\"model\",\"postStream\"]],[30,1,[\"rebakePost\"]],[30,1,[\"recoverPost\"]],[30,1,[\"removeAllowedGroup\"]],[30,1,[\"removeAllowedUser\"]],[30,1,[\"replyToPost\"]],[30,1,[\"selectBelow\"]],[30,1,[\"selectedPostsCount\"]],[30,1,[\"selectedQuery\"]],[30,1,[\"selectReplies\"]],[30,1,[\"showPostFlags\"]],[28,[32,27],[\"showHistory\"],null],[28,[32,27],[\"showInvite\"],null],[28,[32,27],[\"showLogin\"],null],[28,[32,27],[\"showPagePublish\"],null],[28,[32,27],[\"showRawEmail\"],null],[30,1,[\"model\",\"show_read_indicator\"]],[30,1,[\"showTopReplies\"]],[30,1,[\"model\",\"postStream\",\"streamFilters\"]],[30,1,[\"toggleBookmark\"]],[30,1,[\"togglePostSelection\"]],[30,1,[\"togglePostType\"]],[30,1,[\"toggleWiki\"]],[30,1,[\"model\"]],[30,1,[\"topicPageQueryParams\"]],[30,1,[\"topVisibleChanged\"]],[30,1,[\"unhidePost\"]],[30,1,[\"unlockPost\"]],[30,1,[\"updateTopicPageQueryParams\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,1,[\"model\",\"postStream\",\"lastPostNotLoaded\"]],[[[1,\"                  \"],[1,[28,[32,35],[\"below\"],null]],[1,\"\\n\"]],[]],null],[1,\"              \"],[13],[1,\"\\n              \"],[10,0],[14,1,\"topic-bottom\"],[12],[13],[1,\"\\n\\n              \"],[8,[32,37],null,[[\"@condition\"],[[30,1,[\"model\",\"postStream\",\"loadingFilter\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"loadedAllPosts\"]],[[[1,\"\\n\"],[41,[30,1,[\"model\",\"pending_posts\"]],[[[1,\"                    \"],[10,0],[14,0,\"pending-posts\"],[12],[1,\"\\n\"],[42,[28,[31,4],[[28,[31,4],[[30,1,[\"model\",\"pending_posts\"]]],null]],null],null,[[[1,\"                        \"],[10,0],[14,0,\"reviewable-item\"],[15,\"data-reviewable-id\",[30,6,[\"id\"]]],[12],[1,\"\\n                          \"],[10,0],[14,0,\"reviewable-meta-data\"],[12],[1,\"\\n                            \"],[10,1],[14,0,\"reviewable-type\"],[12],[1,\"\\n                              \"],[1,[28,[32,19],[\"review.awaiting_approval\"],null]],[1,\"\\n                            \"],[13],[1,\"\\n                            \"],[10,1],[14,0,\"created-at\"],[12],[1,\"\\n                              \"],[1,[28,[32,38],[[30,6,[\"created_at\"]]],null]],[1,\"\\n                            \"],[13],[1,\"\\n                          \"],[13],[1,\"\\n                          \"],[10,0],[14,0,\"post-contents-wrapper\"],[12],[1,\"\\n                            \"],[8,[32,39],null,[[\"@user\"],[[30,1,[\"currentUser\"]]]],null],[1,\"\\n                            \"],[10,0],[14,0,\"post-contents\"],[12],[1,\"\\n                              \"],[8,[32,40],null,[[\"@user\"],[[30,1,[\"currentUser\"]]]],null],[1,\"\\n                              \"],[10,0],[14,0,\"post-body\"],[12],[1,\"\\n                                \"],[8,[32,41],null,[[\"@rawText\"],[[30,6,[\"raw\"]]]],null],[1,\"\\n                              \"],[13],[1,\"\\n                            \"],[13],[1,\"\\n                          \"],[13],[1,\"\\n                          \"],[10,0],[14,0,\"reviewable-actions\"],[12],[1,\"\\n                            \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"topic-additional-reviewable-actions\",[28,[32,14],null,[[\"pending\"],[[30,6]]]]]],null],[1,\"\\n                            \"],[8,[32,26],[[24,0,\"btn-danger\"]],[[\"@action\",\"@icon\",\"@label\"],[[28,[32,42],[[30,1,[\"deletePending\"]],[30,6]],null],\"trash-can\",\"review.delete\"]],null],[1,\"\\n                          \"],[13],[1,\"\\n                        \"],[13],[1,\"\\n\"]],[6]],null],[1,\"                    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"],[41,[30,1,[\"model\",\"queued_posts_count\"]],[[[1,\"                    \"],[10,0],[14,0,\"has-pending-posts\"],[12],[1,\"\\n                      \"],[10,0],[12],[1,\"\\n                        \"],[1,[28,[32,24],[[28,[32,19],[\"review.topic_has_pending\"],[[\"count\"],[[30,1,[\"model\",\"queued_posts_count\"]]]]]],null]],[1,\"\\n                      \"],[13],[1,\"\\n\\n                      \"],[8,[32,43],null,[[\"@query\",\"@route\"],[[28,[32,44],null,[[\"topic_id\",\"type\",\"status\"],[[30,1,[\"model\",\"id\"]],\"ReviewableQueuedPost\",\"pending\"]]],\"review\"]],[[\"default\"],[[[[1,\"\\n                        \"],[1,[28,[32,19],[\"review.view_pending\"],null]],[1,\"\\n                      \"]],[]]]]],[1,\"\\n                    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n                  \"],[8,[32,45],null,[[\"@topic\",\"@user\"],[[30,1,[\"model\"]],[30,1,[\"currentUser\"]]]],null],[1,\"\\n\\n                  \"],[8,[32,46],null,[[\"@basedOnLastPost\",\"@categoryId\",\"@durationMinutes\",\"@executeAt\",\"@removeTopicTimer\",\"@showTopicTimerModal\",\"@statusType\",\"@statusUpdate\",\"@topicClosed\"],[[30,1,[\"model\",\"topic_timer\",\"based_on_last_post\"]],[30,1,[\"model\",\"topic_timer\",\"category_id\"]],[30,1,[\"model\",\"topic_timer\",\"duration_minutes\"]],[30,1,[\"model\",\"topic_timer\",\"execute_at\"]],[28,[32,42],[[30,1,[\"removeTopicTimer\"]],[30,1,[\"model\",\"topic_timer\",\"status_type\"]],\"topic_timer\"],null],[28,[32,27],[\"showTopicTimerModal\"],null],[30,1,[\"model\",\"topic_timer\",\"status_type\"]],[30,1,[\"model\",\"topic_status_update\"]],[30,1,[\"model\",\"closed\"]]]],null],[1,\"\\n\\n\"],[41,[30,1,[\"showSelectedPostsAtBottom\"]],[[[1,\"                    \"],[10,0],[15,0,[29,[\"selected-posts\\n                        \",[52,[51,[30,1,[\"multiSelect\"]]],\"hidden\"],\"\\n                        \",[52,[30,1,[\"showSelectedPostsAtBottom\"]],\"hidden\"]]]],[12],[1,\"\\n                      \"],[8,[32,9],null,[[\"@canChangeOwner\",\"@canDeleteSelected\",\"@canDeselectAll\",\"@canMergePosts\",\"@canMergeTopic\",\"@canSelectAll\",\"@deleteSelected\",\"@deselectAll\",\"@mergePosts\",\"@selectAll\",\"@selectedPostsCount\",\"@toggleMultiSelect\"],[[30,1,[\"canChangeOwner\"]],[30,1,[\"canDeleteSelected\"]],[30,1,[\"canDeselectAll\"]],[30,1,[\"canMergePosts\"]],[30,1,[\"canMergeTopic\"]],[30,1,[\"canSelectAll\"]],[30,1,[\"deleteSelected\"]],[30,1,[\"deselectAll\"]],[30,1,[\"mergePosts\"]],[30,1,[\"selectAll\"]],[30,1,[\"selectedPostsCount\"]],[30,1,[\"toggleMultiSelect\"]]]],null],[1,\"\\n                    \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n\"]],[]],null],[1,\"              \"]],[]]]]],[1,\"\\n\\n              \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-area-bottom\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n            \"],[13],[1,\"\\n          \"],[13],[1,\"\\n\\n        \"],[13],[1,\"\\n\"],[41,[30,1,[\"loadedAllPosts\"]],[[[41,[30,1,[\"session\",\"showSignupCta\"]],[[[1,\"            \"],[8,[32,47],null,null,null],[1,\"\\n\"]],[]],[[[41,[30,1,[\"currentUser\"]],[[[1,\"              \"],[10,1],[12],[1,\"\\n                \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-footer-buttons\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n              \"],[13],[1,\"\\n\\n\"],[41,[30,1,[\"showTopicFooterButtons\"]],[[[1,\"                \"],[8,[32,48],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deferTopic\",\"@deleteTopic\",\"@editFirstPost\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showFlagTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleArchiveMessage\",\"@toggleBookmark\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\",\"@topic\"],[[30,1,[\"convertToPrivateMessage\"]],[30,1,[\"convertToPublicTopic\"]],[30,1,[\"deferTopic\"]],[30,1,[\"deleteTopic\"]],[30,1,[\"editFirstPost\"]],[30,1,[\"recoverTopic\"]],[30,1,[\"replyToPost\"]],[30,1,[\"resetBumpDate\"]],[28,[32,27],[\"showChangeTimestamp\"],null],[28,[32,27],[\"showFeatureTopic\"],null],[28,[32,27],[\"showFlagTopic\"],null],[28,[32,27],[\"showTopicSlowModeUpdate\"],null],[28,[32,27],[\"showTopicTimerModal\"],null],[30,1,[\"toggleArchived\"]],[30,1,[\"toggleArchiveMessage\"]],[30,1,[\"toggleBookmark\"]],[30,1,[\"toggleClosed\"]],[30,1,[\"toggleMultiSelect\"]],[30,1,[\"toggleVisibility\"]],[30,1,[\"model\"]]]],null],[1,\"\\n\"]],[]],null]],[]],[[[1,\"              \"],[8,[32,49],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n\"]],[]]]],[]]],[1,\"\\n          \"],[10,\"br\"],[12],[13],[1,\"\\n\\n          \"],[10,1],[12],[1,\"\\n            \"],[8,[32,13],null,[[\"@connectorTagName\",\"@name\",\"@outletArgs\"],[\"div\",\"topic-above-suggested\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n          \"],[13],[1,\"\\n\\n          \"],[8,[32,50],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n          \"],[8,[32,13],null,[[\"@name\",\"@outletArgs\"],[\"topic-below-suggested\",[28,[32,14],null,[[\"model\"],[[30,1,[\"model\"]]]]]]],null],[1,\"\\n\"]],[]],null],[1,\"        \"],[8,[32,51],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n        \"],[8,[32,52],null,[[\"@topic\"],[[30,1,[\"model\"]]]],null],[1,\"\\n\"]],[]],[[[1,\"        \"],[10,0],[14,0,\"container\"],[12],[1,\"\\n          \"],[8,[32,37],null,[[\"@condition\"],[[30,1,[\"noErrorYet\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,1,[\"model\",\"errorHtml\"]],[[[1,\"              \"],[10,0],[14,0,\"not-found\"],[12],[1,[28,[32,24],[[30,1,[\"model\",\"errorHtml\"]]],null]],[13],[1,\"\\n\"]],[]],[[[1,\"              \"],[10,0],[14,0,\"topic-error\"],[12],[1,\"\\n                \"],[10,0],[12],[1,[30,1,[\"model\",\"errorMessage\"]]],[13],[1,\"\\n\"],[41,[30,1,[\"model\",\"noRetry\"]],[[[41,[51,[30,1,[\"currentUser\"]]],[[[1,\"                    \"],[8,[32,26],[[24,0,\"btn-primary topic-retry\"]],[[\"@action\",\"@icon\",\"@label\"],[[28,[32,27],[\"showLogin\"],null],\"user\",\"log_in\"]],null],[1,\"\\n\"]],[]],null]],[]],[[[1,\"                  \"],[8,[32,26],[[24,0,\"btn-primary topic-retry\"]],[[\"@action\",\"@icon\",\"@label\"],[[30,1,[\"retryLoading\"]],\"arrows-rotate\",\"errors.buttons.again\"]],null],[1,\"\\n\"]],[]]],[1,\"              \"],[13],[1,\"\\n              \"],[8,[32,37],null,[[\"@condition\"],[[30,1,[\"retrying\"]]]],null],[1,\"\\n\"]],[]]],[1,\"          \"]],[]]]]],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]]],[1,\"\\n\"],[42,[28,[31,4],[[28,[31,4],[[28,[32,53],[[30,1,[\"model\"]]],null]],null]],null],null,[[[1,\"        \"],[8,[32,8],null,[[\"@buildQuoteMarkdown\",\"@editPost\",\"@quoteState\",\"@selectText\",\"@topic\"],[[30,1,[\"buildQuoteMarkdown\"]],[30,1,[\"editPost\"]],[30,1,[\"quoteState\"]],[30,1,[\"selectText\"]],[30,7]]],null],[1,\"\\n\"]],[7]],null]],[]]]],[]],null]],[]]]]]],[\"@controller\",\"postStream\",\"nested\",\"info\",\"toggleProgressExpansion\",\"pending\",\"topic\"],[\"unless\",\"let\",\"if\",\"each\",\"-track-array\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    and,
    hideApplicationFooter,
    DiscourseTopic,
    TopicSkipLinks,
    AddCategoryTagClasses,
    AddTopicStatusClasses,
    bodyClass,
    concat,
    PostTextSelection,
    SelectedPosts,
    Nested,
    DiscourseBanner,
    SharedDraftControls,
    PluginOutlet,
    lazyHash,
    TopicTitle,
    PrivateMessageGlyph,
    TopicTitleEditor,
    TopicMetadata,
    i18n,
    on,
    dIcon,
    booleanString,
    TopicStatus,
    trustHTML,
    TopicCategory,
    DButton,
    routeAction,
    TopicMap,
    eq,
    TopicNavigation,
    TopicTimeline,
    TopicProgress,
    TopicAdminMenu,
    TopicContentLanguagePreferences,
    hideScrollableContent,
    PostStream,
    DConditionalLoadingSpinner,
    dAgeWithTooltip,
    ReviewableCreatedBy,
    ReviewableCreatedByName,
    DCookText,
    fn,
    LinkTo,
    hash,
    SlowModeInfo,
    TopicTimerInfo,
    SignupCta,
    TopicFooterButtons,
    AnonymousTopicFooterButtons,
    MoreTopics,
    EmbedTopicFooter,
    EmbedModeComposer,
    array
  }),
  "isStrictMode": true
}), templateOnly());