require 'spec_helper'

module AcceptsNestedAttributesSpec

  class Child < ActiveRecord::Base
  end

  class Record < ActiveRecord::Base
    has_many :children
    accepts_nested_attributes_for :children
  end

  class FormChild < ActiveType::Record[Child]
    attribute :virtual_string, :string
  end

  class FormRecord < ActiveType::Record[Record]
    change_association :children, class_name: 'FormChild'
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
    end
  end
end

