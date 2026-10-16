# frozen_string_literal: true

module ::IsbfJoin
  class Assets
    ROOT = Pathname.new(File.expand_path("../../web", __dir__))
    CONTENT_TYPES = {
      ".avif" => "image/avif",
      ".css" => "text/css; charset=utf-8",
      ".gif" => "image/gif",
      ".glb" => "model/gltf-binary",
      ".html" => "text/html; charset=utf-8",
      ".js" => "text/javascript; charset=utf-8",
      ".jpeg" => "image/jpeg",
      ".jpg" => "image/jpeg",
      ".json" => "application/json; charset=utf-8",
      ".md" => "text/plain; charset=utf-8",
      ".png" => "image/png",
      ".svg" => "image/svg+xml",
      ".txt" => "text/plain; charset=utf-8",
      ".wasm" => "application/wasm",
      ".webp" => "image/webp",
      ".woff2" => "font/woff2",
    }.freeze

    def self.find(path)
      entry = manifest[path]
      return if !entry
      file = ROOT.join(entry.fetch("file")).realpath
      return if !file.to_s.start_with?("#{ROOT.realpath}/") || !file.file?
      {
        file: file.to_s,
        type: CONTENT_TYPES.fetch(file.extname, "application/octet-stream"),
        sha256: entry.fetch("sha256"),
      }
    rescue Errno::ENOENT
      nil
    end

    def self.manifest
      @manifest ||= JSON.parse(ROOT.join("asset-manifest.json").read)
    end
    private_class_method :manifest
  end
end
