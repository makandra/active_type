module ActiveType

  module NoTable

    extend ActiveSupport::Concern


    module ClassMethods

      def primary_key
        nil
      end

      def column_types
        []
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
        true
      end

      def _update_record(*)
        true
      end
    end

  end

end
