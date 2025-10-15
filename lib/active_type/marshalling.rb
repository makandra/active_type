module ActiveType
  module Marshalling
    # With 7.1 rails defines its own marshal_dump and marshal_load methods,
    # which selectively only dump and load the record´s attributes and some more stuff, but not our @virtual_attributes.
    # Whether these new methods are actually used, depends on ActiveRecord::Marshalling.format_version
    # For format_version = 6.1 active record uses the default ruby implementation for dumping and loading.
    # For format_version = 7.1 active record uses a custom implementation, which we need to override.
    #
    # format_version can also be dynamically changed during runtime, on change we need to define or undefine our marshal_dump dynamically, because:
    # * We cannot check the format_version at runtime within marshal_dump or marshal_load,
    #   as we can´t just super to the default for the wrong version, because there is no method to super to.
    #   (The default implementation is a ruby internal, not a real method.)
    # * We cannot override the methods at load time only when format version is 7.1,
    #   because format version usually gets set after our initialisation and could change at any time.
    #
    # Two facts about ruby also help us with that (also see https://ruby-doc.org/core-2.6.8/Marshal.html):
    # * A custom marshal_load is only used, when marshal_dump is also defined. So we can keep marshal_dump always defined.
    #   (If either is missing, ruby will use _dump and _load)
    # * If a serialized object is dumped using _dump it will be loaded using _load, never marshal_load, so a record
    #   serialized with format_version = 6.1 using _dump, will always load using _load, ignoring whether marshal_load is defined or not.
    #   This ensures objects will always be deserialized with the method they were serialized with. We don´t need to worry about that.

    class << self
      attr_reader :format_version

      def format_version=(version)
        case version
        when 6.1
          Methods.remove_method(:marshal_dump) if Methods.method_defined?(:marshal_dump)
        when 7.1
          Methods.alias_method(:marshal_dump, :_marshal_dump_7_1)
        else
          raise ArgumentError, "Unknown marshalling format: #{version.inspect}"
        end
        @format_version = version
      end
    end

    module ActiveRecordMarshallingExtension
      def format_version=(version)
        ActiveType::Marshalling.format_version = version
        super(version)
      end
    end

    module Methods
      def _marshal_dump_7_1
        [super, @virtual_attributes]
      end

      def marshal_load(state)
        super_attributes, @virtual_attributes = state
        super(super_attributes)
      end
    end

  end
end

ActiveRecord::Marshalling.singleton_class.prepend(ActiveType::Marshalling::ActiveRecordMarshallingExtension)
# Set ActiveType´s format_version to ActiveRecord´s, in case ActiveRecord uses the default value, which is set before we are loaded.
ActiveType::Marshalling.format_version = ActiveRecord::Marshalling.format_version
