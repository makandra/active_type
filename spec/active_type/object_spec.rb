require 'spec_helper'

module ObjectSpec

  class Object < ActiveType::Object

    attribute :virtual_string, :string
    attribute :virtual_integer, :integer
    attribute :virtual_time, :datetime
    attribute :virtual_date, :date
    attribute :virtual_boolean, :boolean
    attribute :virtual_attribute

  end

  class PlainObject < ActiveType::Object
  end


  class ObjectWithValidations < Object

    validates :virtual_string, :presence => true
    validates :virtual_boolean, :presence => true

  end


  class ObjectWithOverrides < Object

    attribute :overridable_test, :string

    def overridable_test
      super + super
    end

  end


  class InheritingObject < Object
    attribute :another_virtual_string, :string
  end


  class IncludingObject < Object

    module Module
      extend ActiveSupport::Concern

      included do
        attribute :another_virtual_string, :string
      end
    end

    include Module
  end


  class ObjectWithCallbacks < Object

    before_save :before_save_callback
    before_validation :before_validation_callback
    after_save :after_save_callback
    after_commit :after_commit_callback
    after_rollback :after_rollback_callback

    def before_save_callback
    end

    def before_validation_callback
    end

    def after_save_callback
    end

    def after_commit_callback
    end

    def after_rollback_callback
    end

  end

  class Child < ActiveRecord::Base
  end

  class ObjectWithBelongsTo < Object

    attribute :child_id, :integer

    belongs_to :child

  end

  class ObjectWithUnsupportedTypes < Object
    attribute :virtual_array, :array
    attribute :virtual_hash, :hash
  end

end


describe ActiveType::Object do

  subject { ObjectSpec::Object.new }

  describe 'constructors' do
    subject { ObjectSpec::Object }

    it_should_behave_like 'ActiveRecord-like constructors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }

  end

  describe 'mass assignment' do
    it_should_behave_like 'ActiveRecord-like mass assignment', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }
  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }
  end

  describe 'unsupported types' do
    subject { ObjectSpec::ObjectWithUnsupportedTypes.new }

    it_should_behave_like 'ActiveRecord-like mass assignment', { :virtual_hash => {'foo' => 'bar'}, :virtual_array => ['foo', 'bar'] }
    it_should_behave_like 'ActiveRecord-like accessors', { :virtual_hash => {'foo' => 'bar'}, :virtual_array => ['foo', 'bar'] }
  end

  describe 'overridable attributes' do
    subject { ObjectSpec::ObjectWithOverrides.new }

    it 'is possible to override attributes with super' do
      subject.overridable_test = "test"

      expect(subject.overridable_test).to eq("testtest")
    end
  end

  describe 'attribute name validation' do
    it 'crashes when trying to define an invalid attribute name' do
      klass = Class.new(ActiveType::Object)
      expect {
        klass.class_eval do
          attribute :"<attr>", :string
        end
      }.to raise_error(ActiveType::InvalidAttributeNameError)
    end
  end

  context 'coercible' do
    describe 'string columns' do
      it_should_behave_like 'a coercible string column', :virtual_string
    end

    describe 'integer columns' do
      it_should_behave_like 'a coercible integer column', :virtual_integer
    end

    describe 'date columns' do
      it_should_behave_like 'a coercible date column', :virtual_date
    end

    describe 'time columns' do
      it_should_behave_like 'a coercible time column', :virtual_time
    end

    describe 'boolean columns' do
      it_should_behave_like 'a coercible boolean column', :virtual_boolean
    end

    describe 'untyped columns' do
      it_should_behave_like 'an untyped column', :virtual_attribute
    end
  end

  describe 'query methods' do

    it 'returns true for true' do
      subject.virtual_attribute = true

      expect(subject.virtual_attribute?).to eq(true)
    end

    it 'returns false for false' do
      subject.virtual_attribute = false

      expect(subject.virtual_attribute?).to eq(false)
    end

    it 'returns false for nil' do
      subject.virtual_attribute = nil

      expect(subject.virtual_attribute?).to eq(false)
    end

    it 'returns true for 1' do
      subject.virtual_attribute = 1

      expect(subject.virtual_attribute?).to eq(true)
    end

    it 'returns true for an object' do
      subject.virtual_attribute = Object.new

      expect(subject.virtual_attribute?).to eq(true)
    end

  end

  describe '#attributes' do

    it 'returns a hash of virtual attributes' do
      subject.virtual_string = "string"
      subject.virtual_integer = "17"

      expect(subject.attributes).to eq({
        "virtual_string" => "string",
        "virtual_integer" => 17,
        "virtual_time" => nil,
        "virtual_date" => nil,
        "virtual_boolean" => nil,
        "virtual_attribute" => nil,
      })
    end

    it 'also includes inherited attributes' do
      object = ObjectSpec::InheritingObject.new
      object.virtual_string = "string"
      object.virtual_integer = "17"

      expect(object.attributes).to eq({
        "virtual_string" => "string",
        "virtual_integer" => 17,
        "virtual_time" => nil,
        "virtual_date" => nil,
        "virtual_boolean" => nil,
        "virtual_attribute" => nil,
        "another_virtual_string" => nil,
      })
    end

    it 'also includes included attributes' do
      object = ObjectSpec::IncludingObject.new
      object.virtual_string = "string"
      object.virtual_integer = "17"

      expect(object.attributes).to eq({
        "virtual_string" => "string",
        "virtual_integer" => 17,
        "virtual_time" => nil,
        "virtual_date" => nil,
        "virtual_boolean" => nil,
        "virtual_attribute" => nil,
        "another_virtual_string" => nil,
      })
    end

  end

  describe 'inherited classes' do

    it 'sees attributes of both classes' do
      object = ObjectSpec::InheritingObject.new
      object.virtual_string = "string"
      object.another_virtual_string = "another string"

      expect(object.virtual_string).to eq("string")
      expect(object.another_virtual_string).to eq("another string")
    end

    it 'does not define the attribute on the parent class' do
      object = ObjectSpec::Object.new
      expect(object).not_to respond_to(:another_virtual_string)
    end

  end

  describe 'included modules' do
    it 'sees attributes of the included module' do
      object = ObjectSpec::IncludingObject.new
      object.virtual_string = "string"
      object.another_virtual_string = "another string"

      expect(object.virtual_string).to eq("string")
      expect(object.another_virtual_string).to eq("another string")
    end

    it 'does not define the attribute on the parent class' do
      object = ObjectSpec::Object.new
      expect(object).not_to respond_to(:another_virtual_string)
    end
  end

  describe 'validations' do
    subject { ObjectSpec::ObjectWithValidations.new }

    it 'has 1 error_on' do
      expect(subject.error_on(:virtual_string).size).to eq(1)
    end
    
    it 'validates the presence of boolean values' do
      subject.virtual_boolean = false
      expect(subject.error_on(:virtual_boolean).size).to eq(1)
      subject.virtual_boolean = '0'
      expect(subject.error_on(:virtual_boolean).size).to eq(1)
      subject.virtual_boolean = 0
      expect(subject.error_on(:virtual_boolean).size).to eq(1)
      subject.virtual_boolean = true
      expect(subject.errors_on(:virtual_boolean).size).to eq(0)
    end

    it 'has no errors if validations pass' do
      subject.virtual_string = "foo"
      subject.virtual_boolean = true
      expect(subject).to be_valid
      expect(subject.errors_on(:virtual_string).size).to eq(0)
    end

    it 'causes #save to return false' do
      expect(subject.save).to be_falsey
    end
  end

  describe 'defaults' do
    it_should_behave_like "a class accepting attribute defaults", ActiveType::Object
  end

  describe 'duping' do
    it_should_behave_like "a class supporting dup for attributes", ActiveType::Object

    it 'can dup without attributes' do
      expect {
        ObjectSpec::PlainObject.new.dup
      }.not_to raise_error
    end
  end

  describe 'dirty tracking' do
    it_should_behave_like 'a class supporting dirty tracking for virtual attributes', ActiveType::Object
  end

  describe '#belongs_to' do
    subject { ObjectSpec::ObjectWithBelongsTo.new }

    it_should_behave_like 'a belongs_to association', :child, ObjectSpec::Child
  end

  describe '#save' do
    subject { ObjectSpec::ObjectWithCallbacks.new }

    it "returns true" do
      subject.save
    end

    %w[before_validation before_save after_save after_commit].each do |callback|

      it "calls #{callback}", :rollback => false do
        expect(subject).to receive("#{callback}_callback")

        expect(subject.save).to eq(true)
      end

    end

    %w[before_validation before_save].each do |callback|

      it "aborts the chain when #{callback} returns false" do
        allow(subject).to receive_messages("#{callback}_callback" => false)

        expect(subject.save).to be_falsey
      end

    end

    it 'runs after_rollback callbacks if an after_save callback raises an error', :rollback => false do
      expect(subject).to receive(:after_save_callback).ordered.and_raise(ActiveRecord::Rollback)
      expect(subject).to receive(:after_rollback_callback).ordered

      expect(subject.save).to be_falsey
    end

    it 'does not run after_rollback callbacks if after_save does not raise an error', :rollback => false do
      expect(subject).to_not receive(:after_rollback_callback)

      expect(subject.save).to be_truthy

    end

  end

  describe '.find' do
    it 'raises an error' do
      error = if ActiveRecord::VERSION::MAJOR >= 4 && ActiveRecord::VERSION::MINOR >= 1
        ActiveRecord::UnknownPrimaryKey
      else
        ActiveRecord::RecordNotFound
      end
      expect do
        ObjectSpec::Object.find(1)
      end.to raise_error(error)
    end
  end

  describe '.all' do
    it 'returns []' do
      expect(ObjectSpec::Object.all).to eq([])
    end
  end

  describe '.create' do
    it 'returns an object' do
      object = ObjectSpec::Object.create(:virtual_string => "string")

      expect(object).to be_a(ObjectSpec::Object)
      expect(object.virtual_string).to eq("string")
    end
  end

end
