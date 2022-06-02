require 'spec_helper'

module UtilSpec

  class BaseRecord < ActiveRecord::Base
    self.table_name = 'records'
    has_many :associated_records
  end

  class ExtendedRecord < ActiveType::Record[BaseRecord]

    attribute :virtual_string
    attribute :virtual_string_for_validation
    after_initialize :set_virtual_string
    attr_reader :after_initialize_called

    def set_virtual_string
      @after_initialize_called = true
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

  class AssociatedRecord < ActiveRecord::Base
    belongs_to :base_record
  end

end

describe ActiveType::Util do

  describe '.cast' do

    describe 'for a relation' do

      it 'casts a scope to a scope of another class' do
        record = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        base_scope = UtilSpec::BaseRecord.where(:persisted_string => 'foo')
        casted_scope = ActiveType::Util.cast(base_scope, UtilSpec::ExtendedRecord)
        expect(casted_scope.build).to be_a(UtilSpec::ExtendedRecord)
        found_record = casted_scope.find(record.id)
        expect(found_record.persisted_string).to eq('foo')
        expect(found_record).to be_a(UtilSpec::ExtendedRecord)
      end

      it 'preserves existing scope conditions' do
        match = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        no_match = UtilSpec::BaseRecord.create!(:persisted_string => 'bar')
        base_scope = UtilSpec::BaseRecord.where(:persisted_string => 'foo')
        casted_scope = ActiveType::Util.cast(base_scope, UtilSpec::ExtendedRecord)
        casted_match = UtilSpec::ExtendedRecord.find(match.id)
        expect(casted_scope.to_a).to eq([casted_match])
      end

    end

    describe 'for a record type' do

      it 'casts a base record to an extended record' do
        base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        expect(extended_record).to be_a(UtilSpec::ExtendedRecord)
        expect(extended_record).to be_persisted
        expect(extended_record.id).to be_present
        expect(extended_record.id).to eq(base_record.id)
        expect(extended_record.persisted_string).to eq('foo')
      end

      context 'casting without copying the @association cache' do
        # When casting, the @association_cache is not copied, because of Issues #146, #147 and #148.
        # This may be unexpected to a user of Active Type, so we decided to not allow
        # casting of records with loaded associations if the associated records
        # already have changes.
        # Only the cases where the @association_cache is loaded and aware of changes could
        # be problematic.

        it 'casts a record that has unsaved changes in an associated record which is not loaded through the association' do
          base_record = UtilSpec::BaseRecord.create!
          associated_record = UtilSpec::AssociatedRecord.create!(:persisted_string => 'initial value', base_record: base_record)

          associated_record.persisted_string = 'changed value'

          expect{ ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord) }.not_to raise_error
        end

        it 'casts a record that has unsaved changes in its associations which are not known to the casted record' do
          base_record = UtilSpec::BaseRecord.create!
          UtilSpec::AssociatedRecord.create!(:persisted_string => 'initial value', base_record: base_record)

          associated_record = base_record.associated_records.first # <- this does not use the @associations_cache
          associated_record.persisted_string = 'changed value'

          expect{ ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord) }.not_to raise_error
        end

        it 'casts a record with loaded associations without changes' do
          base_record = UtilSpec::BaseRecord.create!
          UtilSpec::AssociatedRecord.create!(:persisted_string => 'initial value', base_record: base_record)

          base_record.associated_records.to_a

          expect{ ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord) }.not_to raise_error
        end

        it 'does not cast an record that has unsaved changes in its associations' do
          base_record = UtilSpec::BaseRecord.create!
          UtilSpec::AssociatedRecord.create!(:persisted_string => 'initial value', base_record: base_record)

          associated_record = base_record.associated_records.to_a.first
          associated_record.persisted_string = 'changed value'

          expect{ ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord) }.to raise_error ActiveType::NotCastableError
        end

        context 'with option force: true' do
          it 'casts an record that has unsaved changes in its associations' do
            base_record = UtilSpec::BaseRecord.create!
            UtilSpec::AssociatedRecord.create!(:persisted_string => 'initial value', base_record: base_record)

            associated_record = base_record.associated_records.to_a.first
            associated_record.persisted_string = 'changed value'

            expect{ ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord, force: true) }.not_to raise_error
          end
        end

      end

      it 'does not change the base record' do
        extended_record = UtilSpec::ExtendedRecord.create!(:persisted_string => 'foo')
        base_record = ActiveType::Util.cast(extended_record, UtilSpec::BaseRecord)
        expect(base_record).to be_a(UtilSpec::BaseRecord)
        expect(base_record).to be_persisted
        expect(base_record.id).to be_present
        expect(base_record.id).to eq(extended_record.id)
        expect(base_record.persisted_string).to eq('foo')
      end

      it 'calls after_initialize callbacks of the cast target' do
        base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        expect(extended_record.after_initialize_called).to eq true
      end

      it 'lets after_initialize callbacks access attributes (bug in ActiveRecord#becomes)' do
        base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        expect(extended_record.virtual_string).to eq('persisted_string is foo')
      end

      it 'preserves the #type of an STI record that is casted to an ExtendedRecord' do
        child_record = UtilSpec::Child.create!(:persisted_string => 'foo')
        extended_child_record = ActiveType::Util.cast(child_record, UtilSpec::ExtendedChild)
        expect(extended_child_record).to be_a(UtilSpec::ExtendedChild)
        expect(extended_child_record.type).to eq('UtilSpec::Child')
      end

      it 'changes the #type of an STI record when casted to another type in the hierarchy' do
        child_record = UtilSpec::Child.create!(:persisted_string => 'foo')
        child_sibling_record = ActiveType::Util.cast(child_record, UtilSpec::ChildSibling)
        expect(child_sibling_record).to be_a(UtilSpec::ChildSibling)
        expect(child_sibling_record.type).to eq('UtilSpec::ChildSibling')
      end

      it 'preserves dirty tracking flags' do
        base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        expect(base_record.changes).to eq({})
        base_record.persisted_string = 'bar'
        expect(base_record.changes).to eq({ 'persisted_string' => ['foo', 'bar'] })
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        expect(extended_record).to be_a(UtilSpec::ExtendedRecord)
        expect(extended_record.changes).to eq(
          'persisted_string' => ['foo', 'bar'],
          'virtual_string' => [nil, 'persisted_string is bar']
        )
      end

      it 'associates the error object correctly with the new type (BUGFIX)' do
        base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'foo')
        extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)
        expect {
          value = extended_record.virtual_string_for_validation
          extended_record.errors.add(:virtual_string_for_validation, :empty) if value.nil? || value.empty?
        }.not_to raise_error
        expect(extended_record.errors.size).to eq 1
        expect(base_record.errors.size).to eq 0
      end

      context 'altering the record used as base for casting' do
        it 'to prevent changing it' do
          base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'old value')
          expect{ base_record.persisted_string = 'changed value' }.not_to raise_error

          extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)

          expect{ base_record.persisted_string = 'change after cast' }.to raise_error(ActiveType::MutationAfterCastError)
          expect{ extended_record.persisted_string = 'change after cast' }.not_to raise_error
        end

        it 'to prevent saving it' do
          base_record = UtilSpec::BaseRecord.create!
          expect{ base_record.save! }.not_to raise_error

          extended_record = ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)

          expect{ base_record.save! }.to raise_error(ActiveType::MutationAfterCastError)
          expect{ extended_record.save! }.not_to raise_error
        end

        it 'but still allow to inspect it' do
          base_record = UtilSpec::BaseRecord.create!
          expect{ base_record.inspect }.not_to raise_error

          ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord)

          expect{ base_record.inspect }.not_to raise_error
        end

        context 'with option force: true' do
          it 'will not prevent changing or saving it' do
            base_record = UtilSpec::BaseRecord.create!(:persisted_string => 'old value')

            ActiveType::Util.cast(base_record, UtilSpec::ExtendedRecord, force: true)

            expect{ base_record.persisted_string = 'change after cast' }.not_to raise_error
            expect{ base_record.save! }.not_to raise_error
          end
        end
      end
    end

  end

  it "exposes all methods through ActiveType's root namespace" do
    expect(ActiveType).to respond_to(:cast)
  end

end
