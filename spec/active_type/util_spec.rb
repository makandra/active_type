require 'spec_helper'

module UtilSpec

  class BaseRecord < ActiveRecord::Base
    self.table_name = 'records'
  end

  class ExtendedRecord < ActiveType::Record[BaseRecord]

    attribute :virtual_string
    after_initialize :set_virtual_string

    def set_virtual_string
      self.virtual_string = "persisted_string is #{persisted_string}"
    end

  end

  class Parent < ActiveRecord::Base
    self.table_name = 'sti_records'
  end

  class Child < Parent
  end

  class ChildSibling < Parent
  end

  class ExtendedChild < ActiveType::Record[Child]
  end

end

describe ActiveType::Util do
  
  describe '.cast' do

    describe 'for a relation' do
    
      it 'casts a scope to a scope of another class' do
        record = UtilSpec::BaseRecord.create!(persisted_string: 'foo')
        base_scope = UtilSpec::BaseRecord.where(persisted_string: 'foo')
        casted_scope = ActiveType::Util.cast(base_scope, UtilSpec::ExtendedRecord)
        casted_scope.build.should be_a(UtilSpec::ExtendedRecord)
        found_record = casted_scope.find(record.id)
        found_record.persisted_string.should == 'foo'
        found_record.should be_a(UtilSpec::ExtendedRecord)
      end

      it 'preserves existing scope conditions' do
        match = UtilSpec::BaseRecord.create!(persisted_string: 'foo')
        no_match = UtilSpec::BaseRecord.create!(persisted_string: 'bar')
        base_scope = UtilSpec::BaseRecord.where(persisted_string: 'foo')
        casted_scope = ActiveType::Util.cast(base_scope, UtilSpec::ExtendedRecord)
        casted_match = UtilSpec::ExtendedRecord.find(match.id)
        casted_scope.to_a.should == [casted_match]
      end

    end

    describe 'for a record type' do

      it 'casts a base record to an extended record' do
        base_record = UtilSpec::BaseRecord.create!(persisted_string: 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        extended_record.should be_a(UtilSpec::ExtendedRecord)
        extended_record.should be_persisted
        extended_record.id.should be_present
        extended_record.id.should == base_record.id
        extended_record.persisted_string.should == 'foo'
      end

      it 'casts an extended record to a base record' do
        extended_record = UtilSpec::ExtendedRecord.create!(persisted_string: 'foo')
        base_record = ActiveType::Util.cast(extended_record, UtilSpec::BaseRecord)
        base_record.should be_a(UtilSpec::BaseRecord)
        base_record.should be_persisted
        base_record.id.should be_present
        base_record.id.should == extended_record.id
        base_record.persisted_string.should == 'foo'
      end

      it 'calls after_initialize callbacks of the cast target' do
        base_record = UtilSpec::BaseRecord.create!(persisted_string: 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        extended_record.virtual_string.should be_present
      end

      it 'lets after_initialize callbacks access attributes (bug in ActiveRecord#becomes)' do
        base_record = UtilSpec::BaseRecord.create!(persisted_string: 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        extended_record.virtual_string.should == 'persisted_string is foo'
      end

      it 'preserves the #type of an STI record that is casted to an ExtendedRecord' do
        child_record = UtilSpec::Child.create!(persisted_string: 'foo')
        extended_child_record = ActiveType::Util.cast(child_record, UtilSpec::ExtendedChild)
        extended_child_record.should be_a(UtilSpec::ExtendedChild)
        extended_child_record.type.should == 'UtilSpec::Child'
      end

      it 'changes the #type of an STI record when casted to another type in the hierarchy' do
        child_record = UtilSpec::Child.create!(persisted_string: 'foo')
        child_sibling_record = ActiveType::Util.cast(child_record, UtilSpec::ChildSibling)
        child_sibling_record.should be_a(UtilSpec::ChildSibling)
        child_sibling_record.type.should == 'UtilSpec::Child'
      end

      it 'preserves dirty tracking flags' do
        base_record = UtilSpec::BaseRecord.create!(persisted_string: 'foo')
        base_record.changes.should == {}
        base_record.persisted_string = 'bar'
        base_record.changes.should == { 'persisted_string' => ['foo', 'bar'] }
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        extended_record.should be_a(UtilSpec::ExtendedRecord)
        extended_record.changes.should == { 'persisted_string' => ['foo', 'bar'] }
      end

    end

  end

  it "exposes all methods through ActiveType's root namespace" do
    ActiveType.should respond_to(:cast)
  end

end
