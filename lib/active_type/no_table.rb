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


      case ActiveRecord::VERSION::MAJOR
      when 3

        def all(*)
          []
        end

      when 4

        def find_by_sql(*)
          []
        end

      else
        raise NotImplementedError.new("Unsupported ActiveRecord version")
      end

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
