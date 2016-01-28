require 'spec_helper'

module RecordSpec

  class Record < ActiveType::Record

    attribute :virtual_string, :string
    attribute :virtual_integer, :integer
    attribute :virtual_time, :datetime
    attribute :virtual_date, :date
    attribute :virtual_boolean, :boolean
    attribute :virtual_attribute

  end

  class RecordWithValidations < Record

    validates :persisted_string, :presence => true
    validates :virtual_string, :presence => true

  end


  class RecordWithOverrides < Record

    attribute :overridable_test, :string

    def overridable_test
      super + super
    end

  end

  class RecordCopy < ActiveType::Record
    self.table_name = 'records'

    attribute :virtual_string, :string

  end

  class OtherRecord < ActiveType::Record
  end

  class Child < ActiveRecord::Base
  end

  class RecordWithBelongsTo < Record

    attribute :child_id, :integer

    belongs_to :child

  end
end


describe ActiveType::Record do

  subject { RecordSpec::Record.new }

  it 'is a ActiveRecord::Base' do
    expect(subject).to be_a(ActiveRecord::Base)
  end

  it 'is an abstract class' do
    expect(ActiveType::Record).to be_abstract_class
  end

  describe 'constructors' do
    subject { RecordSpec::Record }

    it_should_behave_like 'ActiveRecord-like constructors', { :persisted_string => "string", :persisted_integer => 100, :persisted_time => Time.now, :persisted_date => Date.today, :persisted_boolean => true }

    it_should_behave_like 'ActiveRecord-like constructors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }

  end

  describe 'mass assignment' do
    it_should_behave_like 'ActiveRecord-like mass assignment', { :persisted_string => "string", :persisted_integer => 100, :persisted_time => Time.now, :persisted_date => Date.today, :persisted_boolean => true }

    it_should_behave_like 'ActiveRecord-like mass assignment', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }
  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :persisted_string => "string", :persisted_integer => 100, :persisted_time => Time.now, :persisted_date => Date.today, :persisted_boolean => true }

    it_should_behave_like 'ActiveRecord-like accessors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }
  end

  describe 'overridable attributes' do

    subject { RecordSpec::RecordWithOverrides.new }

    it 'is possible to override attributes with super' do
      subject.overridable_test = "test"

      expect(subject.overridable_test).to eq("testtest")
    end
  end

  describe 'attribute name validation' do
    it 'crashes when trying to define an invalid attribute name' do
      klass = Class.new(ActiveType::Record)
      expect {
        klass.class_eval do
          attribute :"<attr>", :string
        end
      }.to raise_error(ActiveType::InvalidAttributeNameError)
    end
  end

  describe '.reset_column_information' do
    it 'does not affect virtual attributes' do
      RecordSpec::RecordCopy.new.persisted_string = "string"
      RecordSpec::RecordCopy.reset_column_information

      expect do
        RecordSpec::RecordCopy.new.virtual_string = "string"
      end.to_not raise_error
    end
  end

  context 'coercible' do
    describe 'string columns' do
      it_should_behave_like 'a coercible string column', :persisted_string
      it_should_behave_like 'a coercible string column', :virtual_string
    end

    describe 'integer columns' do
      it_should_behave_like 'a coercible integer column', :persisted_integer
      it_should_behave_like 'a coercible integer column', :virtual_integer
    end

    describe 'date columns' do
      it_should_behave_like 'a coercible date column', :persisted_date
      it_should_behave_like 'a coercible date column', :virtual_date
    end

    describe 'time columns' do
      it_should_behave_like 'a coercible time column', :persisted_time
      it_should_behave_like 'a coercible time column', :virtual_time
    end

    describe 'boolean columns' do
      it_should_behave_like 'a coercible boolean column', :persisted_boolean
      it_should_behave_like 'a coercible boolean column', :virtual_boolean
    end

    describe 'untyped columns' do
      it_should_behave_like 'an untyped column', :virtual_attribute
    end
  end

  describe '#attributes' do

    it 'returns a hash of virtual and persisted attributes' do
      subject.persisted_string = "string"
      subject.virtual_string = "string"
      subject.virtual_integer = "17"

      expect(subject.attributes).to eq({
        "virtual_string" => "string",
        "virtual_integer" => 17,
        "virtual_time" => nil,
        "virtual_date" => nil,
        "virtual_boolean" => nil,
        "virtual_attribute" => nil,
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil
      })
    end

  end

  describe 'validations' do
    subject { RecordSpec::RecordWithValidations.new }

    it 'has 1 error_on' do
      expect(subject.error_on(:persisted_string).size).to eq(1)
    end
    it 'has 1 error_on' do
      expect(subject.error_on(:virtual_string).size).to eq(1)
    end
  end

  describe 'undefined columns' do
    it 'raises an error when trying to access an undefined virtual attribute' do
      expect do
        subject.read_virtual_attribute('foo')
      end.to raise_error(ActiveType::MissingAttributeError)
    end
  end

  describe 'defaults' do
    it_should_behave_like "a class accepting attribute defaults", RecordSpec::Record
  end

  describe 'duping' do
    it_should_behave_like "a class supporting dup for attributes", RecordSpec::Record
  end

  describe 'dirty tracking' do
    it_should_behave_like 'a class supporting dirty tracking for virtual attributes', RecordSpec::Record
  end

  describe 'persistence' do

    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      expect(subject.save).to eq(true)

      expect(subject.class.find(subject.id).persisted_string).to eq("persisted string")
    end
  end

  describe 'isolation' do
    it 'does not let column information bleed into different models' do
      record = RecordSpec::Record.new
      other_record = RecordSpec::OtherRecord.new

      expect(record).not_to respond_to(:other_string)
      expect(other_record).not_to respond_to(:persisted_string)
    end
  end

  describe '#belongs_to' do
    subject { RecordSpec::RecordWithBelongsTo.new }

    it_should_behave_like 'a belongs_to association', :child, RecordSpec::Child
  end

end
