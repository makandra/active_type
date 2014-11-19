require 'active_type/virtual_attributes'
require 'active_type/extended_record/inheritance'

module ActiveType

  module ExtendedRecord

    extend ActiveSupport::Concern

    module ClassMethods

      def [](base)
        Class.new(base) do

          include VirtualAttributes
          include NestedAttributes
          include Inheritance

          self.extended_record_base_class = base
        end
      end

    end

  end

end
