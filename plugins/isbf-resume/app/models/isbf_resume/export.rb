# frozen_string_literal: true

require "fileutils"
require "securerandom"

module IsbfResume
  class Export
    include ActiveModel::Serialization

    EXPORT_ID =
      /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
    FILE_TYPES = %w[docx pdf].freeze
    MAX_PAGES = 1000
    PREVIEW_PAGE = /\A[1-9]\d{0,3}\z/
    PNG_SIGNATURE = "\x89PNG\r\n\x1a\n".b.freeze

    attr_reader :id,
                :owner_id,
                :created_at,
                :pages,
                :template,
                :directory,
                :preview_files

    def self.storage_path
      ENV.fetch("ISBF_RESUME_STORAGE_PATH", "/shared/isbf-resume-private")
    end

    def self.create(owner_id:, resume:)
      FileUtils.mkdir_p(storage_path, mode: 0o700)
      id = SecureRandom.uuid
      directory = File.join(storage_path, id)
      Dir.mkdir(directory, 0o700)
      export = new(id:, owner_id:, created_at: Time.now.utc, directory:)
      File.write(
        export.input_path,
        JSON.generate(resume),
        mode: "wx",
        perm: 0o600
      )
      export
    end

    def self.find(export_id)
      return unless EXPORT_ID.match?(export_id.to_s)
      directory = File.join(storage_path, export_id)
      metadata = JSON.parse(File.read(File.join(directory, "metadata.json")))
      return unless metadata.is_a?(Hash)
      pages = metadata.fetch("pages")
      return unless pages.is_a?(Integer) && pages.between?(1, MAX_PAGES)
      export =
        new(
          id: export_id,
          owner_id: metadata.fetch("owner_id"),
          created_at: Time.iso8601(metadata.fetch("created_at")),
          directory:,
          pages:,
          template: metadata.fetch("template"),
          preview_files: metadata.fetch("preview_files", [])
        )
      return if metadata.key?("preview_files") && export.preview_count != pages
      export
    rescue Errno::ENOENT, JSON::ParserError, KeyError, ArgumentError
      nil
    end

    def initialize(
      id:,
      owner_id:,
      created_at:,
      directory:,
      pages: nil,
      template: nil,
      preview_files: []
    )
      @id = id
      @owner_id = owner_id
      @created_at = created_at
      @directory = directory
      @pages = pages
      @template = template
      @preview_files = preview_files
    end

    def input_path
      File.join(directory, "input.json")
    end

    def expires_at
      created_at + EXPORT_LIFETIME
    end

    def available?
      FILE_TYPES.all? { |type| file_path(type) } && expires_at > Time.now.utc
    end

    def file_path(file_type)
      if FILE_TYPES.exclude?(file_type) ||
           %w[blue-gold blue-gray].exclude?(template)
        return
      end
      path = File.join(directory, "resume-#{template}.#{file_type}")
      path if File.file?(path) && !File.symlink?(path) && File.size?(path)
    end

    def preview_count
      return 0 unless pages.is_a?(Integer) && pages.between?(1, MAX_PAGES)
      expected = (1..pages).map { |number| "preview-#{number}.png" }
      preview_files == expected ? pages : 0
    end

    def preview_path(page)
      return unless preview_count.positive? && available?
      number = page if page.is_a?(Integer)
      number = page.to_i if page.is_a?(String) && PREVIEW_PAGE.match?(page)
      return unless number && number.between?(1, pages)
      path = File.join(directory, "preview-#{number}.png")
      return unless File.file?(path) && !File.symlink?(path) && File.size?(path)
      path if File.binread(path, PNG_SIGNATURE.bytesize) == PNG_SIGNATURE
    rescue Errno::ENOENT
      nil
    end

    def complete!(manifest)
      @template = manifest.fetch("template")
      @pages = manifest.fetch("pages")
      @preview_files = manifest.fetch("preview_files", nil)
      unless pages.is_a?(Integer) && pages.between?(1, MAX_PAGES) &&
               available? && preview_count == pages &&
               (1..pages).all? { |number| preview_path(number) }
        raise Generator::GenerationError
      end
      File.write(
        File.join(directory, "metadata.json"),
        JSON.generate(
          owner_id:,
          created_at: created_at.iso8601,
          pages:,
          template:,
          preview_files:
        ),
        mode: "wx",
        perm: 0o600
      )
    end
  end
end
