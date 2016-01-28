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

  class InheritingFromExtendedRecord < ExtendedRecord
    attribute :yet_another_virtual_string, :string
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
    expect(subject).to be_a(ExtendedRecordSpec::BaseRecord)
  end

  it 'has the same model name as the base class' do
    expect(subject.class.model_name.singular).to eq(ExtendedRecordSpec::BaseRecord.model_name.singular)
  end

  describe 'constructors' do
    subject { ExtendedRecordSpec::ExtendedRecord }

    it_should_behave_like 'ActiveRecord-like constructors', { :persisted_string => "persisted string", :another_virtual_string => "another virtual string" }
  end

  describe '#attributes' do

    it 'returns a hash of virtual and persisted attributes' do
      subject.persisted_string = "string"
      subject.another_virtual_string = "string"

      expect(subject.attributes).to eq({
        "another_virtual_string" => "string",
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil
      })
    end

  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :persisted_string => "persisted string", :another_virtual_string => "another virtual string" }
  end

  describe 'persistence' do
    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      expect(subject.save).to eq(true)

      expect(subject.class.find(subject.id).persisted_string).to eq("persisted string")
    end
  end

  describe '.find' do
    it 'returns an instance of the extended model' do
      subject.save

      expect(subject.class.find(subject.id)).to be_a(subject.class)
    end
  end

  describe '.base_class' do
    it 'is the base class inherited from' do
      expect(subject.class.base_class).to eq(ExtendedRecordSpec::BaseRecord)
    end
  end

end

describe "class ... < ActiveType::Record[ActiveRecord::Base]" do

  subject { ExtendedRecordSpec::InheritingFromExtendedRecord.new }

  it 'is inherits from the base type' do
    expect(subject).to be_a(ExtendedRecordSpec::ExtendedRecord)
  end

  it 'has the same model name as the base class' do
    expect(subject.class.model_name.singular).to eq(ExtendedRecordSpec::BaseRecord.model_name.singular)
  end

  describe '#attributes' do

    it 'returns a hash of virtual and persisted attributes' do
      subject.persisted_string = "string"
      subject.another_virtual_string = "string"
      subject.yet_another_virtual_string = "string"

      expect(subject.attributes).to eq({
        "another_virtual_string" => "string",
        "yet_another_virtual_string" => "string",
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil
      })
    end

  end

  describe 'persistence' do
    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      expect(subject.save).to eq(true)

      expect(subject.class.find(subject.id).persisted_string).to eq("persisted string")
    end
  end

  describe '.find' do
    it 'returns an instance of the inheriting model' do
      subject.save

      expect(subject.class.find(subject.id)).to be_a(subject.class)
    end
  end

end

describe "ActiveType::Record[ActiveType::Record]" do

  subject { ExtendedRecordSpec::ExtendedActiveTypeRecord.new }

  it 'is inherits from the base type' do
    expect(subject).to be_a(ExtendedRecordSpec::BaseActiveTypeRecord)
  end

  it 'has the same model name as the base class' do
    expect(subject.class.model_name.singular).to eq(ExtendedRecordSpec::BaseActiveTypeRecord.model_name.singular)
  end

  describe 'constructors' do
    subject { ExtendedRecordSpec::ExtendedActiveTypeRecord }

    it_should_behave_like 'ActiveRecord-like constructors', { :persisted_string => "persisted string", :virtual_string => "virtual string", :another_virtual_string => "another virtual string" }
  end

  describe '#attributes' do

    it 'returns a hash of virtual and persisted attributes' do
      subject.persisted_string = "string"
      subject.virtual_string = "string"

      expect(subject.attributes).to eq({
        "virtual_string" => "string",
        "another_virtual_string" => nil,
        "id" => nil,
        "persisted_string" => "string",
        "persisted_integer" => nil,
        "persisted_time" => nil,
        "persisted_date" => nil,
        "persisted_boolean" => nil
      })
    end

  end

  describe 'accessors' do
    it_should_behave_like 'ActiveRecord-like accessors', { :persisted_string => "persisted string", :virtual_string => "virtual string", :another_virtual_string => "another virtual string" }
  end

  describe 'validations' do
    subject { ExtendedRecordSpec::ExtendedRecordWithValidations.new }

    it 'has 1 error_on' do
      expect(subject.error_on(:persisted_string).size).to eq(1)
    end
    it 'has 1 error_on' do
      expect(subject.error_on(:virtual_string).size).to eq(1)
    end
    it 'has 1 error_on' do
      expect(subject.error_on(:another_virtual_string).size).to eq(1)
    end
  end

  describe 'persistence' do
    it 'persists to the database' do
      subject.persisted_string = "persisted string"
      expect(subject.save).to eq(true)

      expect(subject.class.find(subject.id).persisted_string).to eq("persisted string")
    end
  end

  describe '.find' do
    it 'returns an instance of the extended model' do
      subject.save

      expect(subject.class.find(subject.id)).to be_a(subject.class)
    end
  end

  describe '.base_class' do
    it 'is the base class inherited from' do
      expect(subject.class.base_class).to eq(ExtendedRecordSpec::BaseActiveTypeRecord)
    end
  end

end
