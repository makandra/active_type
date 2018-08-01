require 'rake'
require 'bundler/gem_tasks'

begin
  require 'gemika/tasks'
rescue LoadError
  puts 'Run `gem install gemika` for additional tasks'
end

task default: 'matrix:spec'


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
