module ActiveType

  module NoTable

    extend ActiveSupport::Concern


    module ClassMethods

      def primary_key
        nil
      end

      def column_types
        {}
      end

      def columns
        []
      end

      def destroy(*)
        new
      end

      def destroy_all(*)
        []
      end


      def find_by_sql(*)
        []
      end

    end

    def id
      nil
    end

    def attribute_names
      []
    end

    def attribute_for_inspect(attr_name)
      value = read_virtual_attribute(attr_name)

      if value.is_a?(String) && value.length > 50
        "#{value[0, 50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.to_s(:db)}")
      elsif value.is_a?(Array) && value.size > 10
        inspected = value.first(10).inspect
        %(#{inspected[0...-1]}, ...])
      else
        value.inspect
      end
    end

    # Returns the contents of the record as a nicely formatted string.
    def inspect
      inspection = self.class._virtual_column_names.collect { |name|
                         "#{name}: #{attribute_for_inspect(name)}"
                     }.compact.join(", ")
      "#<#{self.class} #{inspection}>"
    end

    def transaction(&block)
      @_current_transaction_records ||= []
      yield
    end

    def destroy
      @destroyed = true
      freeze
    end

    def reload
      self
    end


    private

    def create(*)
      true
    end

    def update(*)
      true
    end

    if ActiveRecord::Base.private_method_defined?(:create_record)
      def create_record(*)
        true
      end

      def update_record(*)
        true
      end
    else
      def _create_record(*)
        @new_record = false
        true
      end

      def _update_record(*)
        true
      end
    end

  end

end
