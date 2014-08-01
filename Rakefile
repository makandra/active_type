require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'


namespace :all do

  desc "Run specs on all versions"
  task :spec do
    success = true
    for_each_gemfile do
      success &= system("bundle exec rspec spec")
    end
    fail "Tests failed" unless success
  end

  desc "Bundle all versions"
  task :bundle do
    for_each_gemfile do
      system('bundle install')
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
