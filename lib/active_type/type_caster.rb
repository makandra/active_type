module ActiveType
  class TypeCaster

    def self.get(type)
      native_caster = if ActiveRecord::VERSION::STRING < '4.2'
        NativeCasters::DelegateToColumn.new(type)
      elsif ActiveRecord::VERSION::STRING < '5'
        NativeCasters::DelegateToRails4Type.new(type)
      else
        NativeCasters::DelegateToRails5Type.new(type)
      end
      new(type, native_caster)
    end

    def initialize(type, native_caster)
      @type = type
      @native_caster = native_caster
    end

    def type_cast_from_user(value)
      # For some reason, Rails defines additional type casting logic
      # outside the classes that have that responsibility.
      case @type
      when :integer
        if value == ''
          nil
        else
          native_type_cast_from_user(value)
        end
      when :timestamp, :datetime
        time = native_type_cast_from_user(value)
        if time && ActiveRecord::Base.time_zone_aware_attributes
          if time.zone == 'UTC'
            time = ActiveSupport::TimeWithZone.new(time, Time.zone)
          else
            time = ActiveSupport::TimeWithZone.new(nil, Time.zone, time)
          end
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
      # In these versions, casting logic lives in ActiveRecord::ConnectionAdapters::Column
      class DelegateToColumn

        def initialize(type)
          # the Column initializer expects type as returned from the database, and
          # resolves them to our types
          # fortunately, for all types wie support, type.to_s is a valid sql_type
          sql_type = type.to_s
          @column = ActiveRecord::ConnectionAdapters::Column.new('foo', nil, sql_type)
        end

        def type_cast_from_user(value)
          @column.type_cast(value)
        end

      end

      # Adapter for Rails 4.2+.
      # In these versions, casting logic lives in subclasses of ActiveRecord::Type::Value
      class DelegateToRails4Type

        def initialize(type)
          # The specified type (e.g. "string") may not necessary match the
          # native type ("varchar") expected by the connection adapter.
          # PostgreSQL is one of these. Perform a translation if the adapter
          # supports it (but don't turn a mysql boolean into a tinyint).
          @active_record_type = ActiveRecord::ConnectionAdapters::AbstractAdapter.new(nil).lookup_cast_type(type)
        end

        def type_cast_from_user(value)
          @active_record_type.type_cast_from_user(value)
        end

      end

      # Adapter for Rails 5+.
      # In these versions, casting logic lives in subclasses of ActiveRecord::Type::Value
      class DelegateToRails5Type

        def initialize(type)
          @active_record_type = lookup(type)
        end

        def type_cast_from_user(value)
          @active_record_type.cast(value)
        end

        private

        def lookup(type)
          if type.respond_to?(:cast)
            type
          else
            ActiveRecord::Type.lookup(type, adapter: nil)
          end
        rescue ::ArgumentError
          ActiveRecord::Type::Value.new
        end

      end

    end

  end

end
