# frozen_string_literal: true

require_relative 'lib/state_machines/async/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines-async'
  spec.version       = StateMachines::Async::VERSION
  spec.authors       = ['Abdelkader Boudih']
  spec.email         = ['terminale@gmail.com']
  spec.summary       = 'Async mode for state_machines'
  spec.description   = 'Asynchronous, thread-safe state machines for state_machines: async: true, ' \
                       '<event>_async methods and concurrent transitions, on the async gem (CRuby only)'
  spec.homepage      = 'https://github.com/state-machines/state_machines-async'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 4.0'

  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['{lib}/**/*', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'async', '>= 2.25.0'
  spec.add_dependency 'concurrent-ruby', '>= 1.3.5'
  spec.add_dependency 'state_machines', '>= 0.302.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 6.0'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rake'
end
