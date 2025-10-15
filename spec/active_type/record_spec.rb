require 'spec_helper'
require 'ostruct'

module RecordSpec

  def self.type
    if ActiveRecord::VERSION::MAJOR >= 5
      @type ||= ActiveModel::Type::Value.new
    end
  end

  class Record < ActiveType::Record

    attribute :virtual_string, :string
    attribute :virtual_integer, :integer
    attribute :virtual_time, :datetime
    attribute :virtual_date, :date
    attribute :virtual_boolean, :boolean
    attribute :virtual_attribute
    attribute :virtual_type_attribute, RecordSpec.type

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

  class RecordWithRequiredBelongsTo < Record

    attribute :child_id, :integer

    belongs_to :child, optional: false

  end

  class RecordWithOptionalBelongsTo < Record

    attribute :child_id, :integer

    belongs_to :child, optional: true

  end

  if ActiveRecord::VERSION::STRING >= '7.1.0'
    ActiveRecord.belongs_to_required_validates_foreign_key = !ActiveRecord.belongs_to_required_validates_foreign_key

    class RecordWithRequiredBelongsToFlippedValidatesForeignKey < Record
      BELONGS_TO_REQUIRED_VALIDATES_FOREIGN_KEY = ActiveRecord.belongs_to_required_validates_foreign_key

      attribute :child_id, :integer

      belongs_to :child, optional: false

    end

    class RecordWithOptionalBelongsToFlippedValidatesForeignKey < Record
      BELONGS_TO_REQUIRED_VALIDATES_FOREIGN_KEY = ActiveRecord.belongs_to_required_validates_foreign_key

      attribute :child_id, :integer

      belongs_to :child, optional: true

    end

    ActiveRecord.belongs_to_required_validates_foreign_key = !ActiveRecord.belongs_to_required_validates_foreign_key
  end
end


describe ActiveType::Record do

  subject { RecordSpec::Record.new }
  t = Time.new(2016, 2, 1, 12)

  it 'is a ActiveRecord::Base' do
    expect(subject).to be_a(ActiveRecord::Base)
  end

  it 'is an abstract class' do
    expect(ActiveType::Record).to be_abstract_class
  end

  describe 'constructors' do
    subject { RecordSpec::Record }

    it_should_behave_like 'ActiveRecord-like constructors', { :persisted_string => "string", :persisted_integer => 100, :persisted_time => t, :persisted_date => Date.today, :persisted_boolean => true }

    it_should_behave_like 'ActiveRecord-like constructors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => t, :virtual_date => Date.today, :virtual_boolean => true }

  end

  describe 'mass assignment' do
    it_should_behave_like 'ActiveRecord-like mass assignment', { :persisted_string => "string", :persisted_integer => 100, :persisted_time => t, :persisted_date => Date.today, :persisted_boolean => true }

    it_should_behave_like 'ActiveRecord-like mass assignment', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => t, :virtual_date => Date.today, :virtual_boolean => true }
  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :persisted_string => "string", :persisted_integer => 100, :persisted_time => t, :persisted_date => Date.today, :persisted_boolean => true }

    it_should_behave_like 'ActiveRecord-like accessors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => t, :virtual_date => Date.today, :virtual_boolean => true }
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

    describe 'type columns' do
      it_should_behave_like 'a coercible type column', :virtual_type_attribute, RecordSpec.type
    end
  end

  describe '#inspect' do

    it 'returns the contents of the object as a nicely formatted string' do
      t = Time.now
      subject.persisted_string = "persisted string"
      subject.virtual_string = "string"
      subject.persisted_integer = 20
      subject.virtual_integer = 17
      subject.virtual_time = t
      subject.virtual_date = Date.today
      subject.virtual_boolean = true
      subject.virtual_attribute = OpenStruct.new({:test => "openstruct"})

      expect(subject.inspect).to eq("#<RecordSpec::Record id: nil, persisted_boolean: nil, persisted_date: nil, persisted_integer: 20, persisted_string: \"persisted string\", persisted_time: nil, virtual_attribute: #<OpenStruct test=\"openstruct\">, virtual_boolean: true, virtual_date: \"#{Date.today}\", virtual_integer: 17, virtual_string: \"string\", virtual_time: \"#{t.to_formatted_s(:db)}\", virtual_type_attribute: nil>")
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
        "virtual_type_attribute" => nil,
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil,
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

  describe '#attribute_changed?' do
    it "returns true for persisted attributes if changed" do
      subject.persisted_string = "persisted string"
      expect(subject.attribute_changed?(:persisted_string)).to eq(true)
    end

    it "returns true for persisted attributes if not changed" do
      expect(subject.attribute_changed?(:persisted_string)).to eq(false)
    end
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

  describe '#belongs_to, optional: false' do
    subject { RecordSpec::RecordWithRequiredBelongsTo.new }

    it_should_behave_like 'a required belongs_to association', :child, RecordSpec::Child
  end

  describe '#belongs_to, optional: true' do
    subject { RecordSpec::RecordWithOptionalBelongsTo.new }

    it_should_behave_like 'an optional belongs_to association', :child, RecordSpec::Child
  end

  if ActiveRecord::VERSION::STRING >= '7.1.0'
    v = RecordSpec::RecordWithRequiredBelongsToFlippedValidatesForeignKey::BELONGS_TO_REQUIRED_VALIDATES_FOREIGN_KEY
    describe "#belongs_to, optional: false, belongs_to_required_validates_foreign_key: #{v}" do
      subject { RecordSpec::RecordWithRequiredBelongsToFlippedValidatesForeignKey.new }

      it_should_behave_like 'a required belongs_to association', :child, RecordSpec::Child
    end

    v = RecordSpec::RecordWithOptionalBelongsToFlippedValidatesForeignKey::BELONGS_TO_REQUIRED_VALIDATES_FOREIGN_KEY
    describe "#belongs_to, optional: true, belongs_to_required_validates_foreign_key: #{v}" do
      subject { RecordSpec::RecordWithOptionalBelongsToFlippedValidatesForeignKey.new }

      it_should_behave_like 'an optional belongs_to association', :child, RecordSpec::Child
    end
  end

  it 'can access virtual attributes after .find' do
    subject.save!
    expect(subject.class.find(subject.id).virtual_string).to eq(nil)
    expect(subject.class.find(subject.id).virtual_string).to eq(nil)
  end

  if ActiveRecord::VERSION::MAJOR >= 5
    describe '#ar_attribute' do
      it 'delegates to ActiveRecord\'s original .attribute method' do
        klass = Class.new(RecordSpec::Record) do
          ar_attribute :ar_type, RecordSpec.type
        end
        subject = klass.new

        expect(RecordSpec.type).to receive(:cast).with('input').and_return('output')
        subject.ar_type = 'input'

        expect(subject.ar_type).to eq('output')
      end
    end
  end

  describe "#serializable_hash" do
    it "returns a hash of virtual and real attributes for serialization" do
      subject.persisted_string = "string"
      subject.virtual_string = "string"
      subject.virtual_integer = "17"

      expect(subject.serializable_hash).to eq({
        "id" => nil,
        "persisted_boolean" => nil,
        "persisted_date" => nil,
        "persisted_integer" => nil,
        "persisted_string" => "string",
        "persisted_time" => nil,
        "virtual_string" => "string",
        "virtual_integer" => 17,
        "virtual_time" => nil,
        "virtual_date" => nil,
        "virtual_boolean" => nil,
        "virtual_attribute" => nil,
        "virtual_type_attribute" => nil,
      })
    end
  end

  describe "marshalling" do
    shared_examples "marshalling attributes" do
      it "marshals attributes properly" do
        object = RecordSpec::Record.create!(
          virtual_string: "foobar",
          virtual_integer: 123,
          virtual_time: Time.parse("12:00 15.10.2025"),
          virtual_date: Date.parse("15.10.2025"),
          virtual_boolean: true,
          virtual_attribute: { some: "random object" },
          virtual_type_attribute: "RecordSpec::Record",
          persisted_string: "a real active record attribute"
        )

        serialized_object = Marshal.dump(object)
        deserialized_object = Marshal.load(serialized_object)

        expect(deserialized_object.virtual_string).to eq "foobar"
        expect(deserialized_object.virtual_integer).to eq 123
        expect(deserialized_object.virtual_time).to eq Time.parse("12:00 15.10.2025")
        expect(deserialized_object.virtual_date).to eq Date.parse("15.10.2025")
        expect(deserialized_object.virtual_boolean).to eq true
        expect(deserialized_object.virtual_attribute).to eq({ some: "random object" })
        expect(deserialized_object.virtual_type_attribute).to eq "RecordSpec::Record"
        expect(deserialized_object.persisted_string).to eq "a real active record attribute"
      end
    end

    if ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1
      context 'for 6.1 marshalling' do
        before do
          ActiveRecord::Marshalling.format_version = 6.1
        end

        include_examples "marshalling attributes"
      end

      context 'for 7.1 marshalling' do
        before do
          ActiveRecord::Marshalling.format_version = 7.1
        end

        include_examples "marshalling attributes"
      end

      describe "loading a object marshalled with format version 6.1, but the current version is 7.1" do
        it "marshals attributes properly" do
          object = RecordSpec::Record.create!(
            virtual_string: "foo",
            persisted_string: "bar"
          )

          ActiveRecord::Marshalling.format_version = 6.1
          serialized_object = Marshal.dump(object)

          ActiveRecord::Marshalling.format_version = 7.1
          deserialized_object = Marshal.load(serialized_object)

          expect(deserialized_object.virtual_string).to eq "foo"
          expect(deserialized_object.persisted_string).to eq "bar"
        end
      end

      describe "loading a object marshalled with format version 7.1, but the current version is 6.1" do
        it "marshals attributes properly" do
          object = RecordSpec::Record.create!(
            virtual_string: "foo",
            persisted_string: "bar"
          )

          ActiveRecord::Marshalling.format_version = 7.1
          serialized_object = Marshal.dump(object)

          ActiveRecord::Marshalling.format_version = 6.1
          deserialized_object = Marshal.load(serialized_object)

          expect(deserialized_object.virtual_string).to eq "foo"
          expect(deserialized_object.persisted_string).to eq "bar"
        end
      end
    else
      include_examples "marshalling attributes"
    end
  end
end
