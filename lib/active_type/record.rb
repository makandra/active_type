require 'active_type/virtual_attributes'

module ActiveType

  class Record < ActiveRecord::Base

    include VirtualAttributes

    def initialize(attributes = nil, options = {})
      initialize_virtual_attributes
      super
    end

  end

end
