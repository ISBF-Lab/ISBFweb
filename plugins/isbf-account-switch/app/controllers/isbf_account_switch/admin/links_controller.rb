# frozen_string_literal: true

module IsbfAccountSwitch
  module Admin
    class LinksController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      before_action :ensure_enabled

      def index
        links =
          AccountLink
            .includes(:user_a, :user_b, :requester, :approved_by, :rejected_by, :revoked_by)
            .order(updated_at: :desc)
            .limit(200)
        audits = AuditEvent.includes(:actor).order(created_at: :desc).limit(200)

        render json: {
                 links: links.map { |link| serialize_link(link) },
                 audit_events: audits.map { |event| serialize_audit(event) },
               }
      end

      def approve
        link = AccountLink.find(params[:id])
        unless link.pending_admin? && link.user_a.present? && link.user_b.present?
          return render_error(:invalid_link)
        end

        link.update!(status: :approved, approved_by: current_user, approved_at: Time.zone.now)
        AuditEvent.record!(
          action: "link_approved",
          link: link,
          actor: current_user,
          request: request,
        )
        render json: { link: serialize_link(link.reload) }
      end

      def reject
        link = AccountLink.find(params[:id])
        return render_error(:invalid_link) unless link.pending_target? || link.pending_admin?

        link.update!(status: :rejected, rejected_by: current_user, rejected_at: Time.zone.now)
        link.device_grants.update_all(revoked_at: Time.zone.now)
        AuditEvent.record!(
          action: "link_rejected",
          link: link,
          actor: current_user,
          request: request,
        )
        render json: { link: serialize_link(link.reload) }
      end

      def revoke
        link = AccountLink.find(params[:id])
        link.update!(status: :revoked, revoked_by: current_user, revoked_at: Time.zone.now)
        link.device_grants.update_all(revoked_at: Time.zone.now)
        AuditEvent.record!(
          action: "link_revoked",
          link: link,
          actor: current_user,
          request: request,
        )
        render json: { link: serialize_link(link.reload) }
      end

      private

      def ensure_enabled
        raise Discourse::NotFound unless SiteSetting.isbf_account_switch_enabled
      end

      def render_error(key)
        render json: {
                 errors: [I18n.t("isbf_account_switch.errors.#{key}")],
               },
               status: :unprocessable_entity
      end

      def serialize_audit(event)
        {
          id: event.id,
          action: event.action,
          account_link_id: event.account_link_id,
          actor: event.actor&.username,
          metadata: event.metadata,
          created_at: event.created_at,
        }
      end

      def serialize_link(link)
        {
          id: link.id,
          status: link.status,
          user_a: user_payload(link.user_a, link.user_a_id),
          user_b: user_payload(link.user_b, link.user_b_id),
          requester: link.requester&.username,
          approved_by: link.approved_by&.username,
          approved_at: link.approved_at,
          rejected_by: link.rejected_by&.username,
          rejected_at: link.rejected_at,
          revoked_by: link.revoked_by&.username,
          revoked_at: link.revoked_at,
          created_at: link.created_at,
          updated_at: link.updated_at,
        }
      end

      def user_payload(user, user_id)
        { id: user_id, username: user&.username, name: user&.name }
      end
    end
  end
end
