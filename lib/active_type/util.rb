require 'active_type/not_castable_error'
require 'active_type/util/unmutable_attributes'

module ActiveType
  module Util

    def cast(object, klass, force: false)
      if object.is_a?(ActiveRecord::Relation)
        cast_relation(object, klass)
      elsif object.is_a?(ActiveRecord::Base)
        cast_record(object, klass, force: force)
      else
        raise ArgumentError, "Don't know how to cast #{object.inspect}"
      end
    end

    def scoped(klass_or_relation)
      klass_or_relation.where(nil)
    end

    private

    def cast_record(record, klass, force: false)
      if associations_touched?(record) && !force
        raise NotCastableError, 'Record has changes in its loaded associations!'
      end

      # record.becomes(klass).dup
      klass.new do |casted|
        using_single_table_inheritance = using_single_table_inheritance?(klass, casted)

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
        # Rails 5.2+
        casted.instance_variable_set(:@mutations_from_database, record.instance_variable_get(:@mutations_from_database))
        # Rails 6.1+
        casted.instance_variable_set(:@strict_loading, record.instance_variable_get(:@strict_loading))
        # Rails 7.0+
        casted.instance_variable_set(:@strict_loading_mode, record.instance_variable_get(:@strict_loading_mode))
        # Rails 1.0+
        casted.instance_variable_set(:@readonly, record.instance_variable_get(:@readonly))

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

        casted.after_cast(record) if casted.respond_to?(:after_cast)

        if !force
          make_record_unusable(record)
        end

        casted
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

    def associations_touched?(record)
      return false unless record.instance_variable_get(:@association_cache)

      !!record.instance_variable_get(:@association_cache)[:associated_records]&.target&.any? do |target|
        target.changed?
      end
    end

    def make_record_unusable(record)
      # Changing and saving the base record may lead to unexpected behaviour,
      # since the casted record may have different changes in its autosave
      # associations and will be saved to the same record in the database as
      # the casted record. Therefore we prevent that.
      original_attributes = record.instance_variable_get(:@attributes)
      record.instance_variable_set(:@attributes, UnmutableAttributes.new(original_attributes) )
    end

    extend self

  end
end
