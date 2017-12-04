require 'spec_helper'

module NestedAttributesSpec

  class Record < ActiveRecord::Base
    attr_accessor :fail_on_save, :error

    before_save :check_fail

    validate :check_error

    private

    def check_fail
      if fail_on_save == true
        if ActiveRecord::VERSION::MAJOR >= 5
          throw :abort
        else
          false
        end
      end
    end

    def check_error
      if error.present?
        errors.add(:base, error)
      end
    end
  end

  class UUIDRecord < ActiveRecord::Base
    self.primary_key = :id

    before_create :generate_uuid

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
  end

end

class GlobalRecord < ActiveRecord::Base
  self.table_name = 'records'
end


describe "ActiveType::Object" do

  context '.nests_many' do

    let(:extra_options) { {} }
    let(:record_type) { NestedAttributesSpec::Record }

    subject do
      extra = extra_options
      record_type = self.record_type
      Class.new(ActiveType::Object) do
        nests_many :records, extra.merge(:scope => record_type)

        def bad(attributes)
          attributes[:persisted_string] =~ /bad/
        end

        def reject_all
          true
        end

      end.new
    end

    def should_assign_and_persist(assign, persist = assign)
      expect(subject.records.map(&:persisted_string)).to eq(assign)
      expect(subject.save).to eq(true)
      expect(record_type.all.map(&:persisted_string)).to match_array(persist)
    end


    context 'with no records assigned' do

      it 'can save' do
        expect(subject.save).to eq(true)
      end

    end

    context 'assigning nil' do

      it 'will do nothing' do
        subject.records_attributes = nil
        expect(subject.records).to be_nil
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
        expect(subject.records.size).to eq(1)
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
        expect(subject.records.size).to eq(1)
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

        expect(subject.save).to be_falsey
        expect(NestedAttributesSpec::Record.count).to eq(0)

        # note that other children would be saved and not be rolled back
        # this is also true for regular nested attributes
      end

    end

    context 'validations' do

      describe '#valid?' do

        it 'is true if there are no records assigned' do
          expect(subject.valid?).to eq(true)
        end

        it 'is true if all records are valid' do
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new,
          ]

          expect(subject.valid?).to eq(true)
        end

        it 'is false if one child has an error' do
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new(:error => 'some error'),
          ]

          expect(subject.valid?).to be_falsey
        end

        it 'is copies the error to the record' do
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new(:error => 'some error'),
          ]

          subject.valid?
          expect(subject.errors["records.base"]).to eq(['some error'])
        end

        it 'index errors when index_errors option is used' do
          extra_options.merge!(:index_errors => true)
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new(:error => 'some error')
          ]

          subject.valid?
          expect(subject.errors["records.base"]).not_to eq(['some error'])
          expect(subject.errors["records[1].base"]).to eq(['some error'])
        end

        it 'index errors when global flag is set' do
          old_attribute_config = ActiveRecord::Base.index_nested_attribute_errors

          ActiveRecord::Base.index_nested_attribute_errors = true
          subject.records = [
            NestedAttributesSpec::Record.new,
            NestedAttributesSpec::Record.new(:error => 'some error')
          ]

          subject.valid?
          expect(subject.errors["records.base"]).not_to eq(['some error'])
          expect(subject.errors["records[1].base"]).to eq(['some error'])

          ActiveRecord::Base.index_nested_attribute_errors = old_attribute_config
        end if ActiveRecord::Base.respond_to?(:index_nested_attribute_errors)

      end

    end

    context 'using a string primary key' do

      let(:record_type) { NestedAttributesSpec::UUIDRecord }

      context 'when assigning records without ids' do

        it 'builds multiple nested records when given a hash of attributes, ordered by key' do
          subject.records_attributes = {
            3 => {:persisted_string => "string 3"},
            1 => {:persisted_string => "string 1"},
            2 => {:persisted_string => "string 2"},
          }

          should_assign_and_persist(["string 1", "string 2", "string 3"])
        end

        it 'appends to existing records' do
          subject.records = [NestedAttributesSpec::UUIDRecord.create!(:persisted_string => "existing string")]
          subject.records_attributes = { 1 => {:persisted_string => "new string"} }

          should_assign_and_persist(["existing string", "new string"])
        end

        it 'destroys records on _destroy => trueish if allowed' do
          extra_options.merge!(:allow_destroy => true)
          existing = [
            NestedAttributesSpec::UUIDRecord.create!(:persisted_string => 'delete this'),
            NestedAttributesSpec::UUIDRecord.create!(:persisted_string => 'delete this'),
            NestedAttributesSpec::UUIDRecord.create!(:persisted_string => 'delete this'),
            NestedAttributesSpec::UUIDRecord.create!(:persisted_string => 'keep this'),
          ]

          subject.records = existing.first(2) # assign some

          subject.records_attributes = [
            { :id => existing[0].id, :_destroy => "true" },
            { :id => existing[1].id, :_destroy => 1 },
            { :id => existing[2].id, :_destroy => "1" },
            { :id => existing[3].id, :_destroy => "0" },
          ]
          should_assign_and_persist(["delete this", "delete this", "delete this", "keep this"], ["keep this"])
          expect(subject.records.size).to eq(1)
        end

      end

      context 'when assigning records with ids' do

        it 'updates the record with the id if already assigned' do
          subject.records = [
            NestedAttributesSpec::UUIDRecord.new(:persisted_string => "existing 1"),
            NestedAttributesSpec::UUIDRecord.new(:persisted_string => "existing 2"),
            NestedAttributesSpec::UUIDRecord.new(:persisted_string => "existing 3"),
          ]
          subject.records[0].id = "ddcf8aed-6e99-4acb-b1d6-d1300f711773"
          subject.records[1].id = "32ddfce3-c46b-4a55-9246-ee2a13a6fb3c"
          subject.records[2].id = "067fbacb-4f39-4c6b-ab26-51bd5cc2e30e"

          subject.records_attributes = { 1 => {:id => "32ddfce3-c46b-4a55-9246-ee2a13a6fb3c", :persisted_string => "updated"} }

          should_assign_and_persist(["existing 1", "updated", "existing 3"])
        end

        it 'fetches the record with the id if not already assigned' do
          record = NestedAttributesSpec::UUIDRecord.create!(:id => "5df009ae-55cf-4d65-a589-abe4102525f6", :persisted_string => "existing string 1")
          subject.records = [
            NestedAttributesSpec::UUIDRecord.new(:persisted_string => "existing string 2"),
          ]
          subject.records[0].id = "b373a32d-512a-4236-a37e-678e43359b75"

          subject.records_attributes = { 1 => {:id => record.id, :persisted_string => "updated string"} }

          subject.save

          should_assign_and_persist(["existing string 2", "updated string"])
        end

        it 'raises an error if the child record does not exist' do
          expect do
            subject.records_attributes = { 1 => {:id => "4bed6028-f900-4298-aa82-cb387e61b97d", :persisted_string => "updated string"} }
          end.to raise_error(ActiveType::NestedAttributes::RecordNotFound, "could not find a child record with id '4bed6028-f900-4298-aa82-cb387e61b97d' for 'records'")
        end

      end
    end
  end


  context '.nests_one' do

    let(:extra_options) { {} }
    let(:record_type) { NestedAttributesSpec::Record }

    subject do
      extra = extra_options
      record_type = self.record_type
      Class.new(ActiveType::Object) do
        nests_one :record, extra.merge(:scope => record_type)

        def bad(attributes)
          attributes[:persisted_string] =~ /bad/
        end
      end.new
    end

    def should_assign_and_persist(assign, persist = assign)
      if assign
        expect(subject.record).to be_present
        expect(subject.record.persisted_string).to eq(assign)
      else
        expect(subject.record).to be_nil
      end
      expect(subject.save).to eq(true)
      expect(record_type.all.map(&:persisted_string)).to eq(persist ? [persist] : [])
    end


    context 'with no record assigned' do

      it 'can save' do
        expect(subject.save).to eq(true)
      end

    end

    context 'assigning nil' do

      it 'will do nothing' do
        subject.record_attributes = nil
        expect(subject.record).to be_nil
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
        expect(subject.record).to eq(nil)
      end

      it 'do not raises an error when the id is a string of an existent record' do
        expect do
          subject.record = record
          subject.record_attributes = { :id => "#{record.id}", :persisted_string => "updated string" }
          should_assign_and_persist("updated string")
        end.not_to raise_error
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
          expect(subject.valid?).to eq(true)
        end

        it 'is true if the assigned record is valid' do
          subject.record = NestedAttributesSpec::Record.new

          expect(subject.valid?).to eq(true)
        end

        it 'is false the assigned record has an error' do
          subject.record = NestedAttributesSpec::Record.new(:error => 'some error')

          expect(subject.valid?).to be_falsey
        end

        it 'is copies the error to the record' do
          subject.record = NestedAttributesSpec::Record.new(:error => 'some error')

          subject.valid?
          expect(subject.errors["record.base"]).to eq(['some error'])
        end

      end

    end

    context 'using string primary key' do

      let(:record_type) { NestedAttributesSpec::UUIDRecord }

      context 'when assigning a records without an id' do

        it 'builds a nested records' do
          subject.record_attributes = { :persisted_string => "string" }

          should_assign_and_persist("string")
        end

        it 'updates an assigned record' do
          subject.record = NestedAttributesSpec::UUIDRecord.create!(:persisted_string => "existing string")
          subject.record_attributes = { :persisted_string => "new string" }

          should_assign_and_persist("new string")
        end

      end


      context 'when assigning a records with an id' do

        let(:record) { record = NestedAttributesSpec::UUIDRecord.create!(:persisted_string => "existing string") }

        it 'updates the record if already assigned' do
          subject.record = record

          subject.record_attributes = { :id => record.id, :persisted_string => "updated string" }

          should_assign_and_persist("updated string")
        end

        it 'destroys records on _destroy => true if allowed' do
          extra_options.merge!(:allow_destroy => true)
          subject.record_attributes = { :id => record.id, :_destroy => true }

          should_assign_and_persist("existing string", nil)
          expect(subject.record).to eq(nil)
        end

        it 'raises an error if the assigned record does not match the id' do
          expect do
            subject.record = NestedAttributesSpec::UUIDRecord.create!
            subject.record_attributes = { :id => record.id, :persisted_string => "updated string" }
          end.to raise_error(ActiveType::NestedAttributes::AssignmentError, "child record 'record' did not match id '#{record.id}'")
        end

        it 'raises an error if a record with the id cannot be found' do
          expect do
            subject.record_attributes = { :id => '0c9b997c-61fa-4d8d-9386-574c6558c2ad', :persisted_string => "updated string" }
          end.to raise_error(ActiveType::NestedAttributes::RecordNotFound, "could not find a child record with id '0c9b997c-61fa-4d8d-9386-574c6558c2ad' for 'record'")
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

        expect(subject.record.persisted_string).to eq("string")
        expect(subject.another_record.persisted_string).to eq("another string")
        expect(subject.save).to eq(true)
        expect(NestedAttributesSpec::Record.all.map(&:persisted_string)).to match_array(["string", "another string"])
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

        expect(subject).to receive(:reached)
        subject.record_attributes = { :persisted_string => "string" }

        expect(subject.record.persisted_string).to eq("string")
        expect(subject.save).to eq(true)
        expect(NestedAttributesSpec::Record.all.map(&:persisted_string)).to match_array(["string"])
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

        expect(subject.global_records.first).to be_a(GlobalRecord)
        expect(subject.global_record).to be_a(GlobalRecord)
      end

    end

    context 'when giving a scope via a proc' do

      subject do
        Class.new(ActiveType::Object) do
          nests_many :records, :scope => proc { NestedAttributesSpec::Record.where("persisted_string <> 'invisible'") }
          nests_one :record, :scope => proc { NestedAttributesSpec::Record }

          attribute :default_value, :string
          nests_many :default_records, :scope => proc { NestedAttributesSpec::Record.where(:persisted_string => default_value) }
        end.new
      end

      it 'uses the scope' do
        subject.records_attributes = { 1 => { :persisted_string => "string" } }
        subject.record_attributes = { :persisted_string => "string" }

        expect(subject.records.first).to be_a(NestedAttributesSpec::Record)
        expect(subject.record).to be_a(NestedAttributesSpec::Record)
      end

      it 'evals the scope lazily in the instance' do
        subject.default_value = "default value"
        subject.default_records_attributes = [{}]

        expect(subject.default_records.map(&:persisted_string)).to eq(["default value"])
      end

      it 'caches the scope' do
        subject.default_value = "default value"
        subject.default_records_attributes = [{}]
        subject.default_value = "another default value"
        subject.default_records_attributes = [{}]

        expect(subject.default_records.map(&:persisted_string)).to eq(["default value", "default value"])
      end

      it 'caches the scope per instance' do
        subject.default_value = "default value"
        subject.default_records_attributes = [{}]

        another_subject = subject.class.new
        another_subject.default_value = "another default value"
        another_subject.default_records_attributes = [{}]

        expect(another_subject.default_records.map(&:persisted_string)).to eq(["another default value"])
      end

      it 'raises an error if the child record is not found via the scope' do
        record = NestedAttributesSpec::Record.create!(:persisted_string => 'invisible')

        expect do
          subject.records_attributes = { 1 => { :id => record.id, :persisted_string => "updated string" } }
        end.to raise_error(ActiveType::NestedAttributes::RecordNotFound, "could not find a child record with id '#{record.id}' for 'records'")
      end
    end

    context 'separate scopes for build and find' do

      subject do
        find_scope = proc { NestedAttributesSpec::Record.where(:persisted_string => 'findable') }
        build_scope = proc { NestedAttributesSpec::Record.where(:persisted_string => 'buildable') }
        Class.new(ActiveType::Object) do
          nests_many :records, :build_scope => build_scope, :find_scope => find_scope
          nests_one :record, :build_scope => build_scope, :find_scope => find_scope
        end.new
      end

      it 'nests_many uses the find_scope to find records' do
        record = NestedAttributesSpec::Record.create!(:persisted_string => 'findable')
        hidden_record = NestedAttributesSpec::Record.create!(:persisted_string => 'hidden')

        expect do
          subject.records_attributes = [{ :id => record.id, :persisted_string => 'updated' }]
        end.to_not raise_error

        expect do
          subject.records_attributes = [{ :id => hidden_record.id, :persisted_string => 'updated' }]
        end.to raise_error(ActiveType::NestedAttributes::RecordNotFound)
      end

      it 'nests_many uses the build_scope to find records' do
        subject.records_attributes = [{}]
        expect(subject.records.first.persisted_string).to eq('buildable')
      end

      it 'nests_one uses the find_scope to find records' do
        record = NestedAttributesSpec::Record.create!(:persisted_string => 'findable')
        hidden_record = NestedAttributesSpec::Record.create!(:persisted_string => 'hidden')

        expect do
          subject.record_attributes = { :id => record.id, :persisted_string => 'updated' }
        end.to_not raise_error

        subject.record = nil
        expect do
          subject.record_attributes = { :id => hidden_record.id, :persisted_string => 'updated' }
        end.to raise_error(ActiveType::NestedAttributes::RecordNotFound)
      end

      it 'nests_one uses the build_scope to find records' do
        subject.record_attributes = {}
        expect(subject.record.persisted_string).to eq('buildable')
      end

    end

    context 'defaults' do

      subject do
        Class.new(ActiveType::Object) do
          nests_many :records, :default => proc { [default_record] }
          nests_one :record, :default => proc { default_record }

          nests_many :global_records

          nests_many :other_records, :scope => proc { NestedAttributesSpec::Record }
          nests_one :other_record, :scope => proc { NestedAttributesSpec::Record }

          nests_many :records_without_default, :default => nil

          def default_record
            NestedAttributesSpec::Record.new(:persisted_string => "default")
          end
        end.new
      end

      it 'accepts a :default value' do
        expect(subject.records.map(&:persisted_string)).to eq(["default"])
        expect(subject.record.persisted_string).to eq("default")
      end

      it 'computes the value lazily' do
        allow(subject).to receive_messages :default_record => NestedAttributesSpec::Record.new(:persisted_string => "other default")
        expect(subject.records.map(&:persisted_string)).to eq(["other default"])
        expect(subject.record.persisted_string).to eq("other default")
      end

    end

  end

end

describe "ActiveType::Record" do

  it 'supports nested attributes' do
    expect(ActiveType::Record).to respond_to(:nests_one)
    expect(ActiveType::Record).to respond_to(:nests_many)
  end

end

describe "ActiveType::Record" do

  it 'supports nested attributes' do
    expect(ActiveType::Record[NestedAttributesSpec::Record]).to respond_to(:nests_one)
    expect(ActiveType::Record[NestedAttributesSpec::Record]).to respond_to(:nests_many)
  end

end
