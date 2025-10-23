# encoding: utf-8

require 'active_type/version'

require 'active_record'

module ActiveType
  extend ActiveSupport::Autoload

  autoload :Object
  autoload :Record
  autoload :Util

  # Make Util methods available under the `ActiveType` namespace
  # like `ActiveType.cast(...)`
  extend Util

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new
  end
end
