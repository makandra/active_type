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
        @many = options.fetch(:many, target_name.to_s.pluralize == target_name.to_s)
        @allow_destroy = options.fetch(:allow_destroy, false)
        @reject_if = options[:reject_if]
      end

      def assign(record, attributes)
        return if attributes.nil?
        if @many
          assign_many(record, attributes)
        else
          assign_one(record, attributes)
        end
      end

      def save(record)
        keep = assigned_children(record)
        changed_children(record).each do |child|
          if child.marked_for_destruction?
            child.destroy if child.persisted?
            keep.delete(child)
          else
            child.save(:validate => false) or raise ActiveRecord::Rollback
          end
        end
        assign_children(record, keep)
      end

      def validate(record)
        changed_children(record).each do |child|
          unless child.valid?
            child.errors.each do |attribute, message|
              attribute = "#{@target_name}.#{attribute}"
              record.errors[attribute] << message
              record.errors[attribute].uniq!
            end
          end
        end
      end

      private

      def assign_many(record, attributes_collection)
        unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
          raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
        end

        new_records = []

        if attributes_collection.is_a?(Hash)
          keys = attributes_collection.keys
          attributes_collection = if keys.include?('id') || keys.include?(:id)
            Array.wrap(attributes_collection)
          else
            attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
          end
        end

        attributes_collection.each do |attributes|
          attributes = attributes.with_indifferent_access
          next if reject?(record, attributes)

          destroy = truthy?(attributes.delete(:_destroy)) && @allow_destroy
          if id = attributes.delete(:id)
            child = fetch_child(record, id.to_i)
            if destroy
              child.mark_for_destruction
            else
              child.attributes = attributes
            end
          elsif !destroy
            new_records << build_child(attributes)
          end
        end

        append(record, new_records)
      end

      def assign_one(record, attributes)
        attributes = attributes.with_indifferent_access
        assigned = assigned_child(record)
        if assigned.is_a?(Array)
          raise AssignmentError, "did not expect '#{@target_name}' to be an array, pass :many => true?"
        end
        destroy = truthy?(attributes.delete(:_destroy)) && @allow_destroy
        if id = attributes.delete(:id)
          assigned ||= fetch_child(record, id.to_i)
          if assigned
            if assigned.id == id.to_i
              assigned.attributes = attributes
            else
              raise AssignmentError, "child record '#{@target_name}' did not match id '#{id}'"
            end
            if destroy
              assigned.mark_for_destruction
            end
          end
        elsif !destroy
          assigned ||= append(record, build_child({}))
          assigned.attributes = attributes
        end
      end

      def append(record, child_or_children)
        if @many
          record[@target_name] = assigned_children(record) + Array.wrap(child_or_children)
        else
          record[@target_name] = child_or_children
        end
      end

      def assigned_children(record)
        Array.wrap(record[@target_name])
      end

      def assign_children(record, children)
        if @many
          record[@target_name] = children
        else
          record[@target_name] = children.first
        end
      end

      def assigned_child(record)
        record[@target_name]
      end

      def changed_children(record)
        assigned_children(record).select(&:changed_for_autosave?)
      end

      def build_child(attributes)
        raise AssignmentError, "specify :scope to build records for '#{@target_name}'" unless @scope
        @scope.new(attributes)
      end

      def fetch_child(record, id)
        assigned = assigned_children(record).detect { |record| record.id == id }
        return assigned if assigned

        if @scope
          if child = @scope.find_by_id(id)
            append(record, child)
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

      def reject?(record, attributes)
        result = case @reject_if
        when :all_blank
          attributes.all? { |key, value| key == '_destroy' || value.blank? }
        when Proc
          @reject_if.call(attributes)
        when Symbol
          record.method(@reject_if).arity == 0 ? record.send(@reject_if) : record.send(@reject_if, attributes)
        end
        result
      end

    end

  end

end
