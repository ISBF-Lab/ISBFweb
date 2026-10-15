# frozen_string_literal: true

require_relative "../support/isbf_resume_helpers"

RSpec.describe IsbfResume::Generator do
  include_context "with private resume storage"

  describe ".call" do
    subject(:generate) { described_class.call(export) }

    fab!(:owner, :user)
    let(:export) { IsbfResume::Export.create(owner_id: owner.id, resume:) }

    context "when content is valid" do
      let(:resume) do
        super().merge(
          "projects" => [
            {
              "name" => "A & B <项目>",
              "details" => "第一行保留用户原文 & 50%\n第二行含中英文 GitHub"
            }
          ],
          "summary" => {
            "text" => "用户自述：不是系统生成的评价。"
          }
        )
      end

      it "generates valid DOCX and PDF while preserving the supplied words" do
        generate
        details = resume_document_details(export)
        expect(export).to be_available
        expect(details["pdf_pages"]).to eq(export.pages)
        expect(details["previews"].length).to eq(export.pages)
        expect(details["previews"].map { |page| page["format"] }).to all(
          eq("PNG")
        )
        expect(details["previews"].map { |page| page["signature"] }).to all(
          eq("89504e470d0a1a0a")
        )
        expect(details["previews"].map { |page| page["nonblank"] }).to all(
          eq(true)
        )
        expect(details["docx_text"]).to include(
          resume["projects"].first["name"],
          "第一行保留用户原文 & 50%",
          "第二行含中英文 GitHub",
          resume["summary"]["text"]
        )
        expect(details["pdf_text"]).to include("A & B", "GitHub")
        expect(File.exist?(export.input_path)).to eq(false)
      end

      it "keeps both template packages identical except for their accent color" do
        generate
        gray =
          IsbfResume::Export.create(
            owner_id: owner.id,
            resume: resume.merge("template" => "blue-gray")
          )
        described_class.call(gray)
        gold_details = resume_document_details(export)
        gray_details = resume_document_details(gray)
        expect(gray.template).to eq("blue-gray")
        expect(gold_details["accents"]).to contain_exactly("C19F67")
        expect(gray_details["accents"]).to contain_exactly("A5A5A5")
        expect(gray_details["parts"]).to eq(gold_details["parts"])
        expect(gray_details["pdf_pages"]).to eq(gold_details["pdf_pages"])
      end
    end

    context "when English document headings are requested" do
      let(:resume) do
        super().merge(
          "language" => "en",
          "projects" => [
            {
              "name" => "Portfolio project",
              "details" => "Original wording & 50%\n用户提供的原文"
            }
          ]
        )
      end

      it "generates English DOCX and PDF labels while retaining the supplied text" do
        generate
        details = resume_document_details(export)

        expect(export).to be_available
        expect(details["docx_text"]).to include(
          "Personal information",
          "Name: ",
          "Projects and research",
          "Portfolio project",
          "Original wording & 50%",
          "用户提供的原文",
          resume["basic"]["name"]
        )
        expect(details["pdf_text"]).to include(
          "Personal information",
          "Projects and research",
          "Original wording"
        )
        expect(details["previews"].length).to eq(details["pdf_pages"])
        expect(File.exist?(export.input_path)).to eq(false)
      end
    end

    context "when the resume spans multiple PDF pages" do
      let(:resume) do
        details =
          (1..60).map { |line| "用户填写第#{line}行：保留内容 & #{line}%" }.join("\n")
        super().merge(
          "projects" => [
            { "name" => "项目一", "details" => details },
            { "name" => "项目二", "details" => details }
          ]
        )
      end

      it "renders a valid nonblank PNG for every actual PDF page" do
        generate
        details = resume_document_details(export)
        expect(export.pages).to be > 1
        expect(details["pdf_pages"]).to eq(export.pages)
        expected_files = (1..export.pages).map { |page| "preview-#{page}.png" }
        expect(export.preview_files).to eq(expected_files)
        expect(details["png_names"]).to eq(expected_files.sort)
        expect(details["previews"].map { |page| page["filename"] }).to eq(
          expected_files
        )
        expect(details["previews"].map { |page| page["nonblank"] }).to all(
          eq(true)
        )
        expect(details["previews"].map { |page| page["signature"] }).to all(
          eq("89504e470d0a1a0a")
        )
        expect(File.exist?(export.input_path)).to eq(false)
      end
    end

    context "when imported content includes unknown fields" do
      let(:resume) { super().merge("patents" => [{ "name" => "未支持的专利原文" }]) }

      it "rejects rather than discarding the content" do
        expect { generate }.to raise_error(
          described_class::InvalidResume
        ) do |error|
          expect(error.field_errors.keys).to contain_exactly("document")
        end
        expect(File.exist?(export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end

    context "when a nested field is unknown" do
      let(:resume) do
        super().deep_merge("basic" => { "unexpected" => "必须被拒绝的原文" })
      end

      it "returns the field path without publishing a partial export" do
        expect { generate }.to raise_error(
          described_class::InvalidResume
        ) do |error|
          expect(error.field_errors.keys).to include("basic")
        end
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end

    context "when the photo or link is unsafe" do
      let(:resume) do
        super().deep_merge(
          "basic" => {
            "photo" => "data:image/svg+xml;base64,PHN2Zz4=",
            "linkedin" => "javascript:alert(1)"
          }
        )
      end

      it "reports both validation errors and removes the private input" do
        expect { generate }.to raise_error(
          described_class::InvalidResume
        ) do |error|
          expect(error.field_errors.keys).to contain_exactly(
            "basic.photo",
            "basic.linkedin"
          )
        end
        expect(File.exist?(export.input_path)).to eq(false)
      end
    end

    context "when the executable is missing" do
      around do |example|
        with_resume_environment(
          "ISBF_RESUME_PYTHON" =>
            File.join(IsbfResume::Export.storage_path, "missing-python")
        ) { example.run }
      end

      it "returns a bounded generation error and removes the input" do
        expect { generate }.to raise_error(described_class::GenerationError)
        expect(File.exist?(export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end

    context "when the executable returns malformed output" do
      around do |example|
        executable =
          write_resume_executable(
            name: "invalid-output",
            body:
              "#!/bin/sh\nprintf '%s' started > \"$0.started\"\nprintf '%s' 'invalid-json'\n"
          )
        with_resume_environment("ISBF_RESUME_PYTHON" => executable) do
          example.run
        end
      end

      it "rejects the output without publishing a download" do
        expect { generate }.to raise_error(described_class::GenerationError)
        expect(
          File.exist?(
            File.join(IsbfResume::Export.storage_path, "invalid-output.started")
          )
        ).to eq(true)
        expect(File.exist?(export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end

    context "when the executable exits unsuccessfully" do
      around do |example|
        executable =
          write_resume_executable(
            name: "failed-conversion",
            body:
              "#!/bin/sh\nprintf '%s' started > \"$0.started\"\nprintf '%s' '{}'\nexit 1\n"
          )
        with_resume_environment("ISBF_RESUME_PYTHON" => executable) do
          example.run
        end
      end

      it "rejects the failed conversion and clears its input" do
        expect { generate }.to raise_error(described_class::GenerationError)
        expect(
          File.exist?(
            File.join(
              IsbfResume::Export.storage_path,
              "failed-conversion.started"
            )
          )
        ).to eq(true)
        expect(File.exist?(export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end

    context "when the process exceeds its time limit" do
      around do |example|
        executable =
          write_resume_executable(name: "slow-conversion", body: <<~SHELL)
            #!/bin/sh
            /bin/sleep 30 &
            child=$!
            printf '{"parent":%s,"child":%s}' "$$" "$child" > "$4/processes.json"
            wait "$child"
          SHELL
        with_resume_environment("ISBF_RESUME_PYTHON" => executable) do
          stub_const(IsbfResume, :GENERATION_TIMEOUT, 1) { example.run }
        end
      end

      it "terminates the process group and removes the input" do
        expect { generate }.to raise_error(described_class::GenerationError)
        processes =
          JSON.parse(File.read(File.join(export.directory, "processes.json")))
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
        active_pids = []
        loop do
          active_pids =
            processes.values.select do |pid|
              path = "/proc/#{pid}/stat"
              begin
                File.read(path).split(") ").last.split.first != "Z"
              rescue Errno::ENOENT
                false
              end
            end
          if active_pids.empty? ||
               Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            break
          end
          sleep 0.01
        end
        expect(active_pids).to be_empty
        expect(File.exist?(export.input_path)).to eq(false)
        expect(IsbfResume::Export.find(export.id)).to eq(nil)
      end
    end
  end
end
