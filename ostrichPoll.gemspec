# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ostrichPoll/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Wiktor Macura"]
  gem.email         = ["wiktor@tumblr.com"]
  gem.description   = %q{OstrichPoll is a tiny ruby script for polling one or more twitter ostrich endpoints}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ostrichpoll"
  gem.require_paths = ["lib"]
  gem.version       = OstrichPoll::VERSION

  gem.add_development_dependency 'json'
  gem.add_development_dependency 'trollop'
end
