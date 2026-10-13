# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles::StudentInvites::Action::IssueBatch do
  describe ".call" do
    subject(:result) do
      described_class.call(csv:, guardian: admin.guardian, expires_at:)
    end

    fab!(:admin)
    fab!(:official_group, :group)
    fab!(:official_category, :category)
    let(:csv) do
      DiscourseAcademyRoles::StudentInviteCsv.new(StringIO.new(content))
    end
    let(:content) { "000123\n000124\n" }
    let(:expires_at) { 2.days.from_now.iso8601 }

    before do
      SiteSetting.academy_official_group = official_group.id
      SiteSetting.academy_official_category = official_category.id
      SiteSetting.academy_roles_enabled = true
    end

    it "processes mixed rows in order while retaining all existing reservations and hiding their codes" do
      pending = Fabricate(:academy_student_registration)
      registered = Fabricate(:registered_academy_student)
      expired = Fabricate(:academy_student_registration)
      expired.invite.update!(expires_at: 1.day.ago)
      revoked = Fabricate(:academy_student_registration)
      revoked.invite.update!(invalidated_at: Time.current)
      registrations = [pending, registered, expired, revoked]
      reserved_identities =
        registrations.map do |registration|
          [
            registration.student_number,
            registration.invite_id,
            registration.invite.invite_key
          ]
        end
      content = [
        " 000123 ",
        "000123",
        "",
        "000124,extra",
        "x" * 65,
        *registrations.map(&:student_number),
        "000125"
      ].join("\n")
      csv = DiscourseAcademyRoles::StudentInviteCsv.new(StringIO.new(content))

      expect {
        described_class.call(csv:, guardian: admin.guardian, expires_at:)
      }.to change(Invite, :count).by(2)

      expect(csv.results.map { |row| row[:result] }).to eq(
        %i[
          created
          skipped
          failed
          failed
          failed
          skipped
          skipped
          skipped
          skipped
          created
        ]
      )
      expect(csv.results.map { |row| row[:student_number] }).to eq(
        [
          "000123",
          "000123",
          "",
          "000124",
          "x" * 65,
          *registrations.map(&:student_number),
          "000125"
        ]
      )
      expect([csv.created_count, csv.skipped_count, csv.failed_count]).to eq(
        [2, 5, 3]
      )
      csv
        .results
        .reject { |row| row[:result] == :created }
        .each do |row|
          expect(row.values_at(:invite_key, :link, :expires_at)).to eq(
            [nil, nil, nil]
          )
          expect(row[:reason]).to be_present
        end
      registrations.each do |registration|
        expect(csv.to_csv).not_to include(registration.invite.invite_key)
      end
      expect(
        registrations.map do |registration|
          [
            registration.reload.student_number,
            registration.invite_id,
            registration.invite.invite_key
          ]
        end
      ).to eq(reserved_identities)
      expect(registrations.map(&:status)).to eq(
        %w[pending registered expired revoked]
      )
    end

    it "rolls back a failed row's invitation and continues with the next row" do
      allow(DiscourseAcademyRoles::StudentRegistration).to receive(
        :create
      ).and_wrap_original do |original, attributes|
        if attributes[:student_number] == "000123"
          raise ActiveRecord::RecordNotUnique
        end
        original.call(attributes)
      end

      expect { result }.to change(Invite, :count).by(1).and change(
              DiscourseAcademyRoles::StudentRegistration,
              :count
            ).by(1)

      expect(csv.results.map { |row| row[:result] }).to eq(%i[failed created])
      expect(
        csv.results.first.values_at(:invite_key, :link, :expires_at)
      ).to eq([nil, nil, nil])
      expect(
        DiscourseAcademyRoles::StudentRegistration.where(
          student_number: "000123"
        )
      ).not_to exist
      expect(
        DiscourseAcademyRoles::StudentRegistration.where(
          student_number: "000124"
        )
      ).to exist
    end

    it "classifies a uniqueness conflict after the preload as skipped and continues issuing invitations" do
      existing =
        Fabricate(:academy_student_registration, student_number: "000123")
      existing_invite_key = existing.invite.invite_key

      allow(DiscourseAcademyRoles::StudentRegistration).to receive(
        :where
      ).and_wrap_original do |original, attributes|
        # The preload represents a snapshot before another batch reserved this number.
        if attributes == { student_number: %w[000123 000124] }
          DiscourseAcademyRoles::StudentRegistration.none
        else
          original.call(attributes)
        end
      end
      allow(DiscourseAcademyRoles::StudentRegistration).to receive(
        :create
      ).and_wrap_original do |original, attributes|
        if attributes[:student_number] == "000123"
          raise ActiveRecord::RecordNotUnique
        end
        original.call(attributes)
      end

      expect { result }.to change(Invite, :count).by(1).and change(
              DiscourseAcademyRoles::StudentRegistration,
              :count
            ).by(1)

      expect(csv.results.map { |row| row[:result] }).to eq(%i[skipped created])
      expect(
        csv.results.first.values_at(:invite_key, :link, :expires_at)
      ).to eq([nil, nil, nil])
      expect(csv.results.first[:reason]).to eq(
        I18n.t("academy_roles.student_invites.bulk.existing_student_number")
      )
      expect(existing.reload.invite.invite_key).to eq(existing_invite_key)
      expect(csv.to_csv).not_to include(existing_invite_key)
    end

    it "creates one invitation and skips the other when two batches contend for the same number" do
      batches =
        2.times.map do
          DiscourseAcademyRoles::StudentInviteCsv.new(StringIO.new("000123\n"))
        end
      invitations_before = Invite.count
      registrations_before = DiscourseAcademyRoles::StudentRegistration.count

      threads =
        batches.map do |batch|
          Thread.new do
            described_class.call(
              csv: batch,
              guardian: admin.guardian,
              expires_at:
            )
          end
        end
      threads.each(&:value)

      expect(Invite.count).to eq(invitations_before + 1)
      expect(DiscourseAcademyRoles::StudentRegistration.count).to eq(
        registrations_before + 1
      )
      expect(
        batches.flat_map(&:results).map { |row| row[:result] }
      ).to contain_exactly(:created, :skipped)
      skipped =
        batches.flat_map(&:results).find { |row| row[:result] == :skipped }
      expect(skipped.values_at(:invite_key, :link, :expires_at)).to eq(
        [nil, nil, nil]
      )
    end
  end
end
