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
    it "accepts HTTP and HTTPS collection links from any host" do
      links = %w[
        https://f.wps.cn/g/resume-form
        https://forms.example.com/resume
        http://example.com:8080/form?q=1
        https://www.kdocs.cn/l/resume
      ]

      expect(links.map { |url| described_class.valid_collection?(url) }).to eq([true] * links.size)
    end

    it "rejects missing URLs, unsafe schemes and malformed syntax" do
      invalid = [
        nil,
        "",
        "example.com",
        "not a URL",
        "javascript:alert(1)",
        "data:text/html,test",
        "file:///tmp/form",
        "https://",
        "https://ex ample.com",
        "https://example.com/#{"a" * described_class::MAX_LENGTH}",
      ]

      expect(invalid.map { |url| described_class.valid_collection?(url) }).to eq(
        [false] * invalid.size,
      )
    end
  end
end
