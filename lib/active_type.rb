# encoding: utf-8

require 'active_type/version'
require 'active_record'
require 'active_type/record'
require 'active_type/object'

if ActiveRecord::VERSION::STRING == '4.2.0'
  raise(<<-MESSAGE.strip_heredoc)
    ActiveType is not compatible with ActiveRecord 4.2.0. Please upgrade to 4.2.1
    For details see https://github.com/makandra/active_type/issues/31
  MESSAGE
end