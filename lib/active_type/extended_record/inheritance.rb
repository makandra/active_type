module ActiveType

  module ExtendedRecord

    module Inheritance

      extend ActiveSupport::Concern

      included do
        class_attribute :extended_record_base_class
      end

      module ClassMethods

        def model_name
          extended_record_base_class.model_name
        end

        def sti_name
          extended_record_base_class.sti_name
        end

        def find_sti_class(type_name)
          sti_class = super
          if self <= sti_class
            self
          else
            sti_class
          end
        end

      end

    end

  end

end
