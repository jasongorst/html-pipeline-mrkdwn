# frozen_string_literal: true

# A default pipeline for Slack messages using mrkdwn.

require "bundler/setup"
require_relative "../../mrkdwn"

PIPELINE = HTML::Pipeline.new [
  HTML::Pipeline::PlainTextInputFilter,
  HTML::Pipeline::Mrkdwn
]
