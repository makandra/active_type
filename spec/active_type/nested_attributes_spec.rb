require 'spec_helper'

module NestedAttributesSpec

  class Record < ActiveRecord::Base
    attr_accessor :fail_on_save, :error

    before_save :check_fail

    validate :check_error

    private

    def check_fail
      if fail_on_save == true
        false
      end
    end

    def check_error
      if error.present?
        errors.add(:base, error)
      end
    end
  end

end

class GlobalRecord < ActiveRecord::Base
  self.table_name = 'records'
end


describe "ActiveType::Object" do

  context '.nests_many' do

    let(:extra_options) { {} }

    subject do
      extra = extra_options
      Class.new(ActiveType::Object) do
        nests_many :records, extra.merge(:scope => NestedAttributesSpec::Record)

        def bad(attributes)
          attributes[:persisted_string] =~ /bad/
        end

        def reject_all
          true
        end

      end.new
    end

    def should_assign_and_persist(assign, persist = assign)
      subject.records.map(&:persisted_string).should == assign
      subject.save.should be_true
      NestedAttributesSpec::Record.all.map(&:persisted_string).should =~ persist
    end


    context 'with no records assigned' do

      it 'can save' do
        subject.save.should be_true
      end

    end

    context 'assigning nil' do

      it 'will do nothing' do
        subject.records_attributes = nil
        subject.records.should be_nil
      end

    end

    context 'when assigning records without ids' do

      it 'builds single nested records' do
        subject.records_attributes = { 1 => {:persisted_string => "string"} }

        should_assign_and_persist(["string"])
      end

      it 'builds multiple nested records when given a hash of attributes, ordered by key' do
        subject.records_attributes = {
          3 => {:persisted_string => "string 3"},
          1 => {:persisted_string => "string 1"},
          2 => {:persisted_string => "string 2"},
        }

        should_assign_and_persist(["string 1", "string 2", "string 3"])
      end

      it 'builds multiple nested records when given an array of attributes' do
        subject.records_attributes = [
          {:persisted_string => "string 1"},
          {:persisted_string => "string 2"},
          {:persisted_string => "string 3"},
        ]

        should_assign_and_persist(["string 1", "string 2", "string 3"])
      end

      it 'does not build records that match a :reject_if proc' do
        extra_options.merge!(:reject_if => proc { |attributes| attributes['persisted_string'] =~ /bad/ })
        subject.records_attributes = {
          1 => {:persisted_string => "good value"},
          2 => {:persisted_string => "bad value"},
        }

        should_assign_and_persist(["good value"])
      end

      it 'does not build records that match a :reject_if method taking attributes' do
        extra_options.merge!(:reject_if => :bad)
        subject.records_attributes = {
          1 => {:persisted_string => "good value"},
          2 => {:persisted_string => "bad value"},
        }

        should_assign_and_persist(["good value"])
      end

      it 'does not build records that match a :reject_if method taking attributes' do
        extra_options.merge!(:reject_if => :bad)
        subject.records_attributes = {
          1 => {:persisted_string => "good value"},
          2 => {:persisted_string => "bad value"},
        }

        should_assign_and_persist(["good value"])
      end

      it 'does not build records that match a :reject_if method taking no attributes' do
        extra_options.merge!(:reject_if => :reject_all)
        subject.records_attributes = {
          1 => {:persisted_string => "good value"},
          2 => {:persisted_string => "bad value"},
        }

        should_assign_and_persist([])
      end

      it 'does not build records that match a :reject_if all_blank' do
        extra_options.merge!(:reject_if => :all_blank)
        subject.records_attributes = {
          1 => {:persisted_string => "good value"},
          2 => {},
        }

        should_assign_and_persist(["good value"])
      end

      it 'appends to existing records' do
        subject.records = [NestedAttributesSpec::Record.create!(:persisted_string => "existing string")]
        subject.records_attributes = { 1 => {:persisted_string => "new string"} }

        should_assign_and_persist(["existing string", "new string"])
      end

      it 'leaves unassigned records alone' do
        NestedAttributesSpec::Record.create!(:persisted_string => "unassigned")
        subject.records_attributes = { 1 => {:persisted_string => "string"} }

        should_assign_and_persist(["string"], ["unassigned", "string"])
      end

      it 'does not destroy records on _destroy => trueish by default' do
        existing = NestedAttributesSpec::Record.create!(:persisted_string => 'do not delete this')

        subject.records_attributes = [
          { :id => existing.id, :_destroy => "true" },
        ]
        should_assign_and_persist(["do not delete this"], ["do not delete this"])
        subject.records.size.should == 1
      end

      it 'destroys records on _destroy => trueish if allowed' do
        extra_options.merge!(:allow_destroy => true)
        existing = [
          NestedAttributesSpec::Record.create!(:persisted_string => 'delete this'),
          NestedAttributesSpec::Record.create!(:persisted_string => 'delete this'),
          NestedAttributesSpec::Record.create!(:persisted_string => 'delete this'),
          NestedAttributesSpec::Record.create!(:persisted_string => 'keep this'),
        ]

        subject.records = existing.first(2) # assign some

        subject.records_attributes = [
          { :id => existing[0].id, :_destroy => "true" },
          { :id => existing[1].id, :_destroy => 1 },
          { :id => existing[2].id, :_destroy => "1" },
          { :id => existing[3].id, :_destroy => "0" },
        ]
        should_assign_and_persist(["delete this", "delete this", "delete this", "keep this"], ["keep this"])
        subject.records.size.should == 1
      end

    end

    context 'when assigning records with ids' do

      it 'updates the record with the id if already assigned' do
        subject.records = [
          NestedAttributesSpec::Record.new(:persisted_string => "existing 1"),
          NestedAttributesSpec::Record.new(:persisted_string => "existing 2"),
          NestedAttributesSpec::Record.new(:persisted_string => "existing 3"),
        ]
        subject.records[0].id = 100
        subject.records[1].id = 101
        subject.records[2].id = 102

        subject.records_attributes = { 1 => {:id => 101, :persisted_string => "updated"} }

        should_assign_and_persist(["existing 1", "updated", "existing 3"])
      end

      it 'does not update records matching a reject_if proc' do
        extra_options.merge!(:reject_if => :bad)
        subject.records = [
          NestedAttributesSpec::Record.new(:persisted_string => "existing 1"),
          NestedAttributesSpec::Record.new(:persisted_string => "existing 2"),
        ]
        subject.records[0].id = 100
        subject.records[1].id = 101

        subject.records_attributes = [
          {:id => 100, :persisted_string => "good"},
          {:id => 101, :persisted_string => "bad"}
        ]

        should_assign_and_persist(["good", "existing 2"])
      end

      it 'fetches the record with the id if not already assigned' do
        record = NestedAttributesSpec::Record.create!(:persisted_string => "existing string 1")
        subject.records = [
          NestedAttributesSpec::Record.new(:persisted_string => "existing string 2"),
        ]
        subject.records[0].id = record.id + 1

        subject.records_attributes = { 1 => {:id => record.id, :persisted_string => "updated string"} }

        should_assign_and_persist(["existing string 2", "updated string"])
      end

      it 'raises an error if the child record does not exist' do
        expect do
          subject.records_attributes = { 1 => {:id => 1, :persisted_string => "updated string"} }
        end.to raise_error(ActiveType::NestedAttributes::RecordNotFound, "could not find a child record with id '1' for 'records'")
      end

    end

    context 'save failure' do

      it 'returns false on #save and does not save the child' do
        # it should also cause a rollback, but that will not work with sqlite3
        subject.records = [
          NestedAttributesSpec::Record.new(:fail_on_save => true),
        ]

        subject.save.should be_false
        NestedAttributesSpec::Record.count.should == 0

        # note that other children would be saved and not be rolled back
        # this is also true for regular nested attributes
      end

    end

    context 'validations' do

      describe '#valid?' do

        it 'is true if there are no records assigned' do
          subject.valid?.should be_true
        end

        it 'is true if all records are valid' do
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new,
          ]

          subject.valid?.should be_true
        end

        it 'is false if one child has an error' do
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new(:error => 'some error'),
          ]

          subject.valid?.should be_false
        end

        it 'is copies the error to the record' do
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new(:error => 'some error'),
          ]

          subject.valid?
          subject.errors["records.base"].should == ['some error']
        end

      end

    end

  end


  context '.nests_one' do

    let(:extra_options) { {} }

    subject do
      extra = extra_options
      Class.new(ActiveType::Object) do
        nests_one :record, extra.merge(:scope => NestedAttributesSpec::Record)

        def bad(attributes)
          attributes[:persisted_string] =~ /bad/
        end
      end.new
    end

    def should_assign_and_persist(assign, persist = assign)
      if assign
        subject.record.should be_present
        subject.record.persisted_string.should == assign
      else
        subject.record.should be_nil
      end
      subject.save.should be_true
      NestedAttributesSpec::Record.all.map(&:persisted_string).should == (persist ? [persist] : [])
    end


    context 'with no record assigned' do

      it 'can save' do
        subject.save.should be_true
      end

    end

    context 'assigning nil' do

      it 'will do nothing' do
        subject.record_attributes = nil
        subject.record.should be_nil
      end

    end

    context 'when assigning a records without an id' do

      it 'builds a nested records' do
        subject.record_attributes = { :persisted_string => "string" }

        should_assign_and_persist("string")
      end

      it 'does not build a record that matchs a :reject_if proc' do
        extra_options.merge!(:reject_if => proc { |attributes| attributes['persisted_string'] =~ /bad/ })
        subject.record_attributes = { :persisted_string => "bad" }

        should_assign_and_persist(nil)
      end


      it 'updates an assigned record' do
        subject.record = NestedAttributesSpec::Record.create!(:persisted_string => "existing string")
        subject.record_attributes = { :persisted_string => "new string" }

        should_assign_and_persist("new string")
      end

      it 'does not update a record that matchs a :reject_if proc' do
        extra_options.merge!(:reject_if => proc { |attributes| attributes['persisted_string'] =~ /bad/ })
        subject.record = NestedAttributesSpec::Record.create!(:persisted_string => "existing string")
        subject.record_attributes = { :persisted_string => "bad" }

        should_assign_and_persist("existing string")
      end


    end

    context 'when assigning a records with an id' do

      let(:record) { record = NestedAttributesSpec::Record.create!(:persisted_string => "existing string") }

      it 'updates the record if already assigned' do
        subject.record = record

        subject.record_attributes = { :id => record.id, :persisted_string => "updated string"}

        should_assign_and_persist("updated string")
      end

      it 'fetches the record with the id if not already assigned' do
        subject.record_attributes = { :id => record.id, :persisted_string => "updated string" }

        should_assign_and_persist("updated string")
      end

      it 'does not destroy records on _destroy => true by default' do
        subject.record_attributes = { :id => record.id, :_destroy => true }

        should_assign_and_persist("existing string", "existing string")
      end

      it 'destroys records on _destroy => true if allowed' do
        extra_options.merge!(:allow_destroy => true)
        subject.record_attributes = { :id => record.id, :_destroy => true }

        should_assign_and_persist("existing string", nil)
        subject.record.should == nil
      end

      it 'raises an error if the assigned record does not match the id' do
        expect do
          subject.record = NestedAttributesSpec::Record.create!
          subject.record_attributes = { :id => record.id, :persisted_string => "updated string" }
        end.to raise_error(ActiveType::NestedAttributes::AssignmentError, "child record 'record' did not match id '#{record.id}'")
      end

      it 'raises an error if a record with the id cannot be found' do
        expect do
          subject.record_attributes = { :id => 1, :persisted_string => "updated string" }
        end.to raise_error(ActiveType::NestedAttributes::RecordNotFound, "could not find a child record with id '1' for 'record'")
      end

    end

    context 'validations' do

      describe '#valid?' do

        it 'is true if there is no record assigned' do
          subject.valid?.should be_true
        end

        it 'is true if the assigned record is valid' do
          subject.record = NestedAttributesSpec::Record.new

          subject.valid?.should be_true
        end

        it 'is false the assigned record has an error' do
          subject.record = NestedAttributesSpec::Record.new(:error => 'some error')

          subject.valid?.should be_false
        end

        it 'is copies the error to the record' do
          subject.record = NestedAttributesSpec::Record.new(:error => 'some error')

          subject.valid?
          subject.errors["record.base"].should == ['some error']
        end

      end

    end

  end

  context '.nests_one/nests_many' do

    context 'inheritance' do

      let(:base_class) do
        Class.new(ActiveType::Object) do
          nests_one :record, :scope => NestedAttributesSpec::Record
        end
      end

      it 'works across inheritance hierarchy' do
        subject = Class.new(base_class) do
          nests_one :another_record, :scope => NestedAttributesSpec::Record
        end.new

        subject.record_attributes = { :persisted_string => "string" }
        subject.another_record_attributes = {:persisted_string => "another string"}

        subject.record.persisted_string.should == "string"
        subject.another_record.persisted_string.should == "another string"
        subject.save.should be_true
        NestedAttributesSpec::Record.all.map(&:persisted_string).should =~ ["string", "another string"]
      end

      it 'allows overriding of the accessor' do
        subject = Class.new(base_class) do
          def record_attributes=(attributes)
            reached
            super
          end

          def reached
          end
        end.new

        subject.should_receive(:reached)
        subject.record_attributes = { :persisted_string => "string" }

        subject.record.persisted_string.should == "string"
        subject.save.should be_true
        NestedAttributesSpec::Record.all.map(&:persisted_string).should =~ ["string"]
      end

    end

    context 'when not giving a scope' do

      subject do
        Class.new(ActiveType::Object) do
          nests_many :global_records
          nests_one :global_record
        end.new
      end

      it 'infers the scope from the association name' do
        subject.global_records_attributes = { 1 => { :persisted_string => "string" } }
        subject.global_record_attributes = { :persisted_string => "string" }

        subject.global_records.first.should be_a(GlobalRecord)
        subject.global_record.should be_a(GlobalRecord)
      end

    end

    context 'when giving a scope via a proc' do

      subject do
        Class.new(ActiveType::Object) do
          nests_many :records, :scope => proc { NestedAttributesSpec::Record.where("persisted_string <> 'invisible'") }
          nests_one :record, :scope => proc { NestedAttributesSpec::Record }
        end.new
      end

      it 'uses the scope' do
        subject.records_attributes = { 1 => { :persisted_string => "string" } }
        subject.record_attributes = { :persisted_string => "string" }

        subject.records.first.should be_a(NestedAttributesSpec::Record)
        subject.record.should be_a(NestedAttributesSpec::Record)
      end

      it 'raises an error if the child record is not found via the scope' do
        record = NestedAttributesSpec::Record.create!(:persisted_string => 'invisible')

        expect do
          subject.records_attributes = { 1 => { :id => record.id, :persisted_string => "updated string" } }
        end.to raise_error(ActiveType::NestedAttributes::RecordNotFound, "could not find a child record with id '#{record.id}' for 'records'")
      end
    end

  end


end
