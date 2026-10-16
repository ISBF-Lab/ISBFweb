# frozen_string_literal: true

require_relative "../../../plugin_helper"

RSpec.describe IsbfJoin::Admin::ApplicationsController do
  fab!(:application, :isbf_join_application)

  describe "#index" do
    context "without an authenticated user" do
      it "denies the records endpoint and the direct admin page" do
        get "/isbf/join/admin/applications.json"
        expect(response.status).to eq(403)
        expect(response.body).not_to include(application.student_id)

        get "/admin/plugins/isbf-join/applications"
        expect(response.status).to eq(404)
        expect(response.body).not_to include(application.student_id)
      end
    end

    context "with a regular user" do
      fab!(:user)

      before { sign_in(user) }

      it "denies both records and the direct admin page" do
        get "/isbf/join/admin/applications.json"
        expect(response.status).to eq(403)
        expect(response.body).not_to include(application.student_id)

        get "/admin/plugins/isbf-join/applications"
        expect(response.status).to eq(404)
        expect(response.body).not_to include(application.student_id)
      end
    end

    context "with a moderator" do
      fab!(:user, :moderator)

      before { sign_in(user) }

      it "reserves records and the direct admin page for administrators" do
        get "/isbf/join/admin/applications.json"
        expect(response.status).to eq(403)
        expect(response.body).not_to include(application.student_id)

        get "/admin/plugins/isbf-join/applications"
        expect(response.status).to eq(404)
        expect(response.body).not_to include(application.student_id)
      end
    end

    context "with an administrator" do
      fab!(:user, :admin)

      before { sign_in(user) }

      it "supports a direct page reload and exposes the four record fields" do
        get "/admin/plugins/isbf-join/applications"
        expect(response.status).to eq(200)
        expect(response.media_type).to eq("text/html")

        get "/isbf/join/admin/applications.json"
        expect(response.status).to eq(200)
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.parsed_body).to include("page" => 1, "has_more" => false)
        expect(response.parsed_body["applications"]).to contain_exactly(
          "id" => application.id,
          "name" => application.name,
          "student_id" => application.student_id,
          "phone" => application.phone,
          "created_at" => application.created_at.iso8601(3),
        )
      end

      it "paginates fifty newest records with a stable ID ordering for equal timestamps" do
        application.update!(created_at: 1.day.ago)
        applications =
          Fabricate.times(50, :isbf_join_application, created_at: Time.current.change(usec: 0))

        get "/isbf/join/admin/applications.json"
        first_page = response.parsed_body
        expect(first_page["applications"].map { |record| record["id"] }).to eq(
          applications.reverse.map(&:id),
        )
        expect(first_page).to include("page" => 1, "has_more" => true)

        get "/isbf/join/admin/applications.json", params: { page: 2 }
        expect(response.parsed_body["applications"].map { |record| record["id"] }).to eq(
          [application.id],
        )
        expect(response.parsed_body).to include("page" => 2, "has_more" => false)

        get "/isbf/join/admin/applications.json", params: { page: 3 }
        expect(response.parsed_body).to eq("applications" => [], "page" => 3, "has_more" => false)
      end

      it "defaults invalid and nonpositive page parameters to the first page" do
        %w[invalid 0 -1].each do |page|
          get "/isbf/join/admin/applications.json", params: { page: page }
          expect(response.status).to eq(200)
          expect(response.parsed_body["page"]).to eq(1)
          expect(response.parsed_body["applications"].map { |record| record["id"] }).to eq(
            [application.id],
          )
        end
      end

      it "returns an empty result when there are no applications" do
        application.destroy!

        get "/isbf/join/admin/applications.json"

        expect(response.parsed_body).to eq("applications" => [], "page" => 1, "has_more" => false)
      end
    end
  end
end
