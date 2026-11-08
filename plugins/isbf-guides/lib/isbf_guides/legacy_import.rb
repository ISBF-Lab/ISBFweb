# frozen_string_literal: true

module ::IsbfGuides
  class LegacyImport
    def self.call(directory:, actor:)
      new(directory:, actor:).import
    end

    def initialize(directory:, actor:)
      @directory = Pathname.new(directory)
      @actor = actor
    end

    def import
      raise Discourse::InvalidAccess unless @actor.guardian.can_manage_isbf_guides?
      existing = Guide.find_by(slug: "android")
      return existing if existing

      document = Nokogiri.HTML5(@directory.join("index.html").read)
      intro = document.at_css("main #prep")
      sections = document.css("main > section")
      raise "Invalid Android tutorial source" unless intro && sections.length == 8

      title = intro.at_css("h1").text.strip
      intro.at_css("h1").remove
      heading = Nokogiri::XML::Node.new("h2", document)
      heading.content = "开始前说明"
      intro.prepend_child(heading)
      anchors = { "开始前说明" => "prep" }
      document
        .css("main [id]")
        .each do |node|
          section_heading = node.matches?("h3") ? node : node.at_css("h2, h3")
          anchors[section_heading.text.strip] = node["id"] if section_heading
        end
      raw = sections.map { |section| markdown(section) }.join("\n\n").gsub(/\n{3,}/, "\n\n").strip
      raise "Android screenshots are incomplete" unless raw.scan(/!\[/).length == 29

      Guide.transaction do
        guide = Guide.create!(slug: "android")
        (1..29).each do |number|
          filename = format("step-%02d.jpg", number)
          guide.images.create!(
            filename:,
            creator: @actor,
            data: @directory.join("images", filename).binread,
          )
        end
        result =
          SaveDraft.call(
            guardian: @actor.guardian,
            params: {
              guide_id: guide.id,
              version: guide.lock_version,
              slug: guide.slug,
              title:,
              summary: "Android 客户端的账号登录、通知权限、常驻提示与省电设置，附 29 张实机截图。",
              raw:,
            },
            options: {
              anchors:,
            },
          )
        raise "Android draft import failed: #{result.inspect}" unless result.success?
        result =
          Publish.call(
            guardian: @actor.guardian,
            params: {
              guide_id: guide.id,
              version: guide.reload.lock_version,
            },
          )
        raise "Android publication import failed: #{result.inspect}" unless result.success?
        guide.reload
      end
    end

    private

    def markdown(node)
      return node.text.gsub(/\s+/, " ") if node.text?
      return "" if node.comment?
      content = -> { node.children.map { |child| markdown(child) }.join }
      case node.name
      when "h2", "h3"
        level = node["class"].to_s.include?("__step-title") ? 4 : node.name.delete_prefix("h").to_i
        "\n\n#{"#" * level} #{content.call.strip}\n\n"
      when "p"
        "\n\n#{content.call.strip}\n\n"
      when "strong", "b"
        "**#{content.call.strip}**"
      when "em", "i", "figcaption"
        "\n\n*#{content.call.strip}*\n\n"
      when "img"
        "\n\n![#{node["alt"].to_s.gsub(/[\[\]\\]/, "")}](#{node["src"]})\n\n"
      when "ul", "ol"
        node
          .css("> li")
          .each_with_index
          .map do |item, index|
            prefix = node.name == "ol" ? "#{index + 1}." : "-"
            "\n#{prefix} #{markdown(item).strip.gsub(/\n+/, " ")}"
          end
          .join + "\n\n"
      when "a"
        "[#{content.call.strip}](#{node["href"]})"
      when "br"
        "\n"
      when "div", "section", "article", "figure"
        "\n\n#{content.call.strip}\n\n"
      else
        content.call
      end
    end
  end
end
