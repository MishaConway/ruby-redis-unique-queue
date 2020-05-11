# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_unique_queue'

Gem::Specification.new do |spec|
  spec.name          = "redis-unique-queue"
  spec.version       = RedisUniqueQueue::VERSION
  spec.authors       = ["Misha Conway"]
  spec.email         = ["mishaAconway@gmail.com"]
  spec.summary       = %q{A unique queue with atomic operations implemented in Redis}
  spec.description   = %q{A unique queue with atomic operations implemented in Redis.}
  spec.homepage      = "https://github.com/MishaConway/ruby-redis-unique-queue"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency 'redis'
end
