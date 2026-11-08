# frozen_string_literal: true

require "base64"
require "compression/safe_zip_reader"
require "uri"

module ::IsbfGuides
  class DocumentPackage
    MAX_UPLOAD_BYTES = 10.megabytes
    MAX_EXPANDED_BYTES = 50.megabytes
    MAX_ENTRIES = 500
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .webp .gif].freeze
    Asset =
      Struct.new(:data, :extension, keyword_init: true) do
        def sha256
          @sha256 ||= Digest::SHA256.hexdigest(data)
        end
      end

    attr_reader :html, :image_sources

    def self.accepts?(file)
      file.is_a?(ActionDispatch::Http::UploadedFile) && file.size.positive? &&
        file.size <= MAX_UPLOAD_BYTES &&
        File.extname(file.original_filename.to_s).downcase.in?(%w[.html .htm .zip])
    end

    def self.read(file:)
      new(file:).read
    end

    def initialize(file:)
      @file = file
      @assets = {}
      @expanded_bytes = 0
    end

    def read
      raise DocumentError.new(:invalid_file) unless self.class.accepts?(@file)
      @file.rewind
      if File.extname(@file.original_filename).downcase == ".zip"
        read_zip
      else
        prepare_html(@file.read(MAX_UPLOAD_BYTES + 1))
        collect_assets
      end
      self
    rescue Zip::Error, Compression::SafeZipReader::Error
      raise DocumentError.new(:invalid_archive)
    end

    def asset_for(source)
      @assets[source]
    end

    def html_with_images(mapping)
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css("img").each { |image| image["src"] = mapping.fetch(image["src"]) }
      fragment.to_html
    end

    private

    def read_zip
      Compression::SafeZipReader.open(
        @file.tempfile.path,
        max_entries: MAX_ENTRIES,
        max_total_bytes: MAX_EXPANDED_BYTES,
      ) do |reader|
        entries = reader.entries.reject(&:directory?)
        reader.entries.each do |entry|
          normalize_path(entry.name.delete_suffix("/"))
          raise DocumentError.new(:invalid_archive) if entry.symlink?
        end
        if entries.sum { |entry| entry.size.to_i } > MAX_EXPANDED_BYTES
          raise DocumentError.new(:too_large)
        end
        visible =
          entries.reject do |entry|
            entry.name.split("/").any? { |part| part.start_with?(".") || part == "__MACOSX" }
          end
        candidates =
          visible.select { |entry| File.extname(entry.name).downcase.in?(%w[.html .htm]) }
        primary = reader.find_entry("index.html")
        primary = candidates.first if primary.nil? && candidates.length == 1
        raise DocumentError.new(:missing_html) unless primary && candidates.include?(primary)
        base = File.dirname(normalize_path(primary.name))
        base = "" if base == "."
        indexed = visible.index_by { |entry| normalize_path(entry.name) }
        raise DocumentError.new(:invalid_archive) unless indexed.size == visible.size
        prepare_html(reader.read_entry(primary, max_bytes: MAX_UPLOAD_BYTES, required: true))
        cache = {}
        collect_assets do |path|
          full_path = [base.presence, path].compact.join("/")
          entry = indexed[full_path]
          next unless entry
          cache[full_path] ||= reader.read_entry(entry, max_bytes: MAX_UPLOAD_BYTES, required: true)
        end
      end
    end

    def prepare_html(bytes)
      text = bytes.dup.force_encoding(Encoding::UTF_8)
      raise DocumentError.new(:encoding) unless text.valid_encoding?
      document = Nokogiri.HTML5(text)
      root =
        document.at_css("[data-guide-content]") || document.at_css("main") ||
          document.at_css("body")
      raise DocumentError.new(:empty) unless root
      fragment = DocumentMarkup.clean(root.inner_html)
      fragment.at_css("h1")&.remove
      fragment.css("h1").each { |heading| heading.name = "h2" }
      raise DocumentError.new(:empty) if fragment.text.strip.empty? && fragment.css("img").empty?
      @html = fragment.to_html
      @image_sources = fragment.css("img").map { |image| image["src"].to_s }.uniq
    end

    def collect_assets
      image_sources.each do |source|
        if source.start_with?("data:")
          @assets[source] = embedded_asset(source)
          next
        end
        path = image_path(source)
        data = yield(path) if block_given?
        if data
          extension = File.extname(path).downcase
          raise DocumentError.new(:invalid_image, path:) unless extension.in?(IMAGE_EXTENSIONS)
          @assets[source] = Asset.new(data:, extension:)
        elsif !source.match?(%r{\A/guides/[a-z0-9-]+/images/[a-zA-Z0-9._-]+\z})
          raise DocumentError.new(:missing_image, path:)
        end
      end
      @expanded_bytes += @assets.values.sum { |asset| asset.data.bytesize }
      raise DocumentError.new(:too_large) if @expanded_bytes > MAX_EXPANDED_BYTES
    end

    def embedded_asset(source)
      match = source.match(%r{\Adata:image/(png|jpeg|gif|webp);base64,([A-Za-z0-9+/=\r\n]+)\z})
      raise DocumentError.new(:invalid_image, path: "data:image") unless match
      bytes = Base64.strict_decode64(match[2].delete("\r\n"))
      raise DocumentError.new(:too_large) if bytes.bytesize > MAX_UPLOAD_BYTES
      Asset.new(data: bytes, extension: ".#{match[1] == "jpeg" ? "jpg" : match[1]}")
    rescue ArgumentError
      raise DocumentError.new(:invalid_image, path: "data:image")
    end

    def image_path(source)
      if source.empty? || source.start_with?("//") || source.match?(/\A[a-zA-Z][a-zA-Z0-9+.-]*:/)
        raise DocumentError.new(:image_source)
      end
      path = URI::DEFAULT_PARSER.unescape(source.split(/[?#]/, 2).first)
      path = path.sub(%r{\A/guides/[a-z0-9-]+/images/}, "images/").delete_prefix("/")
      normalize_path(path)
    end

    def normalize_path(path)
      if path.empty? || path.start_with?("/") || path.include?("\\") || path.include?("\0") ||
           path.split("/").include?("..") || path.match?(/\A[A-Za-z]:/)
        raise DocumentError.new(:invalid_path)
      end
      normalized = path.split("/").reject { |part| part.empty? || part == "." }.join("/")
      raise DocumentError.new(:invalid_path) if normalized.empty?
      normalized
    end
  end
end
