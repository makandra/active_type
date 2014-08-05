require 'active_type/nested_attributes/association'

module ActiveType

  module NestedAttributes

    class NestsManyAssociation < Association

      def assign_attributes(parent, attributes_collection)
        return if attributes_collection.nil?

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
          next if reject?(parent, attributes)

          destroy = truthy?(attributes.delete(:_destroy)) && @allow_destroy

          if id = attributes.delete(:id)
            child = fetch_child(parent, id.to_i)
            if destroy
              child.mark_for_destruction
            else
              child.attributes = attributes
            end
          elsif !destroy
            new_records << build_child(parent, attributes)
          end
        end

        add_children(parent, new_records)
      end


      private

      def add_child(parent, child)
        add_children(parent, [child])
      end

      def add_children(parent, children)
        parent[@target_name] = assigned_children(parent) + children
      end

      def assign_children(parent, children)
        parent[@target_name] = children
      end

      def derive_class_name
        @target_name.to_s.classify
      end

    end

  end

end
