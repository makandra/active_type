require 'active_record/errors'

module ActiveType

  module NestedAttributes

    class RecordNotFound < ActiveRecord::RecordNotFound; end
    class AssignmentError < ActiveRecord::RecordNotFound; end

    class Association

      def initialize(owner, target_name, options = {})
        @owner = owner
        @target_name = target_name.to_sym
        @scope = options[:scope]
        @allow_destroy = options.fetch(:allow_destroy, false)
        @reject_if = options[:reject_if]
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
        changed_children(parent).each do |child|
          unless child.valid?
            child.errors.each do |attribute, message|
              attribute = "#{@target_name}.#{attribute}"
              parent.errors[attribute] << message
              parent.errors[attribute].uniq!
            end
          end
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

      def build_child(attributes)
        raise AssignmentError, "specify :scope to build records for '#{@target_name}'" unless @scope
        @scope.new(attributes)
      end

      def fetch_child(parent, id)
        assigned = assigned_children(parent).detect { |r| r.id == id }
        return assigned if assigned

        if @scope
          if child = @scope.find_by_id(id)
            add_child(parent, child)
            child
          else
            raise RecordNotFound, "could not find a child record with id '#{id}' for '#{@target_name}'"
          end
        else
          raise RecordNotFound, "could not find a child record with id '#{id}' for '#{@target_name}'; perhaps you need to supply a :scope?"
        end
      end

      def truthy?(value)
        ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
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

    end

  end

end
