require 'spec_helper'

describe ActiveType::TraverseAssociation do

  describe '#traverse_association' do

    it 'should traverse a belongs_to associations' do
      forum_1 = Forum.create!
      forum_2 = Forum.create!
      forum_3 = Forum.create!
      topic_1 = Topic.create!(:forum => forum_1)
      topic_2 = Topic.create!(:forum => forum_1)
      topic_3 = Topic.create!(:forum => forum_2)
      topic_4 = Topic.create!(:forum => forum_3)
      scope = Topic.scoped(:conditions => { :id => [ topic_2.id, topic_4.id ] })
      traversed_scope = scope.traverse_association(:forum)
      ActiveType::Util.scope?(traversed_scope).should be_true
      traversed_scope.to_a.should =~ [forum_1, forum_3]
    end

    it 'should raise an error when traversing a belongs_to association with conditions, until this is implemented' do
      forum = Forum.create!(:trashed => true)
      topic = Topic.create(:forum => forum)

      scope = Topic.scoped(:conditions => { :id => topic.id })
      expect { scope.traverse_association(:active_forum) }.to raise_error(NotImplementedError)
    end

    it 'should traverse a belongs_to association with conditions'

    it 'should traverse multiple belongs_to associations in different model classes' do
      forum_1 = Forum.create!
      forum_2 = Forum.create!
      forum_3 = Forum.create!
      topic_1 = Topic.create!(:forum => forum_1)
      topic_2 = Topic.create!(:forum => forum_2)
      topic_3 = Topic.create!(:forum => forum_3)
      post_1 = Post.create!(:topic => topic_1)
      post_2 = Post.create!(:topic => topic_2)
      post_3 = Post.create!(:topic => topic_3)
      scope = Post.scoped(:conditions => { :id => [post_1.id, post_3.id] })
      traversed_scope = scope.traverse_association(:topic, :forum)
      ActiveType::Util.scope?(traversed_scope).should be_true
      traversed_scope.to_a.should =~ [forum_1, forum_3]
    end

    it 'should traverse one or more has_many associations' do
      forum_1 = Forum.create!
      forum_2 = Forum.create!
      forum_3 = Forum.create!
      topic_1 = Topic.create!(:forum => forum_1)
      topic_2 = Topic.create!(:forum => forum_2)
      topic_3 = Topic.create!(:forum => forum_3)
      post_1 = Post.create!(:topic => topic_1)
      post_2 = Post.create!(:topic => topic_2)
      post_3a = Post.create!(:topic => topic_3)
      post_3b = Post.create!(:topic => topic_3)
      scope = Forum.scoped(:conditions => { :id => [forum_1.id, forum_3.id] })
      traversed_scope = scope.traverse_association(:topics, :posts)
      ActiveType::Util.scope?(traversed_scope).should be_true
      traversed_scope.to_a.should =~ [post_1, post_3a, post_3b]
    end

    it 'should raise an error when traversing a has_many association with conditions, until this is implemented' do
      forum = Forum.create!
      topic = Topic.create(:forum => forum, :trashed => true)

      scope = Forum.scoped(:conditions => { :id => forum.id })
      expect { scope.traverse_association(:active_topics) }.to raise_error(NotImplementedError)
    end

    it 'should traverse a has_many association with conditions'

    it 'should traverse a has_many :through association' do
      forum_1 = Forum.create!
      forum_2 = Forum.create!
      forum_3 = Forum.create!
      topic_1 = Topic.create!(:forum => forum_1)
      topic_2 = Topic.create!(:forum => forum_2)
      topic_3 = Topic.create!(:forum => forum_3)
      post_1 = Post.create!(:topic => topic_1)
      post_2 = Post.create!(:topic => topic_2)
      post_3a = Post.create!(:topic => topic_3)
      post_3b = Post.create!(:topic => topic_3)
      scope = Forum.scoped(:conditions => { :id => [forum_1.id, forum_3.id] })
      traversed_scope = scope.traverse_association(:posts)
      ActiveType::Util.scope?(traversed_scope).should be_true
      traversed_scope.to_a.should =~ [post_1, post_3a, post_3b]
    end

    it 'should traverse a has_one association' do
      user_1 = User.create!
      user_2 = User.create!
      user_3 = User.create!
      profile_1 = Profile.create!(:user => user_1)
      profile_2 = Profile.create!(:user => user_2)
      profile_3 = Profile.create!(:user => user_3)
      scope = User.scoped(:conditions => { :id => [user_2.id, user_3.id] })
      traversed_scope = scope.traverse_association(:profile)
      ActiveType::Util.scope?(traversed_scope).should be_true
      traversed_scope.to_a.should =~ [profile_2, profile_3]
    end

    it 'should raise an error when traversing a has_many association with conditions, until this is implemented' do
      user = User.create!
      profile = Profile.create(:user => user, :trashed => true)

      scope = User.scoped(:conditions => { :id => user.id })
      expect { scope.traverse_association(:active_profile) }.to raise_error(NotImplementedError)
    end

    it 'should traverse a has_one association with conditions'

    it 'should traverse up and down the same edges' do
      forum_1 = Forum.create!
      forum_2 = Forum.create!
      forum_3 = Forum.create!
      topic_1 = Topic.create!(:forum => forum_1)
      topic_2 = Topic.create!(:forum => forum_2)
      topic_3 = Topic.create!(:forum => forum_3)
      post_1 = Post.create!(:topic => topic_1)
      post_2 = Post.create!(:topic => topic_2)
      post_3a = Post.create!(:topic => topic_3)
      post_3b = Post.create!(:topic => topic_3)
      scope = Post.scoped(:conditions => { :id => [post_3a.id] })
      traversed_scope = scope.traverse_association(:topic, :forum, :topics, :posts)
      ActiveType::Util.scope?(traversed_scope).should be_true
      traversed_scope.to_a.should =~ [post_3a, post_3b]
    end

  end

end
