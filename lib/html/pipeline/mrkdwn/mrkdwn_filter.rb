# frozen_string_literal: true

require "gemoji"

module HTML
  class Pipeline
    # HTML Filter for converting Slack's `mrkdwn` markup language.
    # https://api.slack.com/reference/surfaces/formatting#basics
    #
    # Context options:
    #   :emoji_image_tag - a Proc that returns an `img` tag for custom Emoji
    #   :slack_channels - a hash of Slack channel ids and channel names
    #   :slack_users - a hash of Slack user or bot ids and display names
    class Mrkdwn < Filter
      attr_reader :large_emoji

      EMOJI_AND_WHITESPACE_PATTERN = /(?::[\w+-_]+?:|\s)+/.freeze

      NON_CAPTURING_EMOJI_PATTERN = /:[\w+-_]+?:/.freeze

      MULTILINE_CODE_PATTERN = /```(.+?)```/m.freeze

      CODE_PATTERN = /`(?=\S)(.+?)(?<=\S)`/.freeze

      BLOCKQUOTE_PATTERN = /(^&gt;[^\n]*\n?)+/.freeze

      MENTION_PATTERN = /
        &lt;
        ([@#!][a-z0-9][a-z0-9-]*)
        &gt;
      /ix.freeze

      LINK_PATTERN = /
        &lt;
        ((?:http|mailto)[^|]+)
        (?:\|(.+?))?
        &gt;
      /x.freeze

      LINE_BREAK_PATTERN = /\n/.freeze

      EMOJI_PATTERN = /:([\w+-_]+?):/.freeze

      STYLE_PATTERN = /
        ([`*_~])
        (?=\S)(.+?)(?<=\S)
        \1
      /x.freeze

      IGNORE_PARENTS = %w[pre code a].to_set

      ELEMENTS = {
        multiline_code: %w[```],
        code: %w[`],
        blockquote: %w[&gt;],
        mention: %w[@ # !],
        link: %w[&lt;],
        line_break: %W[\n \r\n],
        emoji: %w[:],
        style: %w[* _ ~],
        unescape: %w[&amp;lowbar;]
      }.freeze

      def initialize(doc, context = nil, result = nil)
        super

        default_emoji_image_tag = ->(emoji) { "<img src=\"#{emoji.image_filename}\" alt=\"#{emoji.name}\" class=\"emoji\">" }

        @emoji_image_tag = @context[:emoji_image_tag] || default_emoji_image_tag
        @large_emoji_image_tag = @context[:large_emoji_image_tag] || @emoji_image_tag
        @large_emoji_class = @context[:large_emoji_class] || "emoji-lg"
        @slack_channels = @context[:slack_channels] || {}
        @slack_users = @context[:slack_users] || {}
      end

      def call
        div = doc.at_css("div")

        if wants_large_emoji?(div.content)
          @large_emoji = true
          div.add_class(@large_emoji_class)
        end

        ELEMENTS.each do |element, includes|
          process_text_nodes(includes) { |content| call_filter(element, content) }
        end

        doc
      end

      def validate
        if context[:emoji_image_tag] && !context[:emoji_image_tag].is_a?(Proc)
          raise ArgumentError,
                "context[:emoji_image_tag] should return a Proc that takes an Emoji object as in the 'gemoji' gem."
        end

        if context[:large_emoji_image_tag] && !context[:large_emoji_image_tag].is_a?(Proc)
          raise ArgumentError,
                "context[:large_emoji_image_tag] should return a Proc that takes an Emoji object as in the 'gemoji' gem."
        end

        if context[:slack_channels] && !context[:slack_channels].is_a?(Hash)
          raise ArgumentError,
                "context[:slack_channels] should return a Hash whose keys are Slack channel ids and values are their names."
        end

        if context[:slack_users] && !context[:slack_users].is_a?(Hash)
          raise ArgumentError,
                "context[:slack_users] should return a Hash whose keys are Slack user or bot ids and values are their display names."
        end
      end

      private

      def process_text_nodes(includes)
        doc.search(".//text()").each do |node|
          content = node.to_html
          next unless includes.any? { |str| content.include?(str) }
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = yield content
          next if html == content

          node.replace(html)
        end
      end

      def call_filter(filter_name, content)
        method = :"#{filter_name}_filter"
        send method, content
      end

      def multiline_code_filter(content)
        content.gsub MULTILINE_CODE_PATTERN do
          text = Regexp.last_match[1].chomp

          "<pre>#{text}</pre>"
        end
      end

      def code_filter(content)
        content.gsub CODE_PATTERN do |match|
          text = Regexp.last_match[1]

          if text&.match(/\A`+\Z/) # ignore runs of backquotes
            match
          else
            "<code>#{text}</code>"
          end
        end
      end

      def blockquote_filter(content)
        content.gsub BLOCKQUOTE_PATTERN do
          text = Regexp.last_match[0].chomp
          text.gsub!(/^&gt;\s*/, "")

          "<blockquote>#{blockquote_filter(text)}</blockquote>"
        end
      end

      def mention_filter(content)
        content.gsub MENTION_PATTERN do |match|
          mention = Regexp.last_match[1]

          (text, klass, prefix) =
            case mention
            when /\A#(C.+)\Z/ # slack channels
              [@slack_channels[Regexp.last_match[1]] || Regexp.last_match[1], "channel", "#"]

            when /\A@([UB].+)\Z/ # slack users or bots
              [@slack_users[Regexp.last_match[1]] || Regexp.last_match[1], "user", "@"]

            when /\A!(here|channel|everyone)\Z/ # special mentions
              [Regexp.last_match[1], "mention", "@"]
            else
              nil
            end

          if text
            "<span class=\"#{klass}\">#{prefix}#{text}</span>"
          else
            match
          end
        end
      end

      def link_filter(content)
        content.gsub LINK_PATTERN do
          link = Regexp.last_match[1]
          text = Regexp.last_match[2] || link

          "<a class=\"link\" href=\"#{link}\">#{text}</a>"
        end
      end

      def line_break_filter(content)
        content.gsub(LINE_BREAK_PATTERN, "<br>")
      end

      def emoji_filter(content)
        content.gsub(EMOJI_PATTERN) do |match|
          emoji = Emoji.find_by_alias(Regexp.last_match[1])

          if emoji&.custom?
            if @large_emoji
              @large_emoji_image_tag.call(emoji)
            else
              @emoji_image_tag.call(emoji)
            end
          elsif emoji
            emoji.raw
          else
            match.gsub(/_/, "&lowbar;")
          end
        end
      end

      def style_filter(content)
        content.gsub STYLE_PATTERN do |match|
          style = Regexp.last_match[1]
          text = Regexp.last_match[2]

          if text&.match(/\A[#{style}]+\Z/) # ignore runs of style delimiters
            match
          else
            case style
            when "*"
              "<strong>#{style_filter(text)}</strong>"
            when "_"
              "<em>#{style_filter(text)}</em>"
            when "~"
              "<del>#{style_filter(text)}</del>"
            else
              nil
            end
          end
        end
      end

      def unescape_filter(content)
        content.gsub("&amp;lowbar;", "_")
      end

      private

      def only_emoji_and_whitespace?(string)
        matchdata = EMOJI_AND_WHITESPACE_PATTERN.match(string)

        matchdata && matchdata[0] == string
      end

      def emoji_count(string)
        string.scan(NON_CAPTURING_EMOJI_PATTERN).size
      end

      def wants_large_emoji?(string)
        only_emoji_and_whitespace?(string) && emoji_count(string).between?(1, 23)
      end
    end
  end
end
