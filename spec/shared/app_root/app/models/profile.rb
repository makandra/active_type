class Profile < ActiveRecord::Base
  include AllowSettingIdOnCreate

  belongs_to :user

  has_defaults :trashed => false

end
