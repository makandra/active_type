# Since our specs are mostly about working with IDs, this module can be
# included in an ActiveRecord model class to allow setting the :id attribute
# on create. This is forbidden by default.
# http://stackoverflow.com/questions/431617/overriding-id-on-create-in-activerecord
module AllowSettingIdOnCreate

  module RemoveIdFromProtectedAttributes
    def attributes_protected_by_default
      super - ['id']
    end
  end

  def self.included(base)
    if Rails.version < '3' # Rails 2 has this as an instance method
      base.send(:include, RemoveIdFromProtectedAttributes)
    else # Rails 3 has this as a class method
      base.send(:extend, RemoveIdFromProtectedAttributes)
    end
  end

end
