# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "/../../lib" )

require 'gemika'
require 'active_type'

ActiveRecord.class_eval do
  def self.version_agnostic_default_timezone
    if respond_to?(:default_timezone)
      self.default_timezone
    else
      self::Base.default_timezone
    end
  end

  def self.version_agnostic_default_timezone=(zone)
    if respond_to?(:default_timezone=)
      self.default_timezone = zone
    else
      self::Base.default_timezone = zone
    end
  end

  def self.version_agnostic_index_nested_attribute_errors
    if respond_to?(:index_nested_attribute_errors)
      self.index_nested_attribute_errors
    else
      self::Base.index_nested_attribute_errors
    end
  end

  def self.version_agnostic_index_nested_attribute_errors=(zone)
    if respond_to?(:index_nested_attribute_errors=)
      self.index_nested_attribute_errors = zone
    else
      self::Base.index_nested_attribute_errors = zone
    end
  end
end

ActiveRecord.version_agnostic_default_timezone = :local

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
