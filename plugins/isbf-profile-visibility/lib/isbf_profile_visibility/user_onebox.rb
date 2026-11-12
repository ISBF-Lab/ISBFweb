# frozen_string_literal: true

module IsbfProfileVisibility
  module UserOnebox
    # The preview is stored inside the post, so it follows the owner's choice
    # rather than what the author of the post happens to be allowed to see.
    def local_user_html(url, route, opts)
      html = super
      return html if html.blank? || !IsbfProfileVisibility.enabled?

      user = User.find_by(username_lower: route[:username].to_s.downcase)
      return html if user.blank? || !IsbfProfileVisibility.hidden_by_owner?(user, :bio)

      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css(".user-onebox > p, .user-onebox span.location").each(&:remove)
      fragment
        .css(".user-onebox span")
        .each { |span| span.remove if span.at_css("a[href]") && !span.at_css(".full-name") }
      fragment.to_html
    end
  end
end
