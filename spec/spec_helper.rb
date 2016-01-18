# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "/../../lib" )

require 'active_type'

ActiveRecord::Base.default_timezone = :local

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].each {|f| require f}


RSpec.configure do |config|
  config.around do |example|
    next example.run unless example.metadata.fetch(:rollback, true)
    ActiveRecord::Base.transaction do
      begin
        example.run
      ensure
        raise ActiveRecord::Rollback
      end
    end
  end
end
