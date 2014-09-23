module ActiveType
  class TypeCaster

    def self.get(connection, sql_type)
      native_caster = if ActiveRecord::VERSION::STRING < '4.2'
        NativeCasters::DelegateToColumn.new(sql_type)
      else
        NativeCasters::DelegateToType.new(sql_type, connection)
      end
      new(sql_type, native_caster)
    end

    def initialize(sql_type, native_caster)
      @sql_type = sql_type
      @native_caster = native_caster
    end

    def type_cast_from_user(value)
      # For some reason, Rails defines additional type casting logic
      # outside the classes that have that responsibility.
      case @sql_type
      when :integer
        if value == ''
          nil
        else
          native_type_cast_from_user(value)
        end
      when :timestamp, :datetime
        time = native_type_cast_from_user(value)
        if time && ActiveRecord::Base.time_zone_aware_attributes
          time = ActiveSupport::TimeWithZone.new(nil, Time.zone, time)
        end
        time
      else
        native_type_cast_from_user(value)
      end
    end

    def native_type_cast_from_user(value)
      @native_caster.type_cast_from_user(value)
    end

    module NativeCasters

      # Adapter for Rails 3.0 - 4.1.
      # In these versions, casting logic lives in ActiveRecord::ConnectionAdapters::Colum
      class DelegateToColumn

        def initialize(sql_type)
          @column = ActiveRecord::ConnectionAdapters::Column.new('foo', nil, sql_type)
        end

        def type_cast_from_user(value)
          @column.type_cast(value)
        end

      end

      # Adapter for Rails 4.2+.
      # In these versions, casting logic lives in subclasses of ActiveRecord::Type::Value
      class DelegateToType

        def initialize(sql_type, connection)
          @active_record_type = connection.lookup_cast_type(sql_type)
        end

        def type_cast_from_user(value)
          @active_record_type.type_cast_from_user(value)
        end

      end

    end

  end

end
