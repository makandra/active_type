module ActiveType
  module Util

    def cast(object, klass)
      if object.is_a?(ActiveRecord::Relation)
        cast_relation(object, klass)
      elsif object.is_a?(ActiveRecord::Base)
        cast_record(object, klass)
      else
        raise ArgumentError, "Don't know how to cast #{object.inspect}"
      end
    end

    def scoped(klass_or_relation)
      klass_or_relation.where(nil)
    end

    private

    def cast_record(record, klass)
      # record.becomes(klass).dup
      klass.new do |casted|
        using_single_table_inheritance = using_single_table_inheritance?(klass, casted)

        casted.instance_variable_set(:@mutations_from_database, record.instance_variable_get(:@mutations_from_database))
        # Rails 3.2, 4.2
        casted.instance_variable_set(:@attributes, record.instance_variable_get(:@attributes))
        # Rails 3.2
        casted.instance_variable_set(:@attributes_cache, record.instance_variable_get(:@attributes_cache))
        # Rails 4.2
        casted.instance_variable_set(:@changed_attributes, record.instance_variable_get(:@changed_attributes))
        # Rails 5.0
        casted.instance_variable_set(:@mutation_tracker, record.instance_variable_get(:@mutation_tracker))
        # Rails 3.2, 4.2
        casted.instance_variable_set(:@new_record, record.new_record?)
        # Rails 3.2, 4.2
        casted.instance_variable_set(:@destroyed, record.destroyed?)

        casted.instance_variable_set(:@association_cache, record.instance_variable_get(:@association_cache))

        # Rails 3.2, 4.2
        errors = record.errors
        if errors.kind_of? ActiveModel::Errors
          errors = errors.dup
          # otherwise attributes defined in ActiveType::Record
          # won't be visible to `errors.add`
          errors.instance_variable_set(:@base, casted)
        end
        casted.instance_variable_set(:@errors, errors)

        casted[klass.inheritance_column] = klass.sti_name if using_single_table_inheritance
      end
    end

    # Backport for Rails 3.2
    def using_single_table_inheritance?(klass, record)
      inheritance_column = klass.inheritance_column
      record[inheritance_column].present? && record.has_attribute?(inheritance_column)
    end

    def cast_relation(relation, klass)
      scoped(klass).merge(scoped(relation))
    end

    extend self

  end
end
