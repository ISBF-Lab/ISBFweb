# frozen_string_literal: true

require_relative "../../plugin_helper"

RSpec.describe IsbfJoin::ApplicationsController do
  describe "#create" do
    let(:payload) do
      {
        name: "申请人",
        studentId: "2026101401",
        phone: "+86 138-0013-8000",
        submissionId: "491e9a65-3270-4acd-8ba9-dc726a6a0307",
      }
    end
    let(:headers) do
      {
        "CONTENT_TYPE" => "application/json",
        "HTTP_ACCEPT" => "application/json",
        "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
      }
    end

    it "accepts the public camelCase protocol and returns the submission ID" do
      expect { post "/api/applications", params: payload.to_json, headers: headers }.to change(
        IsbfJoin::Application,
        :count,
      ).by(1)

      expect(response.status).to eq(201)
      expect(response.parsed_body).to eq("ok" => true, "id" => payload[:submissionId])
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(IsbfJoin::Application.last).to have_attributes(
        name: payload[:name],
        student_id: payload[:studentId],
        phone: payload[:phone],
        submission_id: payload[:submissionId],
      )
    end

    context "when the forum requires login" do
      before { SiteSetting.login_required = true }

      it "still accepts a submission from an anonymous visitor" do
        post "/api/applications", params: payload.to_json, headers: headers

        expect(response.status).to eq(201)
        expect(response.parsed_body["ok"]).to eq(true)
      end
    end

    it "returns field errors with camelCase names and stores nothing" do
      expect {
        post "/api/applications",
             params: payload.merge(name: "", studentId: "", phone: "", submissionId: "").to_json,
             headers: headers
      }.not_to change(IsbfJoin::Application, :count)

      expect(response.status).to eq(400)
      expect(response.parsed_body["ok"]).to eq(false)
      expect(response.parsed_body["errors"].keys).to contain_exactly(
        "name",
        "studentId",
        "phone",
        "submissionId",
      )
    end

    it "rejects non-string fields rather than coercing them into contact information" do
      [nil, 123, true, [], {}].each do |value|
        expect {
          post "/api/applications",
               params:
                 payload.merge(
                   name: value,
                   studentId: value,
                   phone: value,
                   submissionId: value,
                 ).to_json,
               headers: headers
        }.not_to change(IsbfJoin::Application, :count)

        expect(response.status).to eq(400)
        expect(response.parsed_body["errors"].keys).to contain_exactly(
          "name",
          "studentId",
          "phone",
          "submissionId",
        )
      end
    end

    it "requires the external camelCase keys" do
      post "/api/applications",
           params: {
             name: payload[:name],
             student_id: payload[:studentId],
             phone: payload[:phone],
             submission_id: payload[:submissionId],
           }.to_json,
           headers: headers

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"].keys).to contain_exactly("studentId", "submissionId")
    end

    it "rejects cross-site browser submissions before saving any contact details" do
      [
        { "HTTP_ORIGIN" => "https://unrelated.example" },
        { "HTTP_SEC_FETCH_SITE" => "cross-site" },
      ].each do |cross_site_headers|
        expect {
          post "/api/applications",
               params: payload.to_json,
               headers: headers.merge(cross_site_headers)
        }.not_to change(IsbfJoin::Application, :count)
        expect(response.status).to eq(403)
        expect(response.parsed_body["ok"]).to eq(false)
      end

      post "/api/applications",
           params: payload.to_json,
           headers:
             headers.merge(
               "HTTP_ORIGIN" => "http://test.localhost",
               "HTTP_SEC_FETCH_SITE" => "same-origin",
             )
      expect(response.status).to eq(201)
    end

    it "ignores unrecognized fields without allowing record attributes to be set" do
      post "/api/applications",
           params:
             payload.merge(id: 999_999, created_at: "2000-01-01T00:00:00Z", admin: true).to_json,
           headers: headers

      expect(response.status).to eq(201)
      expect(IsbfJoin::Application.last.id).not_to eq(999_999)
      expect(IsbfJoin::Application.last.created_at).to be > Time.utc(2000, 1, 1)
    end

    it "replays normalized identical submissions and rejects changed submissions" do
      post "/api/applications", params: payload.to_json, headers: headers
      original = response.parsed_body

      expect {
        post "/api/applications",
             params:
               payload.merge(name: " 申请人 ", submissionId: payload[:submissionId].upcase).to_json,
             headers: headers
      }.not_to change(IsbfJoin::Application, :count)
      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq(original)

      expect {
        post "/api/applications",
             params: payload.merge(phone: "13900139000").to_json,
             headers: headers
      }.not_to change(IsbfJoin::Application, :count)
      expect(response.status).to eq(409)
      expect(response.parsed_body["ok"]).to eq(false)
      expect(IsbfJoin::Application.last.phone).to eq(payload[:phone])
    end

    it "accepts 4096 bytes and rejects larger bodies by byte size" do
      body = payload.to_json
      exact_body = body + " " * (4096 - body.bytesize)
      post "/api/applications", params: exact_body, headers: headers
      expect(response.status).to eq(201)

      expect { post "/api/applications", params: exact_body + " ", headers: headers }.not_to change(
        IsbfJoin::Application,
        :count,
      )
      expect(response.status).to eq(413)
      expect(response.parsed_body["ok"]).to eq(false)
    end

    it "requires JSON media types while accepting the charset parameter" do
      %w[application/x-www-form-urlencoded text/plain].each do |media_type|
        post "/api/applications",
             params: payload.to_json,
             headers: headers.merge("CONTENT_TYPE" => media_type)
        expect(response.status).to eq(415)
        expect(response.parsed_body["ok"]).to eq(false)
      end

      post "/api/applications",
           params: payload.to_json,
           headers: headers.merge("CONTENT_TYPE" => "application/json; charset=UTF-8")
      expect(response.status).to eq(201)
    end

    it "rejects malformed JSON and non-object JSON" do
      ["{", "[]", "null"].each do |body|
        expect { post "/api/applications", params: body, headers: headers }.not_to change(
          IsbfJoin::Application,
          :count,
        )
        expect(response.status).to eq(400)
      end
    end

    context "with CSRF protection enabled" do
      before { ActionController::Base.allow_forgery_protection = true }
      after { ActionController::Base.allow_forgery_protection = false }

      it "rejects missing and invalid tokens and accepts the session's actual token" do
        [nil, "invalid-token"].each do |token|
          expect {
            post "/api/applications",
                 params: payload.to_json,
                 headers: token ? headers.merge("X-CSRF-Token" => token) : headers
          }.not_to change(IsbfJoin::Application, :count)
          expect(response.status).to eq(403)
        end

        get "/session/csrf.json", headers: headers.except("CONTENT_TYPE")
        expect(response.status).to eq(200)
        csrf = response.parsed_body.fetch("csrf")
        expect(csrf).to be_present

        expect {
          post "/api/applications",
               params: payload.to_json,
               headers: headers.merge("X-CSRF-Token" => csrf)
        }.to change(IsbfJoin::Application, :count).by(1)
        expect(response.status).to eq(201)
      end
    end

    context "with rate limiting enabled" do
      before { RateLimiter.enable }

      it "limits each IP to twenty submissions per ten minutes" do
        20.times do
          post "/api/applications", params: payload.to_json, headers: headers
          expect(response.status).to be_in([200, 201])
        end

        expect {
          post "/api/applications", params: payload.to_json, headers: headers
        }.not_to change(IsbfJoin::Application, :count)
        expect(response.status).to eq(429)
        expect(response.headers["Retry-After"].to_i).to be_between(1, 600)
        expect(response.parsed_body["ok"]).to eq(false)

        post "/api/applications",
             params: payload.to_json,
             headers: headers.merge("REMOTE_ADDR" => "192.0.2.20")
        expect(response.status).to eq(200)
      end
    end

    context "when persistence is unavailable" do
      before do
        IsbfJoin::Application.stubs(:create_or_find_by).raises(ActiveRecord::StatementInvalid)
      end

      it "returns an unavailable response without claiming success" do
        expect {
          post "/api/applications", params: payload.to_json, headers: headers
        }.not_to change(IsbfJoin::Application, :count)
        expect(response.status).to eq(503)
        expect(response.parsed_body["ok"]).to eq(false)
      end
    end
  end
end
