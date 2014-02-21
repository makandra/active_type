require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'

namespace :travis_ci do

  desc 'Things to do before Travis CI begins'
  task :prepare => :slimgems do
    Rake::Task['travis_ci:create_database'].invoke &&
    Rake::Task['travis_ci:create_database_yml'].invoke
  end

  desc 'Install slimgems'
  task :slimgems do
    system('gem install slimgems')
  end

  desc 'Creates a test database'
  task :create_database do
    system("mysql -e 'create database active_type_test;'")
  end

  desc 'Creates a database.yml'
  task :create_database_yml do
    config_dir = "spec/shared/app_root/config"
    system("cp #{config_dir}/database.travis_ci.yml #{config_dir}/database.yml")
  end

end

namespace :all do

  desc "Run specs on all spec apps"
  task :spec do
    success = true
    for_each_directory_of('spec/**/Rakefile') do |directory|
      env = "SPEC=../../#{ENV['SPEC']} " if ENV['SPEC']
      success &= system("cd #{directory} && #{env} bundle exec rake spec")
    end
    fail "Tests failed" unless success
  end

  desc "Bundle all spec apps"
  task :bundle do
    for_each_directory_of('spec/**/Gemfile') do |directory|
      system("cd #{directory} && bundle install")
    end
  end

end

def for_each_directory_of(path, &block)
  Dir[path].sort.each do |rakefile|
    directory = File.dirname(rakefile)
    puts '', "\033[44m#{directory}\033[0m", ''
    block.call(directory)
  end
end
