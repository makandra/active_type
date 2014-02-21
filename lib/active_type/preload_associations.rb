module ActiveType
  module PreloadAssociations

    def preload_associations(*args)
      ActiveRecord::Associations::Preloader.new(*args).run
    end

    if ActiveRecord::Base.respond_to?(:preload_associations, true) # Rails 2.3, Rails 3.0
      ActiveRecord::Base.class_eval do
        class << self
          public :preload_associations
        end
      end
    else # Rails 3.2+
      ActiveRecord::Base.send(:extend, self)
    end

  end
end
