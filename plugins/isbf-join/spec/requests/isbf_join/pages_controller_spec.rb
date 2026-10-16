# frozen_string_literal: true

require_relative "../../plugin_helper"

RSpec.describe IsbfJoin::PagesController do
  describe "#index" do
    it "serves the standalone public page with its own security policy" do
      get "/join/"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include("/join/assets/")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["Content-Security-Policy"]).to include(
        "script-src 'self' 'wasm-unsafe-eval'",
        "connect-src 'self' blob:",
        "worker-src 'self' blob:",
        "frame-ancestors 'none'",
      )
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    end

    context "when the forum requires login" do
      before { SiteSetting.login_required = true }

      it "still serves both public entry URLs to anonymous visitors" do
        %w[/join /join/].each do |path|
          get path
          expect(response.status).to eq(200)
          expect(response.media_type).to eq("text/html")
        end
      end
    end
  end

  describe "#asset" do
    let(:manifest) { JSON.parse(IsbfJoin::Assets::ROOT.join("asset-manifest.json").read) }

    before { SiteSetting.login_required = true }

    it "serves the built scripts, styles, font, model and Draco assets to anonymous visitors" do
      expected_types = {
        ".js" => "text/javascript",
        ".css" => "text/css",
        ".woff2" => "font/woff2",
        ".glb" => "model/gltf-binary",
        ".wasm" => "application/wasm",
      }

      expected_types.each do |extension, content_type|
        path = manifest.keys.find { |asset_path| File.extname(asset_path) == extension }
        expect(path).to be_present

        get "/join/#{path}"

        expect(response.status).to eq(200)
        expect(response.media_type).to eq(content_type)
        expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
        expect(Digest::SHA256.hexdigest(response.body)).to eq(manifest.fetch(path).fetch("sha256"))
        if path.start_with?("assets/")
          expect(response.headers["Cache-Control"]).to include("immutable")
        end
      end
    end

    it "keeps source files and unlisted paths inaccessible" do
      %w[
        src/main.js
        package.json
        asset-manifest.json
        .env
        .git/config
        index.html
        missing.js
      ].each do |path|
        get "/join/#{path}"
        expect(response.status).to eq(404)
      end
    end
  end
end
