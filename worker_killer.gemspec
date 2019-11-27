$:.push File.expand_path('lib', __dir__)

Gem::Specification.new do |gem|
  gem.name        = 'worker_killer'
  gem.description = 'Kill any workers by memory and request counts or take custom reaction'
  gem.homepage    = 'https://github.com/RnD-Soft/worker_killer'
  gem.summary     = gem.description
  gem.version     = File.read('VERSION').strip
  gem.authors     = ['Samoilenko Yuri']
  gem.email       = ['kinnalru@gmail.com']
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f) }
  gem.license     = 'MIT'
  gem.require_paths = ['lib']

  gem.add_dependency 'get_process_mem'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec_junit_formatter'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'simplecov-console'
end

