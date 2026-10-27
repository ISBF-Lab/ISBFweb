# frozen_string_literal: true

class DiscourseAcademyRoles::Admin::StudentGroupBatchesController < ::Admin::AdminController
  requires_plugin "discourse-academy-roles"
  before_action :ensure_developer
  before_action :limit_preview, only: %i[preview undo_preview]
  before_action :limit_execution, only: %i[execute retry]

  rescue_from DiscourseAcademyRoles::StudentGroups::Error do |error|
    render_json_error(error.message, status: :conflict)
  end

  def options
    groups = DiscourseAcademyRoles::StudentGroups::Groups
    alumni = groups.alumni
    render json: {
             groups: groups.available.map { |group| { id: group.id, name: group.name } },
             alumni_group_id: alumni&.id,
             alumni_error: alumni ? nil : I18n.t("academy_roles.student_groups.errors.alumni_unavailable"),
             max_rows: DiscourseAcademyRoles::StudentGroups::MAX_ROWS,
             max_bytes: DiscourseAcademyRoles::StudentGroups::MAX_BYTES,
           }
  end

  def index
    page = [params[:page].to_i, 0].max
    page_size = DiscourseAcademyRoles::StudentGroups::PAGE_SIZE
    batches = DiscourseAcademyRoles::StudentGroupBatch.order(id: :desc).offset(page * page_size).limit(page_size + 1).to_a
    render json: {
             batches: batches.first(page_size).map { |batch| DiscourseAcademyRoles::StudentGroupBatchSerializer.new(batch, scope: guardian, root: false, compact: true).as_json },
             has_more: batches.length > page_size,
           }
  end

  def preview
    DiscourseAcademyRoles::StudentGroups::CreatePreview.call(service_params) do
      on_success { |batch:| render_batch(batch) }
      on_failed_contract { |contract| render_json_error(contract.errors.full_messages, status: :bad_request) }
      on_failed_policy(:developer) { raise Discourse::InvalidAccess }
      on_model_not_found(:batch) do |model|
        raise model.exception if model.exception
        raise Discourse::NotFound
      end
      on_failure { render_json_error(I18n.t("academy_roles.student_groups.errors.execution_failed"), status: :unprocessable_entity) }
    end
  end

  def show
    render_batch(find_batch)
  end

  def execute
    DiscourseAcademyRoles::StudentGroups::ConfirmBatch.call(
      service_params.deep_merge(params: { batch_id: params[:id] }),
    ) do
      on_success { |batch:| render_batch(batch) }
      on_failed_contract { |contract| render_json_error(contract.errors.full_messages, status: :bad_request) }
      on_failed_policy(:developer) { raise Discourse::InvalidAccess }
      on_failed_policy(:initiator) { raise Discourse::InvalidAccess }
      on_model_not_found(:batch) { raise Discourse::NotFound }
      on_failure { render_json_error(I18n.t("academy_roles.student_groups.errors.execution_failed"), status: :unprocessable_entity) }
    end
  end

  def retry
    batch = DiscourseAcademyRoles::StudentGroups::Confirmation.retry(actor: current_user, batch: find_batch)
    render_batch(batch)
  end

  def undo_preview
    batch = DiscourseAcademyRoles::StudentGroups::Preview.undo(actor: current_user, source: find_batch)
    render_batch(batch)
  end

  def download
    batch = find_batch
    csv = CSV.generate do |output|
      output << %w[batch_id student_number username status reason requested_additions requested_removals completed_additions completed_removals primary_group_before primary_group_after title_before title_after flair_group_before flair_group_after]
      batch.items.order(:position).each do |item|
        serialized = DiscourseAcademyRoles::StudentGroupBatchItemSerializer.new(item, scope: guardian, root: false, batch:).as_json
        output << [batch.id, item.student_number, item.username, item.status, serialized[:reason], serialized[:add_groups].join("; "), serialized[:remove_groups].join("; "), serialized[:completed_add_groups].join("; "), serialized[:completed_remove_groups].join("; "), item.before_snapshot.dig("display", "primary_group_id"), item.after_snapshot.dig("display", "primary_group_id"), item.before_snapshot.dig("display", "title"), item.after_snapshot.dig("display", "title"), item.before_snapshot.dig("display", "flair_group_id"), item.after_snapshot.dig("display", "flair_group_id")].map do |value|
          text = value.to_s
          text.match?(/\A[=+\-@\t\r\n]/) ? "'#{text}" : text
        end
      end
    end
    send_data "\uFEFF#{csv}", type: "text/csv; charset=utf-8", filename: "student-group-batch-#{batch.id}.csv"
  end

  private

  def ensure_developer
    DiscourseAcademyRoles::StudentGroups.ensure_developer!(current_user)
    response.headers["Cache-Control"] = "no-store"
  end

  def limit_preview
    RateLimiter.new(current_user, "academy-group-preview", 6, 1.minute).performed!
  end

  def limit_execution
    RateLimiter.new(current_user, "academy-group-execute", 10, 1.minute).performed!
  end

  def find_batch
    DiscourseAcademyRoles::StudentGroupBatch.find(params[:id])
  end

  def render_batch(batch)
    page = [params[:page].to_i, 0].max
    page_size = DiscourseAcademyRoles::StudentGroups::PAGE_SIZE
    items = batch.items.order(:position).offset(page * page_size).limit(page_size + 1).to_a
    render json: {
             batch: DiscourseAcademyRoles::StudentGroupBatchSerializer.new(batch, scope: guardian, root: false).as_json,
             items: items.first(page_size).map { |item| DiscourseAcademyRoles::StudentGroupBatchItemSerializer.new(item, scope: guardian, root: false, batch:).as_json },
             has_more: items.length > page_size,
             page:,
           }
  end
end
