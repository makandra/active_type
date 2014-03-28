module ActiveType

  module NoTable

    extend ActiveSupport::Concern


    module ClassMethods

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

    def create(*)
      true
    end

    def create_record(*)
      true
    end

    def update(*)
      true
    end

    def update_record(*)
      true
    end

    def destroy
      @destroyed = true
      freeze
    end

    def reload
      self
    end

  end

end
