# frozen_string_literal: true

require "open3"
require "tempfile"
require "tmpdir"

module IsbfResumeSharingSpecHelpers
  def with_sharing_environment(values)
    original = values.keys.to_h { |name| [name, ENV[name]] }
    values.each { |name, value| ENV[name] = value }
    yield
  ensure
    original.each { |name, value| ENV[name] = value }
  end

  def sharing_pdf_upload(filename: "shared-resume.pdf", pages: 1, encrypted: false, width: 595)
    tempfile = Tempfile.new(%w[resume-sharing- .pdf], @sharing_fixture_directory)
    (@sharing_uploads ||= []) << tempfile
    program = <<~PYTHON
      import sys
      from pypdf import PdfWriter
      writer = PdfWriter()
      for number in range(int(sys.argv[2])):
          writer.add_blank_page(width=float(sys.argv[4]), height=842)
      if sys.argv[3] == "true":
          writer.encrypt("test-only-password")
      with open(sys.argv[1], "wb") as output:
          writer.write(output)
    PYTHON
    _output, error, status =
      Open3.capture3(
        ENV.fetch("ISBF_RESUME_PYTHON", "/opt/resume-venv/bin/python"),
        "-I",
        "-c",
        program,
        tempfile.path,
        pages.to_s,
        encrypted.to_s,
        width.to_s,
      )
    raise "Synthetic PDF fixture failed: #{error}" unless status.success?
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: filename,
      type: "application/pdf",
    )
  end

  def sharing_raw_upload(content:, filename: "shared-resume.pdf", content_type: "application/pdf")
    tempfile = Tempfile.new(["resume-sharing-", File.extname(filename)], @sharing_fixture_directory)
    (@sharing_uploads ||= []) << tempfile
    tempfile.binmode
    tempfile.write(content)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: filename,
      type: content_type,
    )
  end

  def sharing_request_upload(**options)
    upload = sharing_pdf_upload(**options)
    Rack::Test::UploadedFile.new(
      upload.path,
      upload.content_type,
      true,
      original_filename: upload.original_filename,
    )
  end

  def sharing_image_upload(filename: "preview.png", format: "PNG")
    tempfile = Tempfile.new(["resume-sharing-", File.extname(filename)], @sharing_fixture_directory)
    (@sharing_uploads ||= []) << tempfile
    program = <<~PYTHON
      import sys
      from PIL import Image
      image = Image.new("RGB", (80, 120), (40, 80, 120))
      image.save(sys.argv[1], format=sys.argv[2])
    PYTHON
    _output, error, status =
      Open3.capture3(
        ENV.fetch("ISBF_RESUME_PYTHON", "/opt/resume-venv/bin/python"),
        "-I",
        "-c",
        program,
        tempfile.path,
        format,
      )
    raise "Synthetic image fixture failed: #{error}" unless status.success?
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: filename,
      type: "image/#{format == "JPEG" ? "jpeg" : format.downcase}",
    )
  end

  def sharing_request_image_upload(**options)
    upload = sharing_image_upload(**options)
    Rack::Test::UploadedFile.new(
      upload.path,
      upload.content_type,
      true,
      original_filename: upload.original_filename,
    )
  end

  def materialize_shared_pdf(shared_resume)
    stored_pdf = IsbfResume::SharedPdf.store(sharing_pdf_upload)
    shared_resume.update!(
      storage_key: stored_pdf.key,
      file_sha256: stored_pdf.sha256,
      file_bytes: stored_pdf.bytes,
      pages: stored_pdf.pages,
    )
    shared_resume
  end

  def materialize_shared_preview(shared_resume)
    preview = IsbfResume::SharedPdf.store_preview(images: [sharing_image_upload])
    shared_resume.update!(
      storage_key: preview.key,
      file_sha256: preview.sha256,
      file_bytes: preview.bytes,
      pages: preview.pages,
    )
    shared_resume
  end
end

RSpec.shared_context "with private shared resume storage" do
  include IsbfResumeSharingSpecHelpers

  around do |example|
    Dir.mktmpdir("isbf-resume-sharing-spec-") do |directory|
      @sharing_fixture_directory = directory
      storage = File.join(directory, "shares")
      Dir.mkdir(storage, 0o700)
      with_sharing_environment("ISBF_RESUME_SHARING_STORAGE_PATH" => storage) { example.run }
    ensure
      @sharing_uploads&.each(&:close!)
    end
  end
end

RSpec.shared_context "with resume review permissions" do
  fab!(:sharing_official_group, :group)
  fab!(:sharing_official_category, :category)

  before do
    SiteSetting.isbf_resume_enabled = true
    SiteSetting.academy_official_group = sharing_official_group.id
    SiteSetting.academy_official_category = sharing_official_category.id
    SiteSetting.academy_roles_enabled = true
    SiteSetting.academy_moderators_review_resumes = false
  end
end
