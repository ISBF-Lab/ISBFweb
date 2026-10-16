# frozen_string_literal: true

module ::IsbfJoin
  class PagesController < PublicController
    # Module and worker requests load public scripts without XHR headers.
    skip_after_action :verify_same_origin_request, only: :asset

    CONTENT_SECURITY_POLICY = [
      "default-src 'self'",
      "script-src 'self' 'wasm-unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob:",
      "font-src 'self'",
      # The image bitmap loader fetches embedded model textures from blob URLs.
      "connect-src 'self' blob:",
      "worker-src 'self' blob:",
      "object-src 'none'",
      "base-uri 'self'",
      "frame-ancestors 'none'",
    ].join("; ").freeze

    def index
      response.headers["Content-Security-Policy"] = CONTENT_SECURITY_POLICY
      response.headers["Cache-Control"] = "no-store"
      serve_asset("index.html")
    end

    def asset
      asset_path = params[:asset_path]
      raise Discourse::NotFound if asset_path == "index.html"
      response.headers["Cache-Control"] = (
        if asset_path.start_with?("assets/")
          "public, max-age=31536000, immutable"
        else
          "no-cache"
        end
      )
      serve_asset(asset_path)
    end

    private

    def serve_asset(path)
      asset = Assets.find(path)
      raise Discourse::NotFound if !asset
      response.headers["X-Content-Type-Options"] = "nosniff"
      response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
      send_file asset[:file], type: asset[:type], disposition: :inline
    end
  end
end
