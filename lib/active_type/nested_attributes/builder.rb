require 'active_type/nested_attributes/association'

module ActiveType

  module NestedAttributes

    class Builder

      def initialize(owner, mod)
        @owner = owner
        @module = mod
      end

      def build(name, options)
        options.assert_valid_keys(:scope, :allow_destroy, :many, :reject_if)
        association = Association.new(@owner, name, options)
        add_writer_method(name, association)
        add_autosave(name, association)
        add_validation(name, association)
      end


      private

      def add_writer_method(name, association)
        write_method = "#{name}_attributes="
        @module.module_eval do
          define_method write_method do |attributes|
            association.assign(self, attributes)
          end
        end
      end

      def add_autosave(name, association)
        save_method = "save_associated_records_for_#{name}"
        @module.module_eval do
          define_method save_method do
            association.save(self)
          end
        end
        @owner.after_save save_method
      end

      def add_validation(name, association)
        validate_method = "validate_associated_records_for_#{name}"
        @module.module_eval do
          define_method validate_method do
            association.validate(self)
          end
        end
        @owner.validate validate_method
      end

    end

  end

end
