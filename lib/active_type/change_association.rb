module ActiveType

  module ChangeAssociation

    extend ActiveSupport::Concern

    module ClassMethods

      def change_association(association_name, new_scope, new_options = nil)
        if (existing_association = self.reflect_on_association(association_name))
          if new_scope.is_a?(Hash)
            new_options = new_scope
            new_scope = nil
          end
          original_options = existing_association.options
          if ActiveRecord::VERSION::MAJOR > 3
            new_scope ||= existing_association.scope
            public_send(existing_association.macro, association_name, new_scope, **original_options.merge(new_options))
          else
            public_send(existing_association.macro, association_name, **original_options.merge(new_options))
          end
        else
          raise ArgumentError, "unrecognized association `#{association_name}`"
        end
      end

    end

  end

end
