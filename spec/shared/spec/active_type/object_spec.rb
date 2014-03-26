require 'spec_helper'

module ObjectSpec
  class Record < ActiveType::Object

    virtual_attribute :virtual_string, :string
    virtual_attribute :virtual_integer, :integer
    virtual_attribute :virtual_time, :datetime
    virtual_attribute :virtual_date, :date
    virtual_attribute :virtual_boolean, :boolean

    validates :virtual_string, :presence => true


    virtual_attribute :overridable_test, :string

    def overridable_test
      super + super
    end
  end
end


describe ActiveType::Record do

  subject { ObjectSpec::Record.new }

  describe 'constructors' do
    subject { ObjectSpec::Record }

    it_should_behave_like 'ActiveRecord-like constructors', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }

  end

  describe 'mass assignment' do
    it_should_behave_like 'ActiveRecord-like mass assignment', { :virtual_string => "string", :virtual_integer => 100, :virtual_time => Time.now, :virtual_date => Date.today, :virtual_boolean => true }
  end

  describe 'overridable attributes' do
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

  describe 'validations' do
    it { should have(1).error_on(:virtual_string) }
  end

end
