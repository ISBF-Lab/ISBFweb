# frozen_string_literal: true

RSpec.describe IsbfResume::SharingLinks do
  describe ".valid?" do
    it "accepts HTTPS cloud-document links hosted by WPS and Kdocs" do
      links = %w[
        https://www.kdocs.cn/l/resume
        https://kdocs.cn/l/resume?from=share#page-1
        https://www.wps.cn/resume
        https://drive.wps.cn/resume
      ]

      expect(links.map { |url| described_class.valid?(url) }).to eq([true] * links.size)
    end

    it "rejects unrelated hosts, credentials, unsafe syntax and excessive lengths" do
      links = [
        nil,
        "",
        "http://www.kdocs.cn/l/resume",
        "//www.kdocs.cn/l/resume",
        "javascript:alert(1)",
        "https://www.kdocs.cn.example.com/l/resume",
        "https://example.com/?next=https://www.kdocs.cn/l/resume",
        "https://user:password@www.kdocs.cn/l/resume",
        "https://www.kdocs.cn:444/l/resume",
        "https://www.kdocs.cn/l/with space",
        "https://www.kdocs.cn/l/resume\n",
        "https://www.kdocs.cn\\@example.com/l/resume",
        "https://www.kdocs.cn/l/#{"a" * described_class::MAX_LENGTH}",
      ]

      expect(links.map { |url| described_class.valid?(url) }).to eq([false] * links.size)
    end
  end

  describe ".valid_collection?" do
    it "accepts only HTTPS WPS collection-form links" do
      expect(described_class.valid_collection?("https://f.wps.cn/g/resume-form")).to eq(true)
      invalid = %w[
        https://www.kdocs.cn/l/resume
        https://f.wps.cn/unrelated-path
        https://f.wps.cn/g/
        https://f.wps.cn.example.com/g/resume
        http://f.wps.cn/g/resume
      ]

      expect(invalid.map { |url| described_class.valid_collection?(url) }).to eq(
        [false] * invalid.size,
      )
    end
  end
end
