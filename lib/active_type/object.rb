require 'active_type/no_table'
require 'active_type/virtual_attributes'
require 'active_type/nested_attributes'

module ActiveType

  class Object < ActiveRecord::Base

    include NoTable
    include VirtualAttributes
    include NestedAttributes

  end

end
