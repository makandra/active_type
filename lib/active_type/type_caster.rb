module ActiveType
  class TypeCaster

    def self.get(connection, sql_type)
      implementation = ActiveRecord::VERSION::STRING < '4.2' ? DelegateToColumn : DelegateToType
      implementation.new(connection, sql_type)
    end

    class Base

      def initialize(sql_type)
        @sql_type = sql_type
      end

      def type_cast_from_user(value)
        # For some reason, Rails defines additional type casting logic
        # outside the classes that have that responsibility.
        case @sql_type
        when :integer
          case value
          when FalseClass
            0
          when TrueClass
            1
          when "", nil
            nil
          else
            value.to_i
          end
        when :timestamp, :datetime
          if ActiveRecord::Base.time_zone_aware_attributes
            time = delegated_type_cast_from_user(value)
            if time
              ActiveSupport::TimeWithZone.new(nil, Time.zone, time)
            else
              time
            end
          else
            delegated_type_cast_from_user(value)
          end
        when nil
          value
        else
          delegated_type_cast_from_user(value)
        end
      end

      def delegated_type_cast_from_user(value)
        raise "implement me"
      end

    end

    class DelegateToColumn < Base

      def initialize(_connection, sql_type)
        super(sql_type)
        @column = ActiveRecord::ConnectionAdapters::Column.new('foo', nil, sql_type)
      end

      def delegated_type_cast_from_user(value)
        @column.type_cast(value)
      end

    end

    class DelegateToType < Base

      def initialize(connection, sql_type)
        super(sql_type)
        @rails_cast_type = connection.lookup_cast_type(sql_type)
      end

      def delegated_type_cast_from_user(value)
        @rails_cast_type.type_cast_from_user(value)
      end

    end

  end
end
