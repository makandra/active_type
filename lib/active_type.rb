# encoding: utf-8

require 'active_type/version'

require 'active_record'

if ActiveRecord::VERSION::STRING == '4.2.0'
  raise(<<-MESSAGE.strip_heredoc)
    ActiveType is not compatible with ActiveRecord 4.2.0. Please upgrade to 4.2.1
    For details see https://github.com/makandra/active_type/issues/31
  MESSAGE
end

module ActiveType
  extend ActiveSupport::Autoload

  autoload :Object
  autoload :Record
  autoload :Util

  # Make Util methods available under the `ActiveType` namespace
  # like `ActiveType.cast(...)`
  extend Util
end
