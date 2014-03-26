module ActiveType

  class InvalidAttributeNameError < StandardError; end
  class MissingAttributeError < StandardError; end

  module VirtualAttributes

    class VirtualColumn < ActiveRecord::ConnectionAdapters::Column

      def initialize(name, type)
        @name = name
        @type = type
      end

      def type_cast(value)
        if @type == :integer
          case value
          when FalseClass
            0
          when TrueClass
            1
          when ""
            nil
          else
            value.to_i
          end
        else
          super
        end
      end

    end

    class AccessorGenerator

      def initialize(mod)
        @module = mod
      end

      def generate_accessors(name)
        validate_attribute_name!(name)
        generate_reader(name)
        generate_writer(name)
      end

      private

      def generate_reader(name)
        @module.module_eval <<-BODY, __FILE__, __LINE__ + 1
          def #{name}
            read_virtual_attribute('#{name}')
          end
        BODY
      end

      def generate_writer(name)
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

    end


    extend ActiveSupport::Concern

    included do
      class_attribute :virtual_columns_hash
      self.virtual_columns_hash = {}
    end

    def read_virtual_attribute(name)
      name = name.to_s
      @virtual_attributes_cache[name] ||= begin
        self.singleton_class._virtual_column(name).type_cast(@virtual_attributes[name])
      end
    end

    def write_virtual_attribute(name, value)
      name = name.to_s
      @virtual_attributes_cache.delete(name)
      @virtual_attributes[name] = value
    end

    private

    def initialize_virtual_attributes
      @virtual_attributes = {}
      @virtual_attributes_cache = {}
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

      def virtual_attribute(name, type)
        self.virtual_columns_hash = virtual_columns_hash.merge(name.to_s => VirtualColumn.new(name, type))
        AccessorGenerator.new(generated_attribute_methods).generate_accessors(name)
      end

    end

  end

end
