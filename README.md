# Html::Pipeline::Mrkdwn

An [HTML::Pipeline](https://github.com/gjtorikian/html-pipeline) filter for Slack's
[mrkdwn](https://api.slack.com/reference/surfaces/formatting#basics) markup language.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html-pipeline-mrkdwn'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html-pipeline-mrkdwn

## Usage

Example:

```ruby
require 'html/pipeline'
require 'html/pipeline/mrkdwn'

filters = [
  HTML::Pipeline::PlainTextInputFilter,
  HTML::Pipeline::Mrkdwn
]

pipeline = HTML::Pipeline.new filters

input = "*bold* will produce bold text"

result = pipeline.call(input)

puts result[:output].to_html
# => "<div>\n<strong>bold</strong> will produce bold text</div>" 
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jasongorst/html-pipeline-mrkdwn.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
