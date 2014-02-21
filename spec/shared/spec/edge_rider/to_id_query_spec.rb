require 'spec_helper'

describe ActiveType::ToIdQuery do

  describe '#to_id_query' do

    it 'should simplify a scope to a IN query that selects IDs' do
      Forum.create!(:id => 1, :name => 'Name 1')
      Forum.create!(:id => 2, :name => 'Name 2')
      Forum.create!(:id => 3, :name => 'Name 2')
      scope = Forum.scoped(:conditions => { :name => 'Name 2' })
      scope.to_id_query.to_sql.should =~ ActiveType::Development.selects_star_with_conditions_pattern('forums', /`forums`\.`id` IN \(2,\s*3\)/)
    end

    it 'should resolve and lose any JOINs' do
      Forum.create!(:id => 1, :name => 'A')
      Forum.create!(:id => 2, :name => 'B')
      Forum.create!(:id => 3, :name => 'A')
      Topic.create!(:id => 100, :forum_id => 1)
      Topic.create!(:id => 101, :forum_id => 1)
      Topic.create!(:id => 102, :forum_id => 2)
      Topic.create!(:id => 103, :forum_id => 3)
      scope = Topic.scoped(:joins => :forum, :conditions => 'forums.name = "A"')
      scope.to_id_query.to_sql.should =~ ActiveType::Development.selects_star_with_conditions_pattern('topics', /`topics`\.`id` IN \(100,\s*101,\s*103\)/)
    end

  end

end
