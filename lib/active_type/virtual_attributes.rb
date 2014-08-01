require 'active_type/nested_attributes/builder'

module ActiveType

  class InvalidAttributeNameError < ::StandardError; end
  class MissingAttributeError < ::StandardError; end
  class ArgumentError < ::ArgumentError; end

  module VirtualAttributes

    class VirtualColumn < ActiveRecord::ConnectionAdapters::Column

      def initialize(name, type)
        @name = name
        @type = type
      end

      def type_cast(value)
        case @type
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
            time = super
            if time
              ActiveSupport::TimeWithZone.new(nil, Time.zone, time)
            else
              time
            end
          else
            super
          end
        when nil
          value
        else
          super
        end
      end

    end

    class Builder

      def initialize(owner, mod)
        @owner = owner
        @module = mod
      end

      def build(name, options)
        options.assert_valid_keys(:accepts_nested_attributes)
        validate_attribute_name!(name)
        build_reader(name)
        build_writer(name)
        build_extensions(name, options)
      end

      private

      def build_reader(name)
        @module.module_eval <<-BODY, __FILE__, __LINE__ + 1
          def #{name}
            read_virtual_attribute('#{name}')
          end

          def #{name}?
            read_virtual_attribute('#{name}').present?
          end
        BODY
      end

      def build_writer(name)
        @module.module_eval <<-BODY, __FILE__, __LINE__ + 1
          def #{name}=(value)
            write_virtual_attribute('#{name}', value)
          end
        BODY
      end

      def validate_attribute_name!(name)
        unless name.to_s =~ /\A[A-z0-9_]*\z/
          raise InvalidAttributeNameError.new("'#{name}' is not a valid name for a virtual attribute")
        end
      end

      def build_extensions(name, options)
        options.each do |extension, config|
          config = {} if config == true
          case extension
          when :accepts_nested_attributes
            NestedAttributes::Builder.new(@owner, @module).build(name, config)
          else
            raise ArgumentError, "unknown option #{extension.inspect}"
          end
        end
      end

    end


    extend ActiveSupport::Concern

    included do
      class_attribute :virtual_columns_hash
      self.virtual_columns_hash = {}
    end

    def virtual_attributes
      @virtual_attributes ||= {}
    end

    def virtual_attributes_cache
      @virtual_attributes_cache ||= {}
    end

    def [](name)
      if self.singleton_class._has_virtual_column?(name)
        read_virtual_attribute(name)
      else
        super
      end
    end

    def []=(name, value)
      if self.singleton_class._has_virtual_column?(name)
        write_virtual_attribute(name, value)
      else
        super
      end
    end

    def attributes
      self.class._virtual_column_names.each_with_object(super) do |name, attrs|
        attrs[name] = read_virtual_attribute(name)
      end
    end

    def read_virtual_attribute(name)
      name = name.to_s
      virtual_attributes_cache[name] ||= begin
        self.singleton_class._virtual_column(name).type_cast(virtual_attributes[name])
      end
    end

    def write_virtual_attribute(name, value)
      name = name.to_s
      virtual_attributes_cache.delete(name)
      virtual_attributes[name] = value
    end

    module ClassMethods

      def _virtual_column(name)
        virtual_columns_hash[name.to_s] || begin
          if defined?(super)
            super
          else
            raise MissingAttributeError.new("Undefined attribute '#{name}'")
          end
        end
      end

      def _virtual_column_names
        @virtual_column_names ||= begin
          names = virtual_columns_hash.keys
          if defined?(super)
            names += super
          end
          names
        end
      end

      def _has_virtual_column?(name)
        virtual_columns_hash.has_key?(name.to_s) || begin
          if defined?(super)
            super
          else
            false
          end
        end
      end

      def generated_virtual_attribute_methods
        @generated_virtual_attribute_methods ||= begin
          mod = Module.new
          include mod
          mod
        end
      end

      def attribute(name, *args)
        options = args.extract_options!
        type = args.first

        self.virtual_columns_hash = virtual_columns_hash.merge(name.to_s => VirtualColumn.new(name, type))
        Builder.new(self, generated_virtual_attribute_methods).build(name, options)
      end

    end

  end

end
