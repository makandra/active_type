require 'spec_helper'

describe ActiveType::PreloadAssociations do

  it 'should preload the given named associations so they are no longer fetched lazily' do
    forum = Forum.create!
    topic = Topic.create!(:forum => forum)
    post = Post.create!(:topic => topic)
    Forum.preload_associations([forum], :topics => :posts)
    Topic.should_not_receive(:new)
    Post.should_not_receive(:new)
    forum.topics.collect(&:posts)
  end

end
