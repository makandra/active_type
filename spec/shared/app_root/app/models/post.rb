class Post < ActiveRecord::Base
  include AllowSettingIdOnCreate

  belongs_to :topic
  belongs_to :author, :class_name => 'User'

  has_defaults :trashed => false

end
