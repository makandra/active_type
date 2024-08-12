require 'active_type/mutation_after_cast_error'

module ActiveType
  module Util

    # This object is used as a substitute for a record's @attributes.
    # Reading from the original @attributes is still allowed, to enable
    # `#inspect` and similar functions.
    # But the @attributes can no longer be mutated and will raise instead.
    class UnmutableAttributes

      attr_reader :original_attributes
      delegate :to_hash, to: :original_attributes

      def initialize(attributes)
        @original_attributes = attributes
      end

      def fetch_value(key)
        original_attributes.fetch_value(key)
      end

      def [](key)
        original_attributes[key]
      end

      def key?(key)
        original_attributes.key?(key)
      end

      def keys
        original_attributes.keys
      end

      def method_missing(*args)
        raise MutationAfterCastError, 'Changing a record that has been used to create an ActiveType::Record could have unexpected side effects!'
      end

    end
  end
end
