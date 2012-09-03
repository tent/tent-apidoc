# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "tent-apidoc"
  gem.version       = '0.1.0'
  gem.authors       = ["Jonathan Rudenberg"]
  gem.email         = ["jonathan@titanous.com"]
  gem.description   = "API examples for the Tent protocol documentation"
  gem.summary       = "API examples for the Tent protocol documentation"
  gem.homepage      = "http://tent.io"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'tent-client'
  gem.add_runtime_dependency 'tentd'
  gem.add_runtime_dependency 'rack-test'
end
