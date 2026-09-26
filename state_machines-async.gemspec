# frozen_string_literal: true

require_relative 'lib/state_machines/async/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines-async'
  spec.version       = StateMachines::Async::VERSION
  spec.authors       = ['Abdelkader Boudih']
  spec.email         = ['oss@seuros.com']
  spec.summary       = 'Async mode for state_machines'
  spec.homepage      = 'https://github.com/state-machines/state_machines-async'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4.0'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'state_machines'
  spec.add_dependency 'async', '>= 2.25.0'
  spec.add_dependency 'concurrent-ruby', '>= 1.3.5'

  spec.add_development_dependency 'minitest', '= 5.27.0'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rake'
end
