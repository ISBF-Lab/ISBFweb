# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentGroups::Input do
  describe ".new" do
    it "preserves literal identifiers and reports duplicate list entries" do
      input = described_class.new(kind: "list", student_numbers: "000123, 123；000123\nA_26;B%26")

      expect(input.numbers).to eq(%w[000123 123 A_26 B%26])
      expect(input.duplicate_count).to eq(1)
    end

    it "accepts 1500 rows and rejects larger lists before deduplication" do
      expect(described_class.new(kind: "list", student_numbers: "000123\n" * 1500).numbers).to eq(
        ["000123"],
      )
      expect do
        described_class.new(kind: "list", student_numbers: "000123\n" * 1501)
      end.to raise_error(DiscourseAcademyRoles::StudentGroups::Error)
    end

    it "rejects blank inputs, unknown formats, and oversized text" do
      [
        { kind: "list", student_numbers: " \n " },
        { kind: "unknown", student_numbers: "000123" },
        { kind: "list", student_numbers: "0" * (1.megabyte + 1) },
      ].each do |parameters|
        expect { described_class.new(**parameters) }.to raise_error(
          DiscourseAcademyRoles::StudentGroups::Error,
        )
      end
    end

    it "reads BOM and Chinese CSV headers while retaining leading zeroes" do
      upload =
        ActionDispatch::Http::UploadedFile.new(
          tempfile:
            file_from_contents("\uFEFF学号\r\n000123\r\n000123\r\n002345\r\n", "students.csv"),
          filename: "STUDENTS.CSV",
          type: "text/csv",
        )

      input = described_class.new(kind: "csv", file: upload)

      expect(input.numbers).to eq(%w[000123 002345])
      expect(input.duplicate_count).to eq(1)
    end

    it "rejects invalid CSV encoding, malformed quoting, extra columns and excessive rows" do
      [
        "\xFF".b,
        "\"unfinished\n",
        "000123,extra\n",
        "student_number\n" + "000123\n" * 1501,
        "0" * (1.megabyte + 1),
      ].each do |content|
        Tempfile.create(%w[students .csv], binmode: true) do |file|
          file.write(content)
          file.rewind
          upload =
            ActionDispatch::Http::UploadedFile.new(
              tempfile: file,
              filename: "students.csv",
              type: "text/csv",
            )

          expect { described_class.new(kind: "csv", file: upload) }.to raise_error(
            DiscourseAcademyRoles::StudentGroups::Error,
          )
        end
      end
    end

    it "rejects the whole prefix result when more than the allowed batch would match" do
      3.times do |index|
        Fabricate(:academy_student_registration, student_number: "overflow-#{index}")
      end
      stub_const(DiscourseAcademyRoles::StudentGroups, :MAX_ROWS, 2) do
        expect { described_class.new(kind: "prefix", prefix: "overflow-") }.to raise_error(
          DiscourseAcademyRoles::StudentGroups::Error,
        ) { |error| expect(error.code).to eq("too_many") }
      end
    end

    it "matches SQL wildcard characters in prefixes literally" do
      literal = Fabricate(:academy_student_registration, student_number: "2026_%001")
      Fabricate(:academy_student_registration, student_number: "2026AB001")
      Fabricate(:academy_student_registration, student_number: "2026_Z001")

      expect(described_class.new(kind: "prefix", prefix: "2026_%").numbers).to eq(
        [literal.student_number],
      )
    end
  end

  describe ".valid_number?" do
    it "accepts literal strings within the identifier limit and rejects control characters" do
      ["000123", "123", "2026_%", "0" * 64].each do |number|
        expect(described_class.valid_number?(number)).to eq(true)
      end
      [nil, "", "0" * 65, "000\u0000123", "000\u200B123"].each do |number|
        expect(described_class.valid_number?(number)).to eq(false)
      end
    end
  end
end
