# frozen_string_literal: true

require_relative "lib/html/pipeline/mrkdwn/version"

Gem::Specification.new do |spec|
  spec.platform = Gem::Platform::RUBY
  spec.name = "html-pipeline-mrkdwn"
  spec.version = HTML::Pipeline::Mrkdwn::VERSION

  spec.summary = "An HTML::Pipeline filter for Slack's mrkdwn markup language."
  spec.description = "An HTML::Pipeline filter for Slack's mrkdwn markup language."
  spec.homepage = "https://github.com/jasongorst/html-pipeline-mrkdwn"

  spec.author = "Jason Gorst"
  spec.email = "jason.gorst@me.com"

  spec.required_ruby_version = ">= 3.2.0"

  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jasongorst/html-pipeline-mrkdwn.git"
  spec.metadata["changelog_uri"] = "https://github.com/jasongorst/html-pipeline-mrkdwn/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|circleci)|appveyor)})
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "escape_utils", "~> 1.3"
  spec.add_dependency "gemoji", "~> 4.1"
  spec.add_dependency "html-pipeline", "~> 2.14"

  spec.add_development_dependency "bundler", "~> 2.5.22"
  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "minitest-reporters", "~> 1.7"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.67"
end
