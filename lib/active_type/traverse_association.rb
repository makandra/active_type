module ActiveType
  module TraverseAssociation

    class UnsupportedAssociation < StandardError; end
    class UnknownAssociation < StandardError; end

    def traverse_association(*associations)

      scope = scoped({})

      associations.each_with_index do |association, index|

        reflection = scope.reflect_on_association(association) or raise UnknownAssociation, "Could not find association: #{self.name}##{association}"
        foreign_key = reflection.respond_to?(:foreign_key) ? reflection.foreign_key : reflection.primary_key_name

        raise NotImplementedError if reflection.options[:conditions].present?

        if reflection.macro == :belongs_to # belongs_to
          ids = scope.collect_column(foreign_key, :distinct => true)
          scope = ActiveType::Util.exclusive_query(reflection.klass, :id => ids)
        elsif reflection.macro == :has_many || reflection.macro == :has_one
          if reflection.through_reflection # has_many :through
            scope = scope.traverse_association(reflection.through_reflection.name, reflection.source_reflection.name)
          else # has_many or has_one
            ids = scope.collect_ids
            scope = ActiveType::Util.exclusive_query(reflection.klass, foreign_key => ids)
          end
        else
          raise UnsupportedAssociation, "Unsupport association type: #{reflection.macro}"
        end
      end

      scope

    end

    ActiveRecord::Base.extend(self)

  end
end
