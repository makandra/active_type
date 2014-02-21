require 'spec_helper'

describe ActiveType::CollectColumn do

  describe '#collect_column' do

    it 'should collect the given value from a scope' do
      Forum.create!(:id => 1, :name => 'Name 1')
      Forum.create!(:id => 2, :name => 'Name 2')
      Forum.create!(:id => 3, :name => 'Name 3')
      scope = Forum.scoped(:conditions => { :id => [2, 3] })
      scope.collect_column(:name).should =~ ['Name 2', 'Name 3']
    end

    it 'should collect the given value from an ActiveRecord class' do
      Forum.create!(:id => 1, :name => 'Name 1')
      Forum.create!(:id => 2, :name => 'Name 2')
      Forum.collect_column(:name).should =~ ['Name 1', 'Name 2']
    end

    it 'should cast the collected value to their equivalent Ruby type' do
      Post.create!
      Post.collect_column(:created_at).first.should be_a(Time)
    end

    it 'should not instantiate ActiveRecord objects when collecting values' do
      Forum.create!(:name => 'Name')
      Forum.should_not_receive(:new)
      Forum.collect_column(:name).should == ['Name']
    end

    it 'should qualify the column name to resolve any ambiguities' do
      expect { Topic.scoped(:joins => :forum).collect_column(:id) }.to_not raise_error
    end

    context 'with :distinct option' do

      it 'should return unique values' do
        Forum.create!(:id => 1, :name => 'Name 1')
        Forum.create!(:id => 2, :name => 'Name 2')
        Forum.create!(:id => 3, :name => 'Name 2')
        scope = Forum.scoped(:conditions => { :id => [2, 3] })
        scope.collect_column(:name, :distinct => true).should =~ ['Name 2']
      end

    end

  end

end
