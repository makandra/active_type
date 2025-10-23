module ActiveType
  module NoTable

    extend ActiveSupport::Concern

    class DummySchemaCache

      def columns_hash(table_name)
        {}
      end

      def columns_hash?(table_name)
        return false
      end

      def data_source_exists?(table_name)
        false
      end

      def clear_data_source_cache!(table_name)
      end

    end

    class DummyPool < ActiveRecord::ConnectionAdapters::NullPool
      def with_pool_transaction_isolation_level(*_args)
        yield
      end
    end

    class DummyConnection < ActiveRecord::ConnectionAdapters::AbstractAdapter

      attr_reader :schema_cache

      def initialize(*)
        super
        @schema_cache = DummySchemaCache.new
        @pool = DummyPool.new
      end

      def self.quote_column_name(column_name)
        column_name.to_s
      end

      def pool
        @pool
      end

    end

    module ClassMethods

      def connection
        @connection ||= DummyConnection.new(nil)
      end

      def with_connection(**)
        yield(connection)
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

      def _query_by_sql(*)
        []
      end

      def cached_find_by(*)
        nil
      end

      def schema_cache
        DummySchemaCache.new
      end
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

    def _create_record(*)
      @new_record = false
      true
    end

    def _update_record(*)
      true
    end

  end
end
