require 'spec_helper'

module RecordSpec

  class Record < ActiveType::Record

    attribute :virtual_string, :string
    attribute :virtual_integer, :integer
    attribute :virtual_time, :datetime
    attribute :virtual_date, :date
    attribute :virtual_boolean, :boolean

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
end


describe ActiveType::Record do

  subject { RecordSpec::Record.new }

  it 'is a ActiveRecord::Base' do
    subject.should be_a(ActiveRecord::Base)
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

  describe 'overridable attributes' do

    subject { RecordSpec::RecordWithOverrides.new }

    it 'is possible to override attributes with super' do
      subject.overridable_test = "test"

      subject.overridable_test.should == "testtest"
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
  end

  describe 'validations' do
    subject { RecordSpec::RecordWithValidations.new }

    it { should have(1).error_on(:persisted_string) }
    it { should have(1).error_on(:virtual_string) }
  end

  describe 'undefined columns' do
    it 'raises an error when trying to access an undefined virtual attribute' do
      expect do
        subject.read_virtual_attribute('foo')
      end.to raise_error(ActiveType::MissingAttributeError)
    end
  end

  describe 'persistence' do

    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      subject.save.should be_true

      subject.class.find(subject.id).persisted_string.should == "persisted string"
    end
  end

end
