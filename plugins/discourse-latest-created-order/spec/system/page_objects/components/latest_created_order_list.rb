# frozen_string_literal: true

module PageObjects
  module Components
    class LatestCreatedOrderList < TopicList
      def has_topic_order?(topics)
        topics.each_with_index.all? do |topic, index|
          page.has_css?(
            "#{TOPIC_LIST_ITEM_SELECTOR}:nth-child(#{index + 1})[data-topic-id='#{topic.id}']",
          )
        end
      end

      def load_more_topics
        page.execute_script(
          "document.querySelector('#list-area .load-more-sentinel').scrollIntoView(true)",
        )
      end

      def has_updated_topic_prompt?
        page.has_css?(".show-more a")
      end

      def show_updated_topics
        find(".show-more a").click
      end

      def has_campus_feed?
        page.has_css?(".isbf-feed-card")
      end
    end
  end
end
