require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'


desc "Run specs and isolated specs"
task :spec do
  success = run_specs
  fail "Tests failed" unless success
end

namespace :all do

  desc "Run specs on all versions"
  task :spec do
    success = true
    for_each_gemfile do
      success &= run_specs
    end
    fail "Tests failed" unless success
  end

  desc "Bundle all versions"
  task :install do
    for_each_gemfile do
      system('bundle install')
    end
  end

  desc "Update all versions"
  task :update do
    for_each_gemfile do
      system('bundle update')
    end
  end

end

def for_each_gemfile
  version = ENV['VERSION'] || '*'
  Dir["gemfiles/Gemfile.#{version}"].sort.each do |gemfile|
    next if gemfile =~ /.lock/
    puts '', "\033[44m#{gemfile}\033[0m", ''
    ENV['BUNDLE_GEMFILE'] = gemfile
    yield
  end
end

def for_each_isolated_spec
  Dir["spec/isolated/**/*_spec.rb"].sort.each do |isolated_spec|
    yield(isolated_spec)
  end
end

def run_specs
  success = system("bundle exec rspec spec --exclude-pattern '**/isolated/**'")
  for_each_isolated_spec do |isolated_spec|
    success &= system("bundle exec rspec #{isolated_spec}")
  end
  success
end
