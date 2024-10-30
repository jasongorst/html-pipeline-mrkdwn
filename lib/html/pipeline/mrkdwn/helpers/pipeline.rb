require_relative "../../mrkdwn"

PIPELINE = HTML::Pipeline.new [ HTML::Pipeline::PlainTextInputFilter, HTML::Pipeline::Mrkdwn ]
