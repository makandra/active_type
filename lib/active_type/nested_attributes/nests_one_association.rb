require 'active_type/nested_attributes/association'

module ActiveType

  module NestedAttributes

    class AssignmentError < StandardError; end

    class NestsOneAssociation < Association

      def assign_attributes(parent, attributes)
        return if attributes.nil?
        attributes = attributes.with_indifferent_access
        return if reject?(parent, attributes)

        assigned_child = assigned_children(parent).first
        destroy = truthy?(attributes.delete(:_destroy)) && @allow_destroy

        if id = attributes.delete(:id)
          assigned_child ||= fetch_child(parent, id)
          if assigned_child
            assigned_child.id = id
            if assigned_child.id == assigned_child.id_was
              assigned_child.attributes = attributes
            else
              raise AssignmentError, "child record '#{@target_name}' did not match id '#{id}'"
            end
            if destroy
              assigned_child.mark_for_destruction
            end
          end
        elsif !destroy
          if assigned_child
            assigned_child.attributes = attributes
          else
            add_child(parent, build_child(parent, attributes))
          end
        end
      end


      private

      def add_child(parent, child)
        parent[@target_name] = child
      end

      def assign_children(parent, children)
        parent[@target_name] = children.first
      end

      def derive_class_name
        @target_name.to_s.camelize
      end

    end

  end

end
