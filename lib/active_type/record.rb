require 'active_type/virtual_attributes'
require 'active_type/record_extension'
require 'active_type/nested_attributes'

module ActiveType

  class Record < ActiveRecord::Base

    @abstract_class = true

    include VirtualAttributes
    include NestedAttributes
    include RecordExtension

  end

end
