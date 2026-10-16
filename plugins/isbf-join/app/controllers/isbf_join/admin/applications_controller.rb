# frozen_string_literal: true

module ::IsbfJoin
  module Admin
    class ApplicationsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      def index
        response.headers["Cache-Control"] = "no-store"
        page = [params[:page].to_i, 1].max
        applications =
          Application
            .order(created_at: :desc, id: :desc)
            .offset((page - 1) * PAGE_SIZE)
            .limit(PAGE_SIZE + 1)
            .to_a

        render json: {
                 applications: serialize_data(applications.first(PAGE_SIZE), ApplicationSerializer),
                 page: page,
                 has_more: applications.length > PAGE_SIZE,
               }
      end
    end
  end
end
