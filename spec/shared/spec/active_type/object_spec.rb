require 'spec_helper'

module ObjectSpec

  class Object < ActiveType::Object

    virtual_attribute :virtual_string, :string
    virtual_attribute :virtual_integer, :integer
    virtual_attribute :virtual_time, :datetime
    virtual_attribute :virtual_date, :date
    virtual_attribute :virtual_boolean, :boolean

  end


  class ObjectWithValidations < Object

    validates :virtual_string, :presence => true

  end


  class ObjectWithOverrides < Object

    virtual_attribute :overridable_test, :string

    def overridable_test
      super + super
    end

  end


  class InheritingObject < Object
    virtual_attribute :another_virtual_string, :string
  end


  class IncludingObject < Object

    module Module
      extend ActiveSupport::Concern

      included do
        virtual_attribute :another_virtual_string, :string
      end
    end

    include Module
  end


  class ObjectWithCallbacks < Object

    before_save :before_save_callback
    before_validation :before_validation_callback
    after_save :after_save_callback

    def before_save_callback
    end

    def before_validation_callback
    end

    def after_save_callback
    end

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

  describe 'overridable attributes' do
    subject { ObjectSpec::ObjectWithOverrides.new }

    it 'is possible to override attributes with super' do
      subject.overridable_test = "test"

      subject.overridable_test.should == "testtest"
    end
  end

  describe 'attribute name validation' do
    it 'crashes when trying to define an invalid attribute name' do
      klass = Class.new(ActiveType::Object)
      expect {
        klass.class_eval do
          virtual_attribute :"<attr>", :string
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
  end

  describe 'inherited classes' do

    it 'sees attributes of both classes' do
      object = ObjectSpec::InheritingObject.new
      object.virtual_string = "string"
      object.another_virtual_string = "another string"

      object.virtual_string.should == "string"
      object.another_virtual_string.should == "another string"
    end

    it 'does not define the attribute on the parent class' do
      object = ObjectSpec::Object.new
      object.should_not respond_to(:another_virtual_string)
    end

  end

  describe 'included modules' do
    it 'sees attributes of the included module' do
      object = ObjectSpec::IncludingObject.new
      object.virtual_string = "string"
      object.another_virtual_string = "another string"

      object.virtual_string.should == "string"
      object.another_virtual_string.should == "another string"
    end

    it 'does not define the attribute on the parent class' do
      object = ObjectSpec::Object.new
      object.should_not respond_to(:another_virtual_string)
    end
  end

  describe 'validations' do
    subject { ObjectSpec::ObjectWithValidations.new }

    it { should have(1).error_on(:virtual_string) }

    it 'has no errors if validations pass' do
      subject.virtual_string = "foo"

      subject.should be_valid
      subject.should have(:no).errors_on(:virtual_string)
    end

    it 'causes #save to return false' do
      subject.save.should be_false
    end
  end

  describe '#save' do
    subject { ObjectSpec::ObjectWithCallbacks.new }

    it "returns true" do
      subject.save
    end

    %w[before_validation before_save after_save].each do |callback|

      it "calls #{callback}" do
        subject.should_receive("#{callback}_callback")

        subject.save.should be_true
      end

    end

    %w[before_validation before_save].each do |callback|

      it "aborts the chain when #{callback} returns false" do
        subject.stub("#{callback}_callback" => false)

        subject.save.should be_false
      end

    end

  end

end
