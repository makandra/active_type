# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "/../../lib" )

require 'active_type'

ActiveRecord::Base.default_timezone = :local
ActiveRecord::Base.raise_in_transactional_callbacks = true if ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks)

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].each {|f| require f}


RSpec.configure do |config|
  config.around do |example|
    if example.metadata.fetch(:rollback, true)
      ActiveRecord::Base.transaction do
        begin
          example.run
        ensure
          raise ActiveRecord::Rollback
        end
      end
    else
      example.run
    end
  end
end
