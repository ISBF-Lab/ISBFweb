# frozen_string_literal: true

require_relative "../../plugin_helper"

RSpec.describe IsbfJoin::SubmitApplication do
  describe described_class::Contract, type: :model do
    subject(:contract) do
      described_class.new(
        name: "申请人",
        student_id: "2026101401",
        phone: "+86 138-0013-8000",
        submission_id: "491e9a65-3270-4acd-8ba9-dc726a6a0307",
      )
    end

    it { is_expected.to allow_values("张三", "A" * 60, "😀" * 30).for(:name) }

    it do
      is_expected.not_to allow_values(nil, "", "  ", 123, [], {}, "A" * 61, "😀" * 31).for(:name)
    end

    it { is_expected.not_to allow_values("张\u0000三", "张\n三", "张\u007f三").for(:name) }

    it { is_expected.to allow_values("2026101401", "A" * 40, "😀" * 20).for(:student_id) }

    it do
      is_expected.not_to allow_values(nil, "", " ", 123, [], {}, "A" * 41, "😀" * 21).for(
        :student_id,
      )
    end

    it { is_expected.not_to allow_values("20\u000026", "20\t26", "20\u007f26").for(:student_id) }

    it do
      is_expected.to allow_values("1234567", "+86 (138) 0013-8000", "+123456789012345").for(:phone)
    end

    it do
      is_expected.not_to allow_values(
        nil,
        "",
        13_800_138_000,
        [],
        {},
        "123456",
        "1234567890123456",
        "1234567#",
        "1" + " " * 24 + "234567",
      ).for(:phone)
    end

    it do
      is_expected.not_to allow_values("123\n4567", "123\u00004567", "123\u007f4567").for(:phone)
    end

    it { is_expected.to allow_values("491E9A65-3270-4ACD-8BA9-DC726A6A0307").for(:submission_id) }

    it do
      is_expected.not_to allow_values(
        nil,
        "",
        123,
        [],
        {},
        "491e9a65-3270-1acd-8ba9-dc726a6a0307",
        "491e9a65-3270-4acd-7ba9-dc726a6a0307",
        "491e9a65-3270-4acd-8ba9-dc726a6a0307x",
      ).for(:submission_id)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    let(:params) do
      {
        name: "\uFEFF 申请人\u00a0",
        student_id: " 2026101401 ",
        phone: " +86 138-0013-8000 ",
        submission_id: "491E9A65-3270-4ACD-8BA9-DC726A6A0307",
      }
    end
    let(:dependencies) { {} }

    context "with an invalid contract" do
      let(:params) { super().merge(name: "") }

      it "halts before saving an application" do
        expect { result }.not_to change(IsbfJoin::Application, :count)
        expect(result).to fail_a_contract
      end
    end

    context "when persistence is unavailable" do
      before do
        IsbfJoin::Application.stubs(:create_or_find_by).raises(ActiveRecord::StatementInvalid)
      end

      it "returns a failed result without saving" do
        expect { result }.not_to change(IsbfJoin::Application, :count)
        expect(result).to fail_to_find_a_model(:application)
      end
    end

    context "with a new submission" do
      it "saves normalized contact details and succeeds" do
        expect { result }.to change(IsbfJoin::Application, :count).by(1)
        expect(result).to run_successfully
        expect(result.application).to have_attributes(
          name: "申请人",
          student_id: "2026101401",
          phone: "+86 138-0013-8000",
          submission_id: params[:submission_id].downcase,
        )
        expect(result.application).to be_persisted
      end
    end

    context "with an identical previous submission" do
      fab!(:application) do
        Fabricate(
          :isbf_join_application,
          student_id: "2026101401",
          submission_id: "491e9a65-3270-4acd-8ba9-dc726a6a0307",
        )
      end

      it "returns the existing application without another write" do
        expect { result }.not_to change(IsbfJoin::Application, :count)
        expect(result).to run_successfully
        expect(result.application).to eq(application)
        expect(result.application).not_to be_previously_new_record
      end
    end

    context "with a previous submission containing different details" do
      fab!(:application) do
        Fabricate(
          :isbf_join_application,
          name: "原申请人",
          student_id: "2026101401",
          submission_id: "491e9a65-3270-4acd-8ba9-dc726a6a0307",
        )
      end

      it "fails the replay policy and retains the original record" do
        expect { result }.not_to change(IsbfJoin::Application, :count)
        expect(result).to fail_a_policy(:submission_matches)
        expect(application.reload.name).to eq("原申请人")
      end
    end
  end
end
