# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ostrichPoll/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Wiktor Macura"]
  gem.email         = ["wiktor@tumblr.com"]
  gem.description   = %q{Ostrichpoll is a tiny utility for monitoring Twitter Ostrich services. Effectively it can monitor any service which exposes internal metrics in JSON over HTTP.}
  gem.summary       = %q{Ostrichpoll is a tiny utility for monitoring Twitter Ostrich services.}
  gem.homepage      = "http://github.com/tumblr/ostrichpoll"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ostrichpoll"
  gem.require_paths = ["lib"]
  gem.version       = OstrichPoll::VERSION

  gem.add_development_dependency 'json'
  gem.add_development_dependency 'trollop'
end
