require 'active_type/no_table'
require 'active_type/virtual_attributes'

module ActiveType

  class Object < ActiveRecord::Base

    include NoTable
    include VirtualAttributes

    def initialize(attributes = nil, options = {})
      initialize_virtual_attributes
      super
    end

  end

end
