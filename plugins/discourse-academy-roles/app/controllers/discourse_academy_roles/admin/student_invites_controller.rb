# frozen_string_literal: true

class DiscourseAcademyRoles::Admin::StudentInvitesController < ::Admin::AdminController
  requires_plugin "discourse-academy-roles"

  PAGE_SIZE = 40

  def index
    page = [params[:page].to_i, 0].max
    registrations =
      DiscourseAcademyRoles::StudentRegistration
        .includes(:invite, :user)
        .order(created_at: :desc, id: :desc)
        .offset(page * PAGE_SIZE)
        .limit(PAGE_SIZE + 1)
        .to_a

    render json: {
             student_invites:
               registrations
                 .first(PAGE_SIZE)
                 .map do |registration|
                   DiscourseAcademyRoles::StudentRegistrationSerializer.new(
                     registration,
                     scope: guardian,
                     root: false
                   ).as_json
                 end,
             has_more: registrations.length > PAGE_SIZE
           }
  end

  def create
    DiscourseAcademyRoles::CreateStudentInvite.call(service_params) do
      on_success do |student_registration:|
        render json:
                 DiscourseAcademyRoles::StudentRegistrationSerializer.new(
                   student_registration,
                   scope: guardian,
                   root: false
                 ).as_json,
               status: :created
      end
      on_failed_contract do |contract|
        render_json_error(contract.errors.full_messages, status: :bad_request)
      end
      on_failed_policy(:can_manage_student_invites) do
        raise Discourse::InvalidAccess
      end
      on_model_errors(:student_registration) do
        render_json_error(
          I18n.t("academy_roles.student_invites.duplicate_student_number"),
          status: :conflict
        )
      end
      on_exceptions(ActiveRecord::RecordNotUnique) do
        render_json_error(
          I18n.t("academy_roles.student_invites.duplicate_student_number"),
          status: :conflict
        )
      end
      on_failure do
        render_json_error(
          I18n.t("academy_roles.student_invites.create_failed"),
          status: :unprocessable_entity
        )
      end
    end
  end

  def bulk
    hijack do
      DiscourseAcademyRoles::BulkCreateStudentInvites.call(service_params) do
        on_success do |csv:|
          render json:
                   DiscourseAcademyRoles::StudentInviteBatchSerializer.new(
                     csv,
                     scope: guardian,
                     root: false
                   ).as_json,
                 status: csv.created_count.positive? ? :created : :ok
        end
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages, status: :bad_request)
        end
        on_failed_policy(:can_manage_student_invites) do
          render_json_error(I18n.t("invalid_access"), status: :forbidden)
        end
        on_model_not_found(:csv) do |model|
          if model.exception.is_a?(
               DiscourseAcademyRoles::StudentInviteCsv::InvalidFile
             )
            render_json_error(model.exception.message, status: :bad_request)
          else
            render_json_error(
              I18n.t("academy_roles.student_invites.create_failed"),
              status: :unprocessable_entity
            )
          end
        end
        on_failure do
          render_json_error(
            I18n.t("academy_roles.student_invites.create_failed"),
            status: :unprocessable_entity
          )
        end
      end
    end
  end

  def reissue
    DiscourseAcademyRoles::ReissueStudentInvite.call(
      service_params.deep_merge(
        params: {
          student_registration_id: params[:id]
        }
      )
    ) do
      on_success do |student_registration:|
        render json:
                 DiscourseAcademyRoles::StudentRegistrationSerializer.new(
                   student_registration,
                   scope: guardian,
                   root: false
                 ).as_json
      end
      on_failed_contract do |contract|
        render_json_error(contract.errors.full_messages, status: :bad_request)
      end
      on_failed_policy(:can_manage_student_invites) do
        raise Discourse::InvalidAccess
      end
      on_failed_policy(:unredeemed) do
        render_json_error(
          I18n.t("academy_roles.student_invites.already_registered"),
          status: :conflict
        )
      end
      on_model_not_found(:student_registration) { raise Discourse::NotFound }
      on_failure do
        render_json_error(
          I18n.t("academy_roles.student_invites.create_failed"),
          status: :unprocessable_entity
        )
      end
    end
  end

  def destroy
    DiscourseAcademyRoles::RevokeStudentInvite.call(
      service_params.deep_merge(
        params: {
          student_registration_id: params[:id]
        }
      )
    ) do
      on_success { head :no_content }
      on_failed_policy(:can_manage_student_invites) do
        raise Discourse::InvalidAccess
      end
      on_failed_policy(:unredeemed) do
        render_json_error(
          I18n.t("academy_roles.student_invites.already_registered"),
          status: :conflict
        )
      end
      on_model_not_found(:student_registration) { raise Discourse::NotFound }
      on_failure do
        render_json_error(
          I18n.t("academy_roles.student_invites.create_failed"),
          status: :unprocessable_entity
        )
      end
    end
  end
end
