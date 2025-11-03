$:.push File.expand_path("../lib", __FILE__)
require "active_type/version"

Gem::Specification.new do |s|
  s.name = 'active_type'
  s.version = ActiveType::VERSION
  s.authors = ["Tobias Kraze", "Henning Koch"]
  s.email = 'tobias.kraze@makandra.de'
  s.homepage = 'https://github.com/makandra/active_type'
  s.summary = 'Make any Ruby object quack like ActiveRecord'
  s.description = s.summary
  s.license = 'MIT'
  s.metadata = {
    'source_code_uri' => s.homepage,
    'bug_tracker_uri' => s.homepage + '/issues',
    'changelog_uri' => s.homepage + '/blob/master/CHANGELOG.md',
    'rubygems_mfa_required' => 'true',
  }

  s.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).select do |f|
      f.start_with?(*%w[lib LICENSE README.md CHANGELOG.md])
    end
  end
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", ">= 1.5"
  s.add_development_dependency "rake"

  s.add_runtime_dependency('activerecord', '>= 6.1')

  s.required_ruby_version = '>= 2.7.0'
end
