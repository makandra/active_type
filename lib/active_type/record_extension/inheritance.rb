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
        unless options[:foreign_key] || options[:as]
          options = options.merge(foreign_key: extended_record_base_class.name.foreign_key)
        end
        if ActiveRecord::VERSION::MAJOR > 3
          [options, scope]
        else
          [options]
        end
      end

      module ClassMethods

        def model_name
          @_model_name ||= begin
            if name
              # Namespace detection copied from ActiveModel::Naming
              namespace = module_ancestors.detect do |n|
                n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
              end
              # We create a Name object, with the sti class name, but self as the @klass reference
              # This way lookup_ancestors is invoked on the right class instead of the extended_record_base_class
              dup_model_name = ActiveModel::Name.new(self, namespace, sti_name)
              key = name.underscore.to_sym
              # We set the `i18n_key` to lookup on the derived class key
              # We keep the others the same to preserve parameter and route names
              dup_model_name.instance_variable_set(:@i18n_key, key)
              dup_model_name
            else # name is nil for the anonymous intermediate class
              extended_record_base_class.model_name
            end
          end
        end

        def module_ancestors
          if extended_record_base_class.respond_to?(:module_parents)
            extended_record_base_class.module_parents
          else
            extended_record_base_class.parents
          end
        end

        def sti_name
          extended_record_base_class.sti_name
        end

        def descends_from_active_record?
          extended_record_base_class.descends_from_active_record?
        end

        def has_many(name, scope=nil, *args, &extension)
          new_args, new_scope = Inheritance.add_foreign_key_option(extended_record_base_class, scope, *args)
          if ActiveRecord::VERSION::MAJOR <= 3 || new_scope.nil?
            super(name, **new_args, &extension)
          else
            super(name, new_scope, **new_args, &extension)
          end
        end

        def has_one(name, scope=nil, *args, &extension)
          new_args, new_scope = Inheritance.add_foreign_key_option(extended_record_base_class, scope, *args)
          if ActiveRecord::VERSION::MAJOR <= 3 || new_scope.nil?
            super(name, **new_args, &extension)
          else
            super(name, new_scope, **new_args, &extension)
          end
        end

        private

        if ActiveRecord::VERSION::MAJOR < 5

          def find_sti_class(type_name)
            sti_class = super

            # Consider this class hierarchy
            # class Parent < ActiveRecord::Base; end
            # class Child < Parent; end
            # class ExtendedParent < ActiveType::Record[Parent]; end
            # class ExtendedChild < ActiveType::Record[Child]; end
            if self < sti_class
              # i.e. ExtendendChild.find(child.id)
              # => self = ExtendedChild; sti_class = Child
              # instantiate as ExtendedChild
              self
            elsif sti_class < extended_record_base_class
              # i.e. ExtendedParent.find(child.id)
              # => sti_class = Child; self = ExtendedParent; extended_record_base_class = Parent
              # There is no really good solution here, since we cannot instantiate as both ExtendedParent
              # and Child. We opt to instantiate as ExtendedParent, since the other option can be
              # achieved by using Parent.find(child.id)
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
            # Consider this class hierarchy
            # class Parent < ActiveRecord::Base; end
            # class Child < Parent; end
            # class ExtendedParent < ActiveType::Record[Parent]; end
            # class ExtendedChild < ActiveType::Record[Child]; end
            if self < subclass
              # i.e. ExtendendChild.find(child.id)
              # => self = ExtendedChild; subclass = Child
              # instantiate as ExtendedChild
              subclass = self
            elsif subclass < extended_record_base_class
              # i.e. ExtendedParent.find(child.id)
              # => subclass = Child; self = ExtendedParent; extended_record_base_class = Parent
              # There is no really good solution here, since we cannot instantiate as both ExtendedParent
              # and Child. We opt to instantiate as ExtendedParent, since the other option can be
              # achieved by using Parent.find(child.id)
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
