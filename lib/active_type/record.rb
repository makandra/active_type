require 'active_type/virtual_attributes'
require 'active_type/extended_record'
require 'active_type/nested_attributes'

module ActiveType

  class Record < ActiveRecord::Base

    @abstract_class = true

    include VirtualAttributes
    include NestedAttributes
    include ExtendedRecord

  end

end
