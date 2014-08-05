require 'active_type/nested_attributes/builder'

module ActiveType

  module NestedAttributes

    extend ActiveSupport::Concern

    module ClassMethods

      def nests_one(association_name, options = {})
        Builder.new(self, generated_nested_attribute_methods).build(association_name, :one, options)
      end

      def nests_many(association_name, options = {})
        Builder.new(self, generated_nested_attribute_methods).build(association_name, :many, options)
      end


      private

      def generated_nested_attribute_methods
        @generated_nested_attribute_methods ||= begin
          mod = Module.new
          include mod
          mod
        end
      end

    end

  end

end

