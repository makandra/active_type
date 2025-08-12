require 'spec_helper'

module AcceptsNestedAttributesSpec

  class Child < ActiveRecord::Base
    belongs_to :record
    accepts_nested_attributes_for :record
  end

  class Record < ActiveRecord::Base
    has_many :children
    accepts_nested_attributes_for :children

    has_one :child
    accepts_nested_attributes_for :child
  end

  class FormChild < ActiveType::Record[Child]
    change_association :record, class_name: 'FormRecord'

    attribute :virtual_string, :string
  end

  class FormRecord < ActiveType::Record[Record]
    change_association :children, class_name: 'FormChild'
    change_association :child, class_name: 'FormChild'

    attribute :virtual_string, :string
  end

  describe ActiveType::Record do
    describe '.accepts_nested_attributes_for' do
      it 'works as expected when building new records' do
        children_attributes = {
          '0' => {
            'persisted_string' => 'child 1 persisted',
            'virtual_string' => 'child 1 virtual',
          },
          '1' => {
            'persisted_string' => 'child 2 persisted',
            'virtual_string' => 'child 2 virtual',
          },
        }

        form_record = FormRecord.new(children_attributes: children_attributes)

        expect(form_record.children.map(&:persisted_string)).to eq(['child 1 persisted', 'child 2 persisted'])
        expect(form_record.children.map(&:virtual_string)).to eq(['child 1 virtual', 'child 2 virtual'])
        form_record.save!

        form_record = FormRecord.first
        expect(form_record.children.order(:id).map(&:persisted_string)).to eq(['child 1 persisted', 'child 2 persisted'])
      end

      it 'works as expected when updating existing records' do
        record = Record.create!
        child_1 = record.children.create!(persisted_string: 'old value')
        child_2 = record.children.create!(persisted_string: 'old value')

        children_attributes = {
          '0' => {
            'id' => child_1.id,
            'persisted_string' => 'child 1 persisted',
            'virtual_string' => 'child 1 virtual',
          },
          '1' => {
            'id' => child_2.id,
            'persisted_string' => 'child 2 persisted',
            'virtual_string' => 'child 2 virtual',
          },
        }

        form_record = FormRecord.find(record.id)
        form_record.children
        form_record.children_attributes = children_attributes

        expect(form_record.children.map(&:persisted_string)).to eq(['child 1 persisted', 'child 2 persisted'])
        expect(form_record.children.map(&:virtual_string)).to eq(['child 1 virtual', 'child 2 virtual'])
        form_record.save!

        form_record = FormRecord.first
        expect(form_record.children.order(:id).map(&:persisted_string)).to eq(['child 1 persisted', 'child 2 persisted'])
      end

      it 'works as expected when updating existing records with changes to only belongs_to association virtual attributes' do
        record = FormRecord.create!
        child = Child.create!(record: record)

        record_attributes = {
          'id' => record.id,
          'virtual_string' => 'record virtual'
        }

        form_child = FormChild.new(record: record)
        form_child.record_attributes = record_attributes

        expect(form_child.record.virtual_string).to eq('record virtual')

        expect(form_child.record).to receive(:save)
        form_child.save!
      end

      it 'works as expected when updating existing records with changes to only has_one association virtual attributes' do
        record = Record.create!
        child = record.children.create!(persisted_string: 'old value')

        child_attributes = {
          'id' => child.id,
          'virtual_string' => 'child virtual'
        }

        form_record = FormRecord.find(record.id)
        form_record.child
        form_record.child_attributes = child_attributes

        expect(form_record.child.virtual_string).to eq('child virtual')

        expect(form_record.child).to receive(:save)
        form_record.save!
      end

      it 'works as expected when updating existing records with changes to only has_many association virtual attributes' do
        record = Record.create!
        child_1 = record.children.create!(persisted_string: 'old value')
        child_2 = record.children.create!(persisted_string: 'old value')

        children_attributes = {
          '0' => {
            'id' => child_1.id,
            'virtual_string' => 'child 1 virtual',
          },
          '1' => {
            'id' => child_2.id,
            'virtual_string' => 'child 2 virtual',
          },
        }

        form_record = FormRecord.find(record.id)
        form_record.children
        form_record.children_attributes = children_attributes

        expect(form_record.children.map(&:virtual_string)).to eq(['child 1 virtual', 'child 2 virtual'])

        expect(form_record.children.first).to receive(:save).and_call_original
        expect(form_record.children.second).to receive(:save).and_call_original

        form_record.save!
      end
    end
  end
end

