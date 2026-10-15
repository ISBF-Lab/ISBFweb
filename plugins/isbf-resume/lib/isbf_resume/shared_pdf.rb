# frozen_string_literal: true

require "fileutils"
require "open3"
require "securerandom"
require "timeout"

module IsbfResume
  class SharedPdf
    class InvalidPdf < StandardError
      REASONS = %w[
        invalid_pdf
        pdf_too_large
        pdf_encrypted
        pdf_too_many_pages
        pdf_validation_failed
        pdf_validation_timeout
      ].freeze

      attr_reader :reason

      def initialize(reason = "invalid_pdf")
        @reason = REASONS.include?(reason.to_s) ? reason.to_s : "invalid_pdf"
        super(@reason)
      end
    end

    class PreviewUnavailable < StandardError
    end

    MAX_BYTES = 10.megabytes
    MAX_PAGES = 100
    VALIDATION_TIMEOUT = 10
    PREVIEW_TIMEOUT = 25
    STORAGE_KEY = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
    PNG_SIGNATURE = "\x89PNG\r\n\x1a\n".b.freeze

    attr_reader :key, :pages, :filename_title, :sha256, :bytes

    def self.storage_path
      File.expand_path(
        ENV.fetch("ISBF_RESUME_SHARING_STORAGE_PATH", "/shared/isbf-resume-shares-private"),
      )
    end

    def self.store(upload)
      unless upload.is_a?(ActionDispatch::Http::UploadedFile) &&
               File.extname(upload.original_filename.to_s).casecmp?(".pdf") && upload.size.positive?
        raise InvalidPdf
      end
      raise InvalidPdf.new("pdf_too_large") if upload.size > MAX_BYTES
      upload.rewind
      raise InvalidPdf unless upload.read(5) == "%PDF-"
      upload.rewind

      FileUtils.mkdir_p(storage_path, mode: 0o700)
      raise InvalidPdf if File.symlink?(storage_path)
      pdf = new(key: SecureRandom.uuid)
      Dir.mkdir(pdf.directory, 0o700)
      File.open(pdf.pdf_path, "wx", 0o600) { |output| IO.copy_stream(upload.tempfile, output) }
      pdf.inspect_pdf!(upload.original_filename)
      pdf
    rescue StandardError
      pdf&.discard!
      raise
    end

    def initialize(key:, pages: nil)
      raise InvalidPdf unless STORAGE_KEY.match?(key.to_s)
      @key = key
      @pages = pages
    end

    def directory
      File.join(self.class.storage_path, key)
    end

    def pdf_path
      File.join(directory, "resume.pdf")
    end

    def available_path
      return if File.symlink?(directory) || File.symlink?(pdf_path)
      pdf_path if File.file?(pdf_path) && File.size?(pdf_path)
    end

    def preview_path(page)
      number = page.to_s
      return unless /\A[1-9]\d{0,2}\z/.match?(number) && pages && number.to_i <= pages
      path = File.join(directory, "preview-#{number}.png")
      return if File.symlink?(directory) || File.symlink?(path)
      return unless File.file?(path) && File.size?(path)
      path if File.binread(path, 8) == PNG_SIGNATURE
    rescue Errno::ENOENT
      nil
    end

    def inspect_pdf!(filename)
      manifest, success = run_processor(timeout: VALIDATION_TIMEOUT)
      raise InvalidPdf.new(manifest.fetch("error", "pdf_validation_failed")) unless success
      @pages = manifest["pages"]
      raise InvalidPdf unless pages.is_a?(Integer) && pages.between?(1, MAX_PAGES)
      @bytes = File.size(pdf_path)
      @sha256 = Digest::SHA256.file(pdf_path).hexdigest
      @filename_title =
        File
          .basename(filename.to_s.tr("\\", "/"))
          .sub(/\.pdf\z/i, "")
          .gsub(/[[:cntrl:]]/, "")
          .strip
          .first(200)
    rescue Timeout::Error
      raise InvalidPdf.new("pdf_validation_timeout")
    rescue Errno::ENOENT, JSON::ParserError, TypeError
      raise InvalidPdf.new("pdf_validation_failed")
    end

    def render_preview!(page)
      number = page.to_s
      return unless /\A[1-9]\d{0,2}\z/.match?(number) && pages && number.to_i <= pages
      return unless available_path
      cached = preview_path(number)
      return cached if cached

      lock_path = File.join(self.class.storage_path, ".preview.lock")
      File.open(lock_path, File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
        raise PreviewUnavailable unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        cached = preview_path(number)
        return cached if cached
        temporary = File.join(directory, "render-#{SecureRandom.hex(16)}.png")
        manifest, success =
          run_processor("--page", number, "--output", temporary, timeout: PREVIEW_TIMEOUT)
        unless success && manifest["page"] == number.to_i && File.file?(temporary) &&
                 !File.symlink?(temporary) && File.binread(temporary, 8) == PNG_SIGNATURE
          raise PreviewUnavailable
        end
        File.rename(temporary, File.join(directory, "preview-#{number}.png"))
        preview_path(number)
      ensure
        File.unlink(temporary) if temporary && File.file?(temporary) && !File.symlink?(temporary)
      end
    rescue Timeout::Error, Errno::ENOENT, JSON::ParserError, TypeError
      raise PreviewUnavailable
    end

    def discard!
      return if File.symlink?(directory) || !File.directory?(directory)
      names =
        ["resume.pdf"] +
          (1..MAX_PAGES).flat_map do |page|
            [
              "preview-#{page}.png",
              "page-#{page}.png",
              "page-#{page.to_s.rjust(2, "0")}.png",
              "page-#{page.to_s.rjust(3, "0")}.png",
            ]
          end
      names.uniq.each do |name|
        path = File.join(directory, name)
        File.unlink(path) if File.file?(path) && !File.symlink?(path)
      end
      Dir.rmdir(directory) if Dir.empty?(directory)
    end

    private

    def run_processor(*arguments, timeout:)
      script = File.expand_path("../../shared_pdf.py", __dir__)
      python = ENV.fetch("ISBF_RESUME_PYTHON", "/opt/resume-venv/bin/python")
      output = nil
      status = nil
      Open3.popen3(
        python,
        "-I",
        script,
        directory,
        *arguments,
        pgroup: true,
        umask: 0o077,
      ) do |stdin, stdout, stderr, process|
        stdin.close
        readers = [
          Thread.new { stdout.read(16.kilobytes) },
          Thread.new { stderr.read(16.kilobytes) },
        ]
        begin
          Timeout.timeout(timeout) do
            output = readers.first.value
            readers.last.value
            status = process.value
          end
        rescue Timeout::Error
          begin
            Process.kill("KILL", -process.pid)
          rescue Errno::ESRCH
          end
          raise
        ensure
          readers.each(&:kill)
        end
      end
      [JSON.parse(output), status.success?]
    end
  end
end
