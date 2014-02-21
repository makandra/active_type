module ActiveType
  module CollectIds

    class Uncollectable < StandardError; end

    module Array

      def collect_ids
        collect do |obj|
          case obj
            when Fixnum then obj
            when ActiveRecord::Base then obj.id
            else raise Uncollectable, "Cannot collect an id from #{obj.inspect}"
          end
        end
      end

    end

    ::Array.send(:include, Array)

    module ActiveRecordValue

      def collect_ids
        [id]
      end

    end

    ::ActiveRecord::Base.send(:include, ActiveRecordValue)

    module ActiveRecordScope

      def collect_ids
        collect_column(:id)
      end

    end

    ::ActiveRecord::Base.send(:extend, ActiveRecordScope)

    module Fixnum

      def collect_ids
        [self]
      end

    end

    ::Fixnum.send(:include, Fixnum)

  end
end
