module ActiveModel::Validations

  def errors_on(attribute, options = {})
    valid_args = [options[:context]].compact
    self.valid?(*valid_args)

    [self.errors[attribute]].flatten.compact
  end

  alias :error_on :errors_on

end
