require 'rake'
require 'bundler/gem_tasks'

task default: 'spec:all'


task :spec do
  success = system("bundle exec rspec spec --exclude-pattern 'spec/{isolated,interoperability}/**/*'")
  for_each_isolated_spec do |isolated_spec|
    success &= system("bundle exec rspec #{isolated_spec}")
  end
  fail "Tests failed" unless success
end

namespace :spec do
  task :all => [:spec, :"interoperability:spec:shoulda_matchers"]

  namespace :interoperability do
    task :shoulda_matchers do
      success = system("bundle exec rspec spec/interoperability")
      fail "Tests failed" unless success
    end
  end
end


def for_each_isolated_spec
  Dir["spec/isolated/**/*_spec.rb"].sort.each do |isolated_spec|
    yield(isolated_spec)
  end
end
