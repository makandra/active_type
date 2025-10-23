require 'spec_helper'

module ChangeAssociationSpec

  class Child < ActiveRecord::Base
    belongs_to :record
  end

  class Picture < ActiveRecord::Base
    belongs_to :imageable, polymorphic: true
  end

  class Record < ActiveRecord::Base
    has_many :children, class_name: 'ChangeAssociationSpec::Child', dependent: :destroy
    has_one :lone_child, class_name: 'ChangeAssociationSpec::Child'

    has_many :nice_children, -> { where(nice: true) }, class_name: 'ChangeAssociationSpec::Child'

    has_many :pictures, class_name: 'ChangeAssociationSpec::Picture', as: :imageable
    has_one :lone_picture, class_name: 'ChangeAssociationSpec::Picture', as: :imageable
  end

  class ExtendedChild < ActiveType::Record[Child]
  end

  class ExtendedRecord < ActiveType::Record[Record]
  end

  class ExtendedPicture < ActiveType::Record[Picture]
  end


  describe 'ActiveType::Record[Base]' do

    describe '.change_association' do

      it 'allows to change existing has_many associations for extended records' do
        record = Record.create
        Child.create(record: record)

        extended_class = Class.new(ActiveType::Record[Record]) do
          def self.name
            "ExtendedRecord"
          end
          change_association :children, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        expect(extended_class.first.children.first).to be_instance_of(ExtendedChild)
      end

      it 'complains about unknown association names' do
        expect {
          Class.new(ActiveType::Record[Record]) do
            change_association :foobar, foo: 'bar'
          end
        }.to raise_error(ArgumentError, /unrecognized association `foobar`/)
      end

      it 'does not affect the base classes association' do
        record = Record.create
        Child.create(record: record)

        Class.new(ActiveType::Record[Record]) do
          def self.name
            'ExtendedRecord'
          end

          change_association :children, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        expect(Record.first.children.first).not_to be_instance_of(ExtendedChild)
      end

      it 'retains options of the existing association' do
        record = Record.create
        Child.create(record: record)

        extended_class = Class.new(ActiveType::Record[Record]) do
          def self.name
            'ExtendedRecord'
          end

          change_association :children, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        extended_class.first.destroy

        expect(Child.count).to eq 0
      end

      it 'works for has_one' do
        record = Record.create
        Child.create(record: record)

        extended_class = Class.new(ActiveType::Record[Record]) do
          def self.name
            "ExtendedRecord"
          end

          change_association :lone_child, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        expect(extended_class.first.lone_child).to be_instance_of(ExtendedChild)
      end

      it 'works for belongs_to' do
        record = Record.create
        Child.create(record: record)

        extended_class = Class.new(ActiveType::Record[Child]) do
          def self.name
            "ExtendedChild"
          end

          change_association :record, class_name: 'ChangeAssociationSpec::ExtendedRecord'
        end

        expect(extended_class.first.record).to be_instance_of(ExtendedRecord)
      end

      it 'works for polymorphic associations' do
        record = Record.create
        Picture.create(imageable: record)

        extended_class = Class.new(ActiveType::Record[Record]) do
          def self.name
            "ExtendedRecord"
          end

          change_association :pictures, class_name: 'ChangeAssociationSpec::ExtendedPicture'
          change_association :lone_picture, class_name: 'ChangeAssociationSpec::ExtendedPicture'
        end

        expect(extended_class.first.pictures.first).to be_instance_of(ExtendedPicture)
        expect(extended_class.first.lone_picture).to be_instance_of(ExtendedPicture)
      end

      it 'retains scopes of the existing association' do
        record = Record.create
        Child.create(record: record, nice: true)
        Child.create(record: record, nice: false)
        expect(record.nice_children.size).to eq 1

        extended_class = Class.new(ActiveType::Record[Record]) do
          def self.name
            'ExtendedRecord'
          end

          change_association :nice_children, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        extended_nice_children = extended_class.first.nice_children

        expect(extended_nice_children.size).to eq 1
        expect(extended_nice_children.first).to be_instance_of(ExtendedChild)
      end

      it 'can override scopes' do
        record = Record.create
        Child.create(record: record, nice: true)
        Child.create(record: record, nice: false)
        Child.create(record: record, nice: false)
        expect(record.nice_children.size).to eq 1

        extended_class = Class.new(ActiveType::Record[Record]) do
          def self.name
            'ExtendedRecord'
          end

          # today is opposite day
          change_association :nice_children, -> { where(nice: false) }, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        extended_nice_children = extended_class.first.nice_children

        expect(extended_nice_children.size).to eq 2
        expect(extended_nice_children.first).to be_instance_of(ExtendedChild)
      end

      it 'does not raise an error when overriding scopes without new_options' do
        record = Record.create
        Child.create(record: record, nice: true)
        Child.create(record: record, nice: false)
        Child.create(record: record, nice: false)
        expect(record.nice_children.size).to eq 1

        extended_proc = ->(_class) do
          def self.name
            'ExtendedRecord'
          end

          # today is opposite day
          change_association :nice_children, -> { where(nice: false) }
        end

        expect { @extended_class = Class.new(ActiveType::Record[Record], &extended_proc) }.not_to raise_error

        extended_nice_children = @extended_class.first.nice_children
        expect(extended_nice_children.size).to eq 2
        expect(extended_nice_children.first).to be_instance_of(Child)
      end

    end

  end

  describe 'ActiveType::Record' do

    describe '.change_association' do

      it 'works too' do
        record = Record.create
        Child.create(record: record)

        extended_class = Class.new(ActiveType::Record) do
          self.table_name = 'records'
          def self.name
            "ExtendedRecord"
          end
          has_many :children, class_name: 'ChangeAssociationSpec::Child', dependent: :destroy, foreign_key: 'record_id'
          change_association :children, class_name: 'ChangeAssociationSpec::ExtendedChild'
        end

        expect(extended_class.first.children.first).to be_instance_of(ExtendedChild)
      end

    end

  end


end
