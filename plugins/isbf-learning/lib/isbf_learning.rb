# frozen_string_literal: true

require "uri"
require "cgi"

module IsbfLearning
  def self.can_manage?(guardian)
    guardian.is_admin? ||
      (guardian.respond_to?(:academy_can?) && guardian.academy_can?(:manage_resources))
  end

  def self.can_review?(guardian)
    guardian.is_admin? ||
      (guardian.respond_to?(:academy_can?) && guardian.academy_can?(:review_resources))
  end

  STORE = "isbf-learning"
  COURSE_FIELD = "isbf_learning_course_id"
  GROUP_FIELD = COURSE_FIELD
  FILES_FIELD = "isbf_learning_files"
  LINK_FIELD = "isbf_learning_link"
  DESCRIPTION_FIELD = "isbf_learning_description"
  DESCRIPTION_LIMIT = 300
  CONTRIBUTOR_FIELD = "isbf_learning_contributor"
  CONTRIBUTOR_LIMIT = 15
  RESOURCE_FIELDS = [
    COURSE_FIELD,
    FILES_FIELD,
    LINK_FIELD,
    DESCRIPTION_FIELD,
    CONTRIBUTOR_FIELD,
  ].freeze
  GRADES = (1..4).map { |id| { id: id, label: %w[大一 大二 大三 大四][id - 1] } }.freeze
  class StorageError < StandardError
  end

  def self.category_id
    id = SiteSetting.isbf_learning_category_id.to_i
    id if id.positive? && Category.exists?(id: id)
  end

  def self.enabled?
    SiteSetting.isbf_learning_enabled && category_id.present?
  end

  def self.resource_libraries
    [IsbfLearning, IsbfLibrary]
  end

  def self.all_resource_fields
    resource_libraries.flat_map { |library| library::RESOURCE_FIELDS }
  end

  def self.resource_library_for_category(id)
    return unless id.to_i.positive?
    resource_libraries.find { |library| library.category_id == id.to_i }
  end

  def self.resource_library_for_topic(topic)
    resource_library_for_category(topic.category_id) if topic && !topic.private_message?
  end

  def self.ensure_scope_fields!(library, options)
    foreign = all_resource_fields - library::RESOURCE_FIELDS
    if foreign.any? { |field| !options[field.to_sym].nil? }
      raise Discourse::InvalidParameters.new("resource_library")
    end
  end

  def self.reviewable_resource_library(reviewable)
    return unless reviewable.is_a?(ReviewableQueuedPost)
    resource_library_for_category(reviewable.category_id) ||
      resource_libraries.find { |library| reviewable.payload&.[](library::GROUP_FIELD).present? }
  end

  def self.learning_topic?(topic)
    category_id && topic&.category_id == category_id && !topic.private_message?
  end

  def self.ensure_can_submit!(user, guardian)
    category = Category.find_by(id: category_id)
    permitted =
      SiteSetting.isbf_learning_enabled && user&.active? && (user.staff? || user.approved?) &&
        !user.silenced? && !user.suspended? && category &&
        guardian.can_create_topic_on_category?(category)
    raise Discourse::InvalidAccess unless permitted
  end

  def self.file_ids(value)
    ids = value.is_a?(String) ? JSON.parse(value) : value
    unless ids.is_a?(Array) && ids.length <= 20 && ids.uniq == ids &&
             ids.all? { |id| id.is_a?(String) && Files.valid_id?(id) }
      raise Discourse::InvalidParameters.new(FILES_FIELD)
    end
    ids
  rescue JSON::ParserError
    raise Discourse::InvalidParameters.new(FILES_FIELD)
  end

  def self.links(raw)
    URI
      .extract(raw.to_s, %w[http https])
      .filter_map do |value|
        value = value.sub(/[)\]>.,，。]+\z/, "")
        uri = URI.parse(value)
        value if uri.host.present? && !uri.userinfo && uri.host != Discourse.current_hostname
      rescue URI::InvalidURIError
        nil
      end
      .uniq
      .first(20)
  end

  def self.external_link(value)
    unless value.is_a?(String) && value.length.between?(1, 2048) &&
             !value.match?(/[\\\s\x00-\x20<>]/)
      raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.invalid_link"))
    end
    uri = URI.parse(value)
    if %w[http https].exclude?(uri.scheme&.downcase) || uri.host.blank? || uri.userinfo ||
         uri.host.casecmp?(Discourse.current_hostname)
      raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.invalid_link"))
    end
    value
  rescue URI::InvalidURIError
    raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.invalid_link"))
  end

  def self.description(value)
    return "" if value.nil?
    unless value.is_a?(String) && value.length <= DESCRIPTION_LIMIT &&
             !value.match?(/[\x00-\x08\x0b\x0c\x0e-\x1f]/)
      raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.invalid_description"))
    end
    value.gsub("\r\n", "\n").gsub("\r", "\n").strip
  end

  def self.contributor_name(user)
    user&.name.presence || user&.username.presence || I18n.t("isbf_learning.unknown_contributor")
  end

  def self.contributor(value, user)
    default = contributor_name(user)
    return default if value.nil? || (value.is_a?(String) && value.strip.empty?)
    valid =
      value.is_a?(String) && !value.match?(/[\x00-\x1f\x7f]/) &&
        (value.strip.length <= CONTRIBUTOR_LIMIT || value.strip == default)
    raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.invalid_contributor")) unless valid
    value.strip
  end

  def self.learning_reviewable?(reviewable)
    reviewable_resource_library(reviewable).present?
  end

  def self.link_body(title, link, introduction = "")
    label = CGI.escapeHTML(title).gsub(/[\\\[\]]/) { |character| "\\#{character}" }
    body = "[#{label}](<#{link}>)"
    return body if introduction.blank?
    plain =
      CGI.escapeHTML(
        introduction.gsub(/[\\`*_{}\[\]()#+.!|~:\/-]/) { |character| "\\#{character}" },
      )
    "#{body}\n\n#{plain}"
  end

  def self.validate_payload!(user, options)
    ensure_can_submit!(user, user&.guardian)
    ensure_scope_fields!(self, options)
    description(options[DESCRIPTION_FIELD.to_sym])
    contributor(options[CONTRIBUTOR_FIELD.to_sym], user)
    course = Courses.find(options[COURSE_FIELD.to_sym])
    ids = file_ids(options[FILES_FIELD.to_sym])
    raw = options[:raw].to_s
    if options[LINK_FIELD.to_sym].present?
      external_link(options[LINK_FIELD.to_sym])
      raise Discourse::InvalidParameters.new(FILES_FIELD) unless ids.empty?
    end
    if !course || options[:title].to_s.strip.blank? ||
         options[:title].to_s.include?("[isbf-untitled:") ||
         options[:archetype] == Archetype.private_message || options[:isbf_anonymous] ||
         raw.match?(%r{(?:upload://|/uploads/)}i) || (ids.empty? && links(raw).empty?)
      raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.invalid"))
    end
    referenced = raw.scan(%r{/isbf/learning/files/([0-9a-f-]{36})}).flatten.uniq
    raise Discourse::InvalidParameters.new(FILES_FIELD) unless (referenced - ids).empty?
    ids.each do |id|
      file = Files.metadata(id)
      permitted =
        file &&
          (
            can_manage?(user.guardian) || can_review?(user.guardian) || file[:owner_id] == user.id
          ) && file_accessible?(id, user, user.guardian)
      raise Discourse::InvalidAccess unless permitted
    end
    [course, ids]
  end

  def self.visible_resource?(topic, guardian)
    unless guardian.user && learning_topic?(topic) && topic.visible && !topic.deleted_at &&
             guardian.can_see_topic?(topic)
      return false
    end
    post = topic.first_post
    post && post.post_type == Post.types[:regular] && !post.deleted_at && !post.user_deleted &&
      !post.hidden? && guardian.can_see_post?(post) &&
      !(defined?(IsbfModeration::Hold) && IsbfModeration::Hold.persisted?(post))
  end

  def self.file_accessible?(id, user, guardian)
    return false unless user
    file = Files.metadata(id)
    return false unless file
    # Existing topic references take precedence over ownership and stale queues.
    references =
      Topic
        .with_deleted
        .joins(:_custom_fields)
        .where(topic_custom_fields: { name: FILES_FIELD })
        .where("topic_custom_fields.value LIKE ?", "%#{id}%")
        .distinct
    return references.any? { |topic| visible_resource?(topic, guardian) } if references.exists?
    return false if file[:bound]
    pending =
      ReviewableQueuedPost
        .pending
        .where(category_id: category_id)
        .where("payload ->> ? LIKE ?", FILES_FIELD, "%#{id}%")
    if pending.exists?
      return(
        pending.viewable_by(user).exists? || pending.where(target_created_by_id: user.id).exists?
      )
    end
    can_manage?(guardian) || file[:owner_id] == user.id
  end

  def self.resource(topic, guardian)
    course = Courses.find(topic.custom_fields[COURSE_FIELD])
    return unless course && visible_resource?(topic, guardian)
    post = topic.first_post
    link = topic.custom_fields[LINK_FIELD].presence
    files =
      file_ids(topic.custom_fields[FILES_FIELD] || []).filter_map do |id|
        file = Files.metadata(id)
        file&.slice(:id, :name, :size, :url)
      end
    {
      id: topic.id,
      title: topic.title,
      url: topic.relative_url,
      description:
        (
          if link
            description(topic.custom_fields[DESCRIPTION_FIELD])
          else
            PrettyText.excerpt(post.cooked, 280, strip_links: true, strip_images: true)
          end
        ),
      created_at: post.created_at,
      grade: course["grade"],
      course: course,
      contributor: topic.custom_fields[CONTRIBUTOR_FIELD].presence || contributor_name(post.user),
      can_delete: can_manage?(guardian) && guardian.can_delete_topic?(topic),
      author:
        post.user &&
          {
            username: post.user.username,
            name: post.user.name,
            avatar_template: post.user.avatar_template,
          },
      files: files,
      links: link ? [external_link(link)] : links(post.raw),
      link_only: link.present?,
    }
  end
end

require_relative "isbf_learning/courses"
require_relative "isbf_learning/files"
