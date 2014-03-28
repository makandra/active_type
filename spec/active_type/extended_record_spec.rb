require 'spec_helper'

module ExtendedRecordSpec

  class BaseRecord < ActiveRecord::Base
    self.table_name = 'records'
  end

  class BaseActiveTypeRecord < ActiveType::Record
    self.table_name = 'records'

    attribute :virtual_string, :string
  end

  class ExtendedRecord < ActiveType::Record[BaseRecord]
    attribute :another_virtual_string, :string
  end

  class ExtendedActiveTypeRecord < ActiveType::Record[BaseActiveTypeRecord]
    attribute :another_virtual_string, :string
  end


  class ExtendedRecordWithValidations < ExtendedActiveTypeRecord
    validates :persisted_string, :presence => true
    validates :virtual_string, :presence => true
    validates :another_virtual_string, :presence => true
  end

end


describe "ActiveType::Record[ActiveRecord::Base]" do

  subject { ExtendedRecordSpec::ExtendedRecord.new }

  it 'is inherits from the base type' do
    subject.should be_a(ExtendedRecordSpec::BaseRecord)
  end

  describe 'constructors' do
    subject { ExtendedRecordSpec::ExtendedRecord }

    it_should_behave_like 'ActiveRecord-like constructors', { :persisted_string => "persisted string", :another_virtual_string => "another virtual string" }
  end

  describe '#attributes' do

    it 'returns a hash of virtual and persisted attributes' do
      subject.persisted_string = "string"
      subject.another_virtual_string = "string"

      subject.attributes.should == {
        "another_virtual_string" => "string",
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil
      }
    end

  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :persisted_string => "persisted string", :another_virtual_string => "another virtual string" }
  end

  describe 'persistence' do
    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      subject.save.should be_true

      subject.class.find(subject.id).persisted_string.should == "persisted string"
    end
  end

  describe '.find' do
    it 'returns an instance of the extended model' do
      subject.save

      subject.class.find(subject.id).should be_a(subject.class)
    end
  end

  describe '.base_class' do
    it 'is the base class inherited from' do
      subject.class.base_class.should == ExtendedRecordSpec::BaseRecord
    end
  end

end


describe "ActiveType::Record[ActiveType::Record]" do

  subject { ExtendedRecordSpec::ExtendedActiveTypeRecord.new }

  it 'is inherits from the base type' do
    subject.should be_a(ExtendedRecordSpec::BaseActiveTypeRecord)
  end

  it 'has the same model name as the base class' do
    subject.class.model_name.singular.should == ExtendedRecordSpec::BaseActiveTypeRecord.model_name.singular
  end

  describe 'constructors' do
    subject { ExtendedRecordSpec::ExtendedActiveTypeRecord }

    it_should_behave_like 'ActiveRecord-like constructors', { :persisted_string => "persisted string", :virtual_string => "virtual string", :another_virtual_string => "another virtual string" }
  end

  describe '#attributes' do

    it 'returns a hash of virtual and persisted attributes' do
      subject.persisted_string = "string"
      subject.virtual_string = "string"

      subject.attributes.should == {
        "virtual_string" => "string",
        "another_virtual_string" => nil,
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil
      }
    end

  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :persisted_string => "persisted string", :virtual_string => "virtual string", :another_virtual_string => "another virtual string" }
  end

  describe 'validations' do
    subject { ExtendedRecordSpec::ExtendedRecordWithValidations.new }

    it { should have(1).error_on(:persisted_string) }
    it { should have(1).error_on(:virtual_string) }
    it { should have(1).error_on(:another_virtual_string) }
  end

  describe 'persistence' do
    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      subject.save.should be_true

      subject.class.find(subject.id).persisted_string.should == "persisted string"
    end
  end

  describe '.find' do
    it 'returns an instance of the extended model' do
      subject.save

      subject.class.find(subject.id).should be_a(subject.class)
    end
  end

  describe '.base_class' do
    it 'is the base class inherited from' do
      subject.class.base_class.should == ExtendedRecordSpec::BaseActiveTypeRecord
    end
  end

end
