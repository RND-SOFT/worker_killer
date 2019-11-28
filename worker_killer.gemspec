$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'worker_killer/version'

Gem::Specification.new 'worker_killer' do |spec|
  spec.version     = ENV['BUILDVERSION'].to_i > 0 ? "#{WorkerKiller::VERSION}.#{ENV['BUILDVERSION'].to_i}" : WorkerKiller::VERSION
  spec.authors     = ['Samoilenko Yuri']
  spec.email       = ['kinnalru@gmail.com']

  spec.summary     = 'Kill any workers by memory and request counts or take custom reaction'
  spec.description = spec.summary

  spec.homepage    = 'https://github.com/RnD-Soft/worker_killer'
  spec.license     = 'MIT'

  spec.files       = Dir['{lib}/**/*', 'AUTHORS', 'README.md', 'LICENSE"'].reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.test_files = Dir['**/*'].select do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'get_process_mem'

  spec.add_development_dependency 'bundler', '~> 2.0', '>= 2.0.1'
  spec.add_development_dependency 'rake'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-console'
end

