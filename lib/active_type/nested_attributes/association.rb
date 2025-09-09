require 'active_record/errors'

module ActiveType

  module NestedAttributes

    class RecordNotFound < ActiveRecord::RecordNotFound; end

    class Association

      def initialize(owner, target_name, options = {})
        options.assert_valid_keys(*valid_options)

        @owner = owner
        @target_name = target_name.to_sym
        @allow_destroy = options.fetch(:allow_destroy, false)
        @reject_if = options.delete(:reject_if)
        @options = options.dup

        @index_errors = case
                        when ActiveRecord::VERSION::MAJOR < 5
                          @options[:index_errors]
                        when ActiveRecord::VERSION::MAJOR < 7
                          @options[:index_errors] || ActiveRecord::Base.index_nested_attribute_errors
                        else
                          @options[:index_errors] || ActiveRecord.index_nested_attribute_errors
                        end
      end

      def assign_attributes(parent, attributes)
        raise NotImplementedError
      end

      def save(parent)
        keep = assigned_children(parent)
        changed_children(parent).each do |child|
          if child.marked_for_destruction?
            child.destroy if child.persisted?
            keep.delete(child)
          else
            child.save(:validate => false) or raise ActiveRecord::Rollback
          end
        end
        assign_children(parent, keep)
      end

      def validate(parent)
        changed_children(parent).each_with_index do |child, index|
          add_errors_to_parent(parent, child, index) unless child.valid?
        end
      end

      private

      def add_child(parent, child_or_children)
        raise NotImplementedError
      end

      def assigned_children(parent)
        Array.wrap(parent[@target_name])
      end

      def assign_children(parent, children)
        raise NotImplementedError
      end

      def changed_children(parent)
        assigned_children(parent).select(&:changed_for_autosave?)
      end

      def build_child(parent, attributes)
        build_scope(parent).new(attributes)
      end

      def scope(parent)
        scope_for(parent, :scope) || derive_class_name.constantize
      end

      def build_scope(parent)
        scope_for(parent, :build_scope) || scope(parent)
      end

      def find_scope(parent)
        scope_for(parent, :find_scope) || scope(parent)
      end

      def scope_for(parent, key)
        parent._nested_attribute_scopes ||= {}
        parent._nested_attribute_scopes[[self, key]] ||= begin
          scope = @options[key]
          scope.respond_to?(:call) ? parent.instance_eval(&scope) : scope
        end
      end

      def derive_class_name
        raise NotImplementedError
      end

      def fetch_child(parent, id)
        assigned = assigned_children(parent).detect { |r| r.id.to_s == id.to_s }
        return assigned if assigned

        if child = find_scope(parent).find_by_id(id)
          add_child(parent, child)
          child
        else
          raise RecordNotFound, "could not find a child record with id '#{id}' for '#{@target_name}'"
        end
      end

      def truthy?(value)
        @boolean_type_caster ||= TypeCaster.get(:boolean)
        @boolean_type_caster.type_cast_from_user(value)
      end

      def reject?(parent, attributes)
        result = case @reject_if
        when :all_blank
          attributes.all? { |key, value| key == '_destroy' || value.blank? }
        when Proc
          @reject_if.call(attributes)
        when Symbol
          parent.method(@reject_if).arity == 0 ? parent.send(@reject_if) : parent.send(@reject_if, attributes)
        end
        result
      end

      def valid_options
        [:build_scope, :find_scope, :scope, :allow_destroy, :reject_if]
      end

      def add_errors_to_parent(parent, child, index)
        if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new("6.1")
          child.errors.each do |error|
            attribute = translate_error_attribute(error.attribute, index)
            parent.errors.add(attribute, error.message)
          end
        else
          child.errors.each do |attribute, message|
            attribute = translate_error_attribute(attribute, index)
            parent.errors.add(attribute, message)
            parent.errors[attribute].uniq!
          end
        end
      end

      def translate_error_attribute(attribute, index)
        @index_errors ? "#{@target_name}[#{index}].#{attribute}" : "#{@target_name}.#{attribute}"
      end
    end

  end

end
