require 'active_type/type_caster'

module ActiveType

  class InvalidAttributeNameError < ::StandardError; end
  class MissingAttributeError < ::StandardError; end
  class ArgumentError < ::ArgumentError; end

  module VirtualAttributes

    module Serialization
      extend ActiveSupport::Concern

      def init_with(coder)
        if coder['virtual_attributes'].present?
          @virtual_attributes = coder['virtual_attributes']
        end
        super(coder)
      end

      def encode_with(coder)
        coder['virtual_attributes'] = @virtual_attributes
        coder['active_type_yaml_version'] = 1
        super(coder)
      end
    end

    class VirtualColumn

      def initialize(name, type_caster, options)
        @name = name
        @type_caster = type_caster
        @options = options
      end

      def type_cast(value)
        @type_caster.type_cast_from_user(value)
      end

      def default_value(object)
        default = @options[:default]
        default.respond_to?(:call) ? object.instance_eval(&default) : default
      end

    end

    class Builder

      def initialize(owner, mod)
        @owner = owner
        @module = mod
      end

      def build(name, type, options)
        validate_attribute_name!(name)
        options.assert_valid_keys(:default)
        add_virtual_column(name, type, options)
        build_reader(name)
        build_writer(name)
        build_dirty_tracking_methods(name)
      end

      private

      def add_virtual_column(name, type, options)
        type_caster = TypeCaster.get(type)
        column = VirtualColumn.new(name, type_caster, options.slice(:default))
        @owner.virtual_columns_hash = @owner.virtual_columns_hash.merge(name.to_s => column)
      end

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

      # Methods for compatibility with gems expecting the ActiveModel::Dirty API.
      def build_dirty_tracking_methods(name)
        return if name.to_s == 'attribute' # clashes with internal methods

        @module.module_eval <<-BODY, __FILE__, __LINE__ + 1
          def #{name}_was
            virtual_attributes_were["#{name}"]
          end
        BODY

        @module.module_eval <<-BODY, __FILE__, __LINE__ + 1
          def #{name}_changed?
            #{name} != virtual_attributes_were["#{name}"]
          end
        BODY

        @module.module_eval <<-BODY, __FILE__, __LINE__ + 1
          def #{name}_will_change!
            # no-op
          end
        BODY
      end

      def validate_attribute_name!(name)
        unless name.to_s =~ /\A[A-Za-z0-9_]*\z/
          raise InvalidAttributeNameError.new("'#{name}' is not a valid name for a virtual attribute")
        end
      end

    end

    def self.deep_dup(hash)
      result = hash.dup
      result.each do |key, value|
        result[key] = value.dup if value.duplicable?
      end
      result
    end

    extend ActiveSupport::Concern

    included do
      include ActiveType::VirtualAttributes::Serialization
      class_attribute :virtual_columns_hash
      self.virtual_columns_hash = {}

      class << self
        if method_defined?(:attribute)
          alias_method :ar_attribute, :attribute
        end
      end
    end

    def initialize_dup(other)
      @virtual_attributes_cache = {}
      @virtual_attributes = VirtualAttributes.deep_dup(virtual_attributes)
      @virtual_attributes_were = VirtualAttributes.deep_dup(virtual_attributes_were)

      super
    end

    def virtual_attributes
      @virtual_attributes ||= {}
    end

    def virtual_attributes_were
      @virtual_attributes_were ||= {}
    end

    def virtual_attributes_cache
      @virtual_attributes_cache ||= {}
    end

    def read_existing_virtual_attribute(name, &block_when_not_virtual)
      if self.singleton_class._has_virtual_column?(name)
        read_virtual_attribute(name)
      else
        yield
      end
    end

    def write_existing_virtual_attribute(name, value, &block_when_not_virtual)
      if self.singleton_class._has_virtual_column?(name)
        write_virtual_attribute(name, value)
      else
        yield
      end
    end

    def [](name)
      read_existing_virtual_attribute(name) { super }
    end

    if ActiveRecord::VERSION::STRING >= '4.2.0'
      def _read_attribute(name)
        read_existing_virtual_attribute(name) { super }
      end
    end

    if ActiveRecord::VERSION::STRING < '4.2.0' || ActiveRecord::VERSION::STRING >= '6.1.0'
      # in 6.1, read_attribute does not call _read_attribute
      def read_attribute(name)
        read_existing_virtual_attribute(name) { super }
      end
    end

    def []=(name, value)
      write_existing_virtual_attribute(name, value) { super }
    end

    if ActiveRecord::VERSION::STRING >= '5.2.0'
      def _write_attribute(name, value)
        write_existing_virtual_attribute(name, value) { super }
      end
    end

    if ActiveRecord::VERSION::STRING < '5.2.0' || ActiveRecord::VERSION::STRING >= '6.1.0'
      # in 6.1, write_attribute does not call _write_attribute
      def write_attribute(name, value)
        write_existing_virtual_attribute(name, value) { super }
      end
    end

    def attributes
      self.class._virtual_column_names.each_with_object(super) do |name, attrs|
        attrs[name] = read_virtual_attribute(name)
      end
    end

    def changed?
      self.class._virtual_column_names.any? { |attr| virtual_attributes_were[attr] != send(attr) } || super
    end

    def changes
      changes = self.class._virtual_column_names.each_with_object({}) do |attr, changes|
        current_value = send(attr)
        previous_value = virtual_attributes_were[attr]
        changes[attr] = [previous_value, current_value] if  previous_value != current_value
      end

      super.merge(changes)
    end

    if ActiveRecord::VERSION::MAJOR >= 4
      def changes_applied
        super

        virtual_attributes.each do |attr, _|
          value = read_virtual_attribute(attr)
          virtual_attributes_were[attr] = value.duplicable? ? value.clone : value
        end
      end
    end

    def read_virtual_attribute(name)
      name = name.to_s
      if virtual_attributes_cache.has_key?(name)
        virtual_attributes_cache[name]
      else
        virtual_attributes_cache[name] = begin
          virtual_column = self.singleton_class._virtual_column(name)
          raw_value = virtual_attributes.fetch(name) { virtual_column.default_value(self) }
          virtual_column.type_cast(raw_value)
        end
      end
    end

    def write_virtual_attribute(name, value)
      name = name.to_s
      virtual_attributes_cache.delete(name)
      virtual_attributes[name] = value
    end

    # Returns the contents of the record as a nicely formatted string.
    def inspect
      inspection = attributes.collect do |name, value|
        "#{name}: #{VirtualAttributes.attribute_for_inspect(value)}"
      end.sort.compact.join(", ")
      "#<#{self.class} #{inspection}>"
    end

    def self.attribute_for_inspect(value)
      if value.is_a?(String) && value.length > 50
        "#{value[0, 50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.to_formatted_s(:db)}")
      elsif value.is_a?(Array) && value.size > 10
        inspected = value.first(10).inspect
        %(#{inspected[0...-1]}, ...])
      else
        value.inspect
      end
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

        Builder.new(self, generated_virtual_attribute_methods).build(name, type, options)
      end

    end

  end

end
