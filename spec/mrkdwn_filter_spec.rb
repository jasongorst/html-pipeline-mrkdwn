# frozen_string_literal: true

require "rspec"
require_relative "../lib/html/pipeline/mrkdwn/helpers/pipeline"

RSpec.describe "HTML::Pipeline::Mrkdwn" do
  it "has a version number" do
    expect(HTML::Pipeline::Mrkdwn::VERSION).not_to be nil
  end

  it "returns a valid result" do
    result = PIPELINE.call("")
    expect(result).to be_a_kind_of(Hash)
    expect(result).to include(:output)
    expect(result[:output]).to be_a_kind_of(HTML::Pipeline::DocumentFragment)
  end

  def filter(input)
    PIPELINE.to_html(input)
  end

  it "leaves non-mrkdwn text unchanged" do
    input = "hello world"
    expect(filter(input)).to include(input)
  end

  it "converts multiline code blocks" do
    input = <<~INPUT.chomp
      ```
        puts "hello world!"
      ```
    INPUT
    expect(filter(input)).to include("<pre>\n  puts \"hello world!\"</pre>")
  end

  it "converts blockquotes" do
    input = <<~INPUT.chomp
      >first line
      >second line
      third line
    INPUT
    expect(filter(input)).to include("first line<br>second")
  end

  it "converts line breaks" do
    input = <<~INPUT.chomp
      the first line
      the second line
    INPUT
    expect(filter(input)).to include("first line<br>the second")
  end

  it "converts emoji" do
    input = ":rat:"
    expect(filter(input)).to include("\u{1f400}")
  end

  context "converts mentions" do
    it "converts channel mentions" do
      input = "<#Channel>"
      expect(filter(input)).to include("<span class=\"channel\">#Channel</span>")
    end

    it "converts user mentions" do
      input = "<@User>"
      expect(filter(input)).to include("<span class=\"user\">@User</span>")
    end

    it "converts special mentions" do
      input = "<!everyone>"
      expect(filter(input)).to include("<span class=\"mention\">@everyone</span>")
    end
  end

  context "converts links" do
    it "converts bare links" do
      input = "<https://example.org>"
      expect(filter(input)).to include("<a class=\"link\" href=\"https://example.org\">https://example.org</a>")
    end

    it "converts mailto links" do
      input = "<mailto:bob@example.com>"
      expect(filter(input)).to include("<a class=\"link\" href=\"mailto:bob@example.com\">mailto:bob@example.com</a>")
    end

    it "converts links with link text" do
      input = "<https://example.org/foo|Example Foo>"
      expect(filter(input)).to include("<a class=\"link\" href=\"https://example.org/foo\">Example Foo</a>")
    end
  end

  context "converts text styles" do
    it "converts bold text" do
      input = "*bold*"
      expect(filter(input)).to include("<strong>bold</strong>")
    end

    it "converts italic text" do
      input = "_italic_"
      expect(filter(input)).to include("<em>italic</em>")
    end

    it "converts strikethrough text" do
      input = "~strike~"
      expect(filter(input)).to include("<del>strike</del>")
    end

    it "converts inline code" do
      input = "`puts \"hello world!\"`"
      expect(filter(input)).to include("<code>puts \"hello world!\"</code>")
    end
  end
end
