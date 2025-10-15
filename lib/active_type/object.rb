require 'active_type/no_table'
require 'active_type/virtual_attributes'
require 'active_type/nested_attributes'
require 'active_type/marshalling' if ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1

module ActiveType

  class Object < ActiveRecord::Base

    include NoTable
    include VirtualAttributes
    include NestedAttributes
    include Marshalling::Methods if ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1

  end

end
