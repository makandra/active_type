class Topic < ActiveRecord::Base
  include AllowSettingIdOnCreate

  belongs_to :forum
  belongs_to :active_forum, :conditions => { :trashed => false }, :class_name => 'Forum'
  has_many :posts
  belongs_to :author, :class_name => 'User'
  has_many :post_authors, :through => :posts

  has_defaults :trashed => false

end
