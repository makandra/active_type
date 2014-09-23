module ActiveType
  class TypeCaster

    def self.get(connection, sql_type)
      new(connection, sql_type)
    end

    if ActiveRecord::VERSION::STRING < '4.2'

      def initialize(_connection, sql_type)
        @column = ActiveRecord::ConnectionAdapters::Column.new('foo', nil, sql_type)
      end

      def type_cast_from_user(value)
        @column.type_cast(value)
      end

    else

      def initialize(connection, sql_type)
        @rails_cast_type = connection.lookup_cast_type(sql_type)
      end

      def type_cast_from_user(value)
        @rails_cast_type.type_cast_from_user(value)
      end

    end

  end
end
