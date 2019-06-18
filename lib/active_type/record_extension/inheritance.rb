module ActiveType

  module RecordExtension

    module Inheritance

      extend ActiveSupport::Concern

      included do
        class_attribute :extended_record_base_class
      end

      def self.add_foreign_key_option(extended_record_base_class, scope = nil, options = {})
        if scope.is_a?(Hash)
          options = scope
          scope = nil
        end
        unless options[:foreign_key]
          options = options.merge(foreign_key: extended_record_base_class.name.foreign_key)
        end
        if ActiveRecord::VERSION::MAJOR > 3
          [scope, options]
        else
          [options]
        end
      end

      module ClassMethods

        def model_name
          extended_record_base_class.model_name
        end

        def sti_name
          extended_record_base_class.sti_name
        end

        def has_many(name, *args, &extension)
          super(name, *Inheritance.add_foreign_key_option(extended_record_base_class, *args), &extension)
        end

        def has_one(name, *args, &extension)
          super(name, *Inheritance.add_foreign_key_option(extended_record_base_class, *args), &extension)
        end

        private

        if ActiveRecord::VERSION::MAJOR < 5

          def find_sti_class(type_name)
            sti_class = super
            if self <= sti_class
              self
            else
              sti_class
            end
          end

        else

          # Rails 5 find_sti_class does a sanity check for proper inheritance that fails for
          # our usecase
          # copied from activerecord/lib/active_record/inheritance.rb
          def find_sti_class(type_name)
            type_name = base_class.type_for_attribute(inheritance_column).cast(type_name)
            subclass = begin
              if store_full_sti_class
                ActiveSupport::Dependencies.constantize(type_name)
              else
                compute_type(type_name)
              end
            rescue NameError
              raise ActiveRecord::SubclassNotFound,
                "The single-table inheritance mechanism failed to locate the subclass: '#{type_name}'. " \
                "This error is raised because the column '#{inheritance_column}' is reserved for storing the class in case of inheritance. " \
                "Please rename this column if you didn't intend it to be used for storing the inheritance class " \
                "or overwrite #{name}.inheritance_column to use another column for that information."
            end
            #### our code starts here
            if self <= subclass
              subclass = self
            end
            #### our code ends here
            unless subclass == self || descendants.include?(subclass)
              raise ActiveRecord::SubclassNotFound, "Invalid single-table inheritance type: #{subclass.name} is not a subclass of #{name}"
            end
            subclass
          end

        end

      end

    end

  end

end
