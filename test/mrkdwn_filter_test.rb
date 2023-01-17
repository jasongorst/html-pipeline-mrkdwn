# frozen_string_literal: true

require "minitest/autorun"
require "minitest/rg"
require_relative "../lib/html/pipeline/mrkdwn"

class TestMrkdwn < Minitest::Test
  def setup
    @pipeline = HTML::Pipeline.new [
      HTML::Pipeline::PlainTextInputFilter,
      HTML::Pipeline::Mrkdwn
    ]
  end

  def test_that_it_has_a_version_number
    refute_nil HTML::Pipeline::Mrkdwn::VERSION
  end

  def test_that_it_returns_a_valid_result
    result = @pipeline.call("")
    assert_kind_of Hash, result
    assert_includes result, :output
    assert_kind_of HTML::Pipeline::DocumentFragment, result[:output]
  end

  def filter(input)
    @pipeline.to_html(input)
  end

  def test_that_it_wraps_non_mrkdwn_content
    input = "hello world"
    assert_equal filter(input), "<div>#{input}</div>"
  end

  def test_that_it_converts_multiline_code_blocks
    input = <<~INPUT.chomp
      ```
        puts "hello world!"
      ```
    INPUT
    assert_includes filter(input), "<pre>\n  puts \"hello world!\"</pre>"
  end

  def test_that_it_converts_blockquotes
    input = <<~INPUT.chomp
      >first line
      >second line
      third line
    INPUT
    assert_includes filter(input), "first line<br>second"
  end

  def test_that_it_converts_line_breaks
    input = <<~INPUT.chomp
      the first line
      the second line
    INPUT
    assert_includes filter(input), "first line<br>the second"
  end

  def test_that_it_converts_emoji
    input = ":rat:"
    assert_includes filter(input), "\u{1f400}"
  end

  def test_that_it_converts_channel_mentions
    input = "<#Channel>"
    assert_includes filter(input), "<span class=\"channel\">#Channel</span>"
  end

  def test_that_it_converts_user_mentions
    input = "<@User>"
    assert_includes filter(input), "<span class=\"user\">@User</span>"
  end

  def test_that_it_converts_special_mentions
    input = "<!everyone>"
    assert_includes filter(input), "<span class=\"mention\">@everyone</span>"
  end

  def test_that_it_converts_bare_links
    input = "<https://example.org>"
    assert_includes filter(input), "<a class=\"link\" href=\"https://example.org\">https://example.org</a>"
  end

  def test_that_it_converts_mailto_links
    input = "<mailto:bob@example.com>"
    assert_includes filter(input), "<a class=\"link\" href=\"mailto:bob@example.com\">mailto:bob@example.com</a>"
  end

  def test_that_it_converts_links_with_link_text
    input = "<https://example.org/foo|Example Foo>"
    assert_includes filter(input), "<a class=\"link\" href=\"https://example.org/foo\">Example Foo</a>"
  end

  def test_that_it_converts_bold_text
    input = "*bold*"
    assert_includes filter(input), "<strong>bold</strong>"
  end

  def test_that_it_converts_italic_text
    input = "_italic_"
    assert_includes filter(input), "<em>italic</em>"
  end

  def test_that_it_converts_strikethrough_text
    input = "~strike~"
    assert_includes filter(input), "<del>strike</del>"
  end

  def test_that_it_converts_inline_code
    input = "`puts \"hello world!\"`"
    assert_includes filter(input), "<code>puts \"hello world!\"</code>"
  end
end
