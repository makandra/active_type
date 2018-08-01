require 'rake'
require 'bundler/gem_tasks'

begin
  require 'gemika/tasks'
rescue LoadError
  puts 'Run `gem install gemika` for additional tasks'
end

task default: 'matrix:spec'


# we have to override the matrix:spec task, since we need some specs to run in isolation

Rake::Task["matrix:spec"].clear

namespace :matrix do

  desc "Run specs for all Ruby #{RUBY_VERSION} gemfiles"
  task :spec, :files do |t, options|
    Gemika::Matrix.from_travis_yml.each do |row|
      options = options.to_hash.merge(
        :gemfile => row.gemfile,
        :fatal => false,
        :bundle_exec => true,
      )
      success = Gemika::RSpec.run_specs(options.merge(
        :options => '--exclude-pattern "**/isolated/**"',
      ))

      for_each_isolated_spec do |isolated_spec|
        isolated_success = Gemika::RSpec.run_specs(options.merge(
          :files => isolated_spec,
        ))
        success &&= isolated_success
      end

      success
    end
  end

end

def for_each_isolated_spec
  Dir["spec/isolated/**/*_spec.rb"].sort.each do |isolated_spec|
    yield(isolated_spec)
  end
end
