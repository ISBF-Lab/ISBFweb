# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentInviteCsv do
  describe ".new" do
    it "accepts optional English or Chinese headers and a UTF-8 BOM without losing leading zeroes" do
      [
        "",
        "student_number\r\n",
        "学号\r\n",
        " STUDENT_NUMBER \r\n"
      ].each do |header|
        ["", Encodings::BOM].each do |bom|
          csv =
            described_class.new(
              StringIO.new("#{bom}#{header} 000123 \r\n002345\r\n")
            )

          expect(csv.rows).to eq(
            [
              { student_number: "000123", column_count: 1 },
              { student_number: "002345", column_count: 1 }
            ]
          )
        end
      end
    end

    it "accepts exactly 1500 data rows in addition to the header" do
      csv = described_class.new(StringIO.new("学号\n" + "000123\n" * 1500))

      expect(csv.rows.size).to eq(1500)
    end

    it "rejects empty files, files containing only a header, and more than 1500 data rows" do
      [
        "",
        Encodings::BOM,
        "student_number\n",
        "学号\n" + "000123\n" * 1501
      ].each do |content|
        expect { described_class.new(StringIO.new(content)) }.to raise_error(
          described_class::InvalidFile
        )
      end
    end

    it "rejects invalid encoding, malformed CSV, and a file exceeding one megabyte" do
      ["\xFF".b, "\"unterminated\n", "0" * (1.megabyte + 1)].each do |content|
        expect { described_class.new(StringIO.new(content)) }.to raise_error(
          described_class::InvalidFile
        )
      end
    end

    it "rewinds an already-read upload before parsing" do
      file = StringIO.new("000123\n")
      file.read

      expect(described_class.new(file).rows).to eq(
        [{ student_number: "000123", column_count: 1 }]
      )
    end
  end

  describe "#row_error" do
    it "identifies blank, multiple-column and overlong rows while accepting quoted student numbers" do
      csv =
        described_class.new(
          StringIO.new(
            "\n\" \"\n0001,extra\n#{"1" * 65}\n\"0001,quoted\"\n#{"2" * 64}\n"
          )
        )

      expect(csv.rows.map { |row| csv.row_error(row) }).to eq(
        [
          I18n.t("academy_roles.student_invites.bulk.missing_student_number"),
          I18n.t("academy_roles.student_invites.bulk.missing_student_number"),
          I18n.t("academy_roles.student_invites.bulk.single_column_required"),
          I18n.t("academy_roles.student_invites.bulk.student_number_too_long"),
          nil,
          nil
        ]
      )
    end
  end

  describe "#to_csv" do
    fab!(:registration, :academy_student_registration)

    it "exports translated Chinese headers, ordered results, quoted cells, a BOM and CRLF" do
      csv = described_class.new(StringIO.new("000123\n000124\n000125\n"))
      reason = "重复,\"学号\"\n请核对"
      csv.record(csv.rows[0], status: :created, registration:)
      csv.record(csv.rows[1], status: :skipped, reason:)
      csv.record(csv.rows[2], status: :failed, reason:)

      I18n.with_locale(:zh_CN) do
        output = csv.to_csv
        exported = CSV.parse(output.delete_prefix(Encodings::BOM))

        expect(output).to start_with(Encodings::BOM + '"学号","邀请码"')
        expect(output).to end_with("\r\n")
        expect(exported.first).to eq(%w[学号 邀请码 邀请链接 到期时间（UTC） 处理结果 原因])
        expect(exported.drop(1).map(&:first)).to eq(%w[000123 000124 000125])
        expect(exported[1]).to eq(
          [
            "000123",
            registration.invite.invite_key,
            registration.invite.link,
            registration.invite.expires_at.iso8601,
            "已生成",
            ""
          ]
        )
        expect(exported[2]).to eq(["000124", "", "", "", "已跳过", reason])
        expect(exported[3]).to eq(["000125", "", "", "", "失败", reason])
        expect([csv.created_count, csv.skipped_count, csv.failed_count]).to eq(
          [1, 1, 1]
        )
      end
    end

    it "escapes spreadsheet formula prefixes in every exported cell" do
      csv = described_class.new(StringIO.new("000123\n"))
      prefixes = ["=", "+", "-", "@", "\t", "\r", "\n"]
      prefixes.each do |prefix|
        csv.record(
          { student_number: "#{prefix}001", column_count: 1 },
          status: :failed,
          reason: "#{prefix}reason"
        )
      end

      exported = CSV.parse(csv.to_csv.delete_prefix(Encodings::BOM)).drop(1)

      expect(exported.map(&:first)).to eq(
        prefixes.map { |prefix| "'#{prefix}001" }
      )
      expect(exported.map(&:last)).to eq(
        prefixes.map { |prefix| "'#{prefix}reason" }
      )
    end
  end
end

RSpec.describe DiscourseAcademyRoles::StudentInviteBatchSerializer do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)

  describe "#as_json" do
    it "exposes the export only to an administrator even outside the controller" do
      csv =
        DiscourseAcademyRoles::StudentInviteCsv.new(StringIO.new("000123\n"))
      csv.record(csv.rows.first, status: :failed)

      expect(
        described_class.new(csv, scope: admin.guardian, root: false).as_json
      ).to include(csv: csv.to_csv, failed_count: 1)
      [moderator.guardian, member.guardian, Guardian.new, nil].each do |scope|
        expect(
          described_class.new(csv, scope:, root: false).as_json
        ).not_to have_key(:csv)
      end
    end
  end
end
