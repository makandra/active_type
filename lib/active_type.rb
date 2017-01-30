# encoding: utf-8

require 'active_type/version'


load_now = proc do
  require 'active_type/util'
  require 'active_type/record'
  require 'active_type/object'

  if ActiveRecord::VERSION::STRING == '4.2.0'
    raise(<<-MESSAGE.strip_heredoc)
      ActiveType is not compatible with ActiveRecord 4.2.0. Please upgrade to 4.2.1
      For details see https://github.com/makandra/active_type/issues/31
    MESSAGE
  end
end


if defined?(Rails) && defined?(ActiveSupport)
  # If we are inside Rails, we'll assume active_record will be required anyways
  # in this case, wait until then, to not mess with ActiveRecord configuration.
  # (compare https://github.com/rails/rails/issues/23589)
  ActiveSupport.on_load(:active_record) do
    load_now.call()
  end
else
  # No Rails.
  require 'active_record'
  load_now.call()
end
