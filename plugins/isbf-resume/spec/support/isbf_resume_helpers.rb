# frozen_string_literal: true

require "base64"
require "tmpdir"

module IsbfResumeSpecHelpers
  PNG_FIXTURE =
    Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC"
    ).freeze

  def with_resume_environment(values)
    original = values.keys.to_h { |name| [name, ENV[name]] }
    values.each { |name, value| ENV[name] = value }
    yield
  ensure
    original.each { |name, value| ENV[name] = value }
  end

  def create_downloadable_resume(owner:, template: "blue-gold", pages: 1)
    export = IsbfResume::Export.create(owner_id: owner.id, resume: resume)
    previews = write_resume_file_fixtures(export, template:, pages:)
    export.complete!(
      "template" => template,
      "pages" => pages,
      "preview_files" => previews
    )
    File.unlink(export.input_path)
    export
  end

  def write_resume_file_fixtures(export, template: "blue-gold", pages: 1)
    File.binwrite(
      File.join(export.directory, "resume-#{template}.docx"),
      "PK\x03\x04private docx fixture"
    )
    File.binwrite(
      File.join(export.directory, "resume-#{template}.pdf"),
      "%PDF-1.7\nprivate pdf fixture"
    )
    (1..pages).map do |page|
      filename = "preview-#{page}.png"
      File.binwrite(File.join(export.directory, filename), PNG_FIXTURE)
      filename
    end
  end

  def write_resume_executable(name:, body:)
    path = File.join(IsbfResume::Export.storage_path, name)
    File.write(path, body, perm: 0o700)
    File.chmod(0o700, path)
    path
  end

  def resume_document_details(export)
    program = <<~PYTHON
      import hashlib, json, sys
      from xml.etree import ElementTree
      from zipfile import ZipFile
      from pypdf import PdfReader
      from pathlib import Path
      from PIL import Image
      with ZipFile(sys.argv[1]) as document:
          root = ElementTree.fromstring(document.read("word/document.xml"))
          text = "\\n".join(node.text or "" for node in root.iter() if node.tag.endswith("}t"))
          accents = sorted({value for node in root.iter() for value in node.attrib.values() if value in {"C19F67", "A5A5A5"}})
          parts = {name: hashlib.sha256(document.read(name).replace(b"C19F67", b"A5A5A5")).hexdigest() for name in document.namelist()}
      pdf = PdfReader(sys.argv[2])
      previews = []
      for page in range(1, len(pdf.pages) + 1):
          path = Path(sys.argv[3]) / f"preview-{page}.png"
          with Image.open(path) as image:
              image.verify()
          with Image.open(path) as image:
              extrema = image.convert("RGB").getextrema()
              previews.append({"filename": path.name, "format": image.format, "size": image.size, "nonblank": any(low != high for low, high in extrema), "signature": path.read_bytes()[:8].hex()})
      print(json.dumps({"docx_text": text, "pdf_text": "\\n".join(page.extract_text() or "" for page in pdf.pages), "pdf_pages": len(pdf.pages), "parts": parts, "accents": accents, "previews": previews, "png_names": sorted(path.name for path in Path(sys.argv[3]).glob("preview-*.png"))}))
    PYTHON
    output, error, status =
      Open3.capture3(
        ENV.fetch("ISBF_RESUME_PYTHON", "/opt/resume-venv/bin/python"),
        "-c",
        program,
        export.file_path("docx"),
        export.file_path("pdf"),
        export.directory
      )
    raise "Document inspection failed: #{error}" unless status.success?
    JSON.parse(output)
  end
end

RSpec.shared_context "with private resume storage" do
  include IsbfResumeSpecHelpers

  let(:resume) do
    {
      "version" => 1,
      "template" => "blue-gold",
      "basic" => {
        "name" => "测试候选人",
        "phone" => "+86 138 0000 0000",
        "email" => "resume-spec@example.com"
      }
    }
  end

  around do |example|
    Dir.mktmpdir("isbf-resume-spec-") do |directory|
      with_resume_environment("ISBF_RESUME_STORAGE_PATH" => directory) do
        example.run
      end
    end
  end
end
