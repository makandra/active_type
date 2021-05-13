require 'spec_helper'

module RecordExtensionSpec

  class Child < ActiveRecord::Base
    self.table_name = 'children'
  end

  class Record < ActiveRecord::Base
    self.table_name = 'records'
  end

  class BaseActiveTypeRecord < ActiveType::Record
    self.table_name = 'records'

    attribute :virtual_string, :string
  end

  class ExtendedRecord < ActiveType::Record[Record]
    attribute :another_virtual_string, :string

    has_many :children, class_name: 'Child'
    has_one :child, nil, class_name: 'Child'

    has_many :weird_children, class_name: 'Child', foreign_key: 'weird_id'
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

  subject { RecordExtensionSpec::ExtendedRecord.new }

  it 'is inherits from the base type' do
    expect(subject).to be_a(RecordExtensionSpec::Record)
  end

  it 'has the same model name as the base class' do
    base_model_name = RecordExtensionSpec::Record.model_name
    model_name = subject.class.model_name

    expect(model_name.singular).to eq(base_model_name.singular)
    expect(model_name.plural).to eq(base_model_name.plural)
  end

  it 'has the same route keys as the base class' do
    base_model_name = RecordExtensionSpec::Record.model_name
    model_name = subject.class.model_name

    expect(model_name.route_key).to eq(base_model_name.route_key)
    expect(model_name.singular_route_key).to eq(base_model_name.singular_route_key)
  end

  it 'has the same param key as the base class' do
    base_model_name = RecordExtensionSpec::Record.model_name
    model_name = subject.class.model_name

    expect(model_name.param_key).to eq(base_model_name.param_key)
  end

  it 'has a different i18n_key than the base class' do
    base_model_name = RecordExtensionSpec::Record.model_name
    model_name = subject.class.model_name

    expect(model_name.i18n_key).not_to eq(base_model_name.i18n_key)
    expect(model_name.i18n_key).to eq(:'record_extension_spec/extended_record')
  end

  describe 'constructors' do
    subject { RecordExtensionSpec::ExtendedRecord }

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
      expect(subject.class.base_class).to eq(RecordExtensionSpec::Record)
    end
  end

  describe 'associations' do
    it 'guess the correct foreign key' do
      expect(RecordExtensionSpec::ExtendedRecord.reflect_on_association(:children).foreign_key).to eq 'record_id'
    end

    it 'allows to override the foreign key' do
      expect(RecordExtensionSpec::ExtendedRecord.reflect_on_association(:weird_children).foreign_key).to eq 'weird_id'
    end

    it 'work by default' do
      subject.save
      child = RecordExtensionSpec::Child.create(record_id: subject.id)
      expect(subject.children).to eq [child]
      expect(subject.child).to eq child
    end
  end

end

describe "class ... < ActiveType::Record[ActiveRecord::Base]" do

  subject { RecordExtensionSpec::InheritingFromExtendedRecord.new }

  it 'is inherits from the base type' do
    expect(subject).to be_a(RecordExtensionSpec::ExtendedRecord)
  end

  it 'has the same model name as the base class' do
    base_model_name = RecordExtensionSpec::ExtendedRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.singular).to eq(base_model_name.singular)
    expect(model_name.plural).to eq(base_model_name.plural)
  end

  it 'has the same route keys as the base class' do
    base_model_name = RecordExtensionSpec::ExtendedRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.route_key).to eq(base_model_name.route_key)
    expect(model_name.singular_route_key).to eq(base_model_name.singular_route_key)
  end

  it 'has the same param key as the base class' do
    base_model_name = RecordExtensionSpec::ExtendedRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.param_key).to eq(base_model_name.param_key)
  end

  it 'has a different i18n_key than the base class' do
    base_model_name = RecordExtensionSpec::ExtendedRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.i18n_key).not_to eq(base_model_name.i18n_key)
    expect(model_name.i18n_key).to eq(:'record_extension_spec/inheriting_from_extended_record')
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

  subject { RecordExtensionSpec::ExtendedActiveTypeRecord.new }

  it 'is inherits from the base type' do
    expect(subject).to be_a(RecordExtensionSpec::BaseActiveTypeRecord)
  end

  it 'has the same model name as the base class' do
    base_model_name = RecordExtensionSpec::BaseActiveTypeRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.singular).to eq(base_model_name.singular)
    expect(model_name.plural).to eq(base_model_name.plural)
  end

  it 'has the same route keys as the base class' do
    base_model_name = RecordExtensionSpec::BaseActiveTypeRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.route_key).to eq(base_model_name.route_key)
    expect(model_name.singular_route_key).to eq(base_model_name.singular_route_key)
  end

  it 'has the same param key as the base class' do
    base_model_name = RecordExtensionSpec::BaseActiveTypeRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.param_key).to eq(base_model_name.param_key)
  end

  it 'has a different i18n_key than the base class' do
    base_model_name = RecordExtensionSpec::BaseActiveTypeRecord.model_name
    model_name = subject.class.model_name

    expect(model_name.i18n_key).not_to eq(base_model_name.i18n_key)
    expect(model_name.i18n_key).to eq(:'record_extension_spec/extended_active_type_record')
  end

  describe 'constructors' do
    subject { RecordExtensionSpec::ExtendedActiveTypeRecord }

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
    subject { RecordExtensionSpec::ExtendedRecordWithValidations.new }

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
      expect(subject.class.base_class).to eq(RecordExtensionSpec::BaseActiveTypeRecord)
    end
  end

end

describe 'i18n' do

  around :each do |test|
    begin
      orig_backend = I18n.backend
      I18n.backend = I18n::Backend::KeyValue.new({})
      test.run
    ensure
      I18n.backend = orig_backend
    end
  end

  describe 'translation of model name' do

    it 'has its own I18n key' do
      I18n.backend.store_translations(:en, activerecord: { models: { 'record_extension_spec/extended_record': 'ExtendedRecord translation' } })
      expect(RecordExtensionSpec::ExtendedRecord.model_name.human).to eq('ExtendedRecord translation')
    end

    it 'falls back to the I18n key of the base class if does not have its own I18n key' do
      I18n.backend.store_translations(:en, activerecord: { models: { 'record_extension_spec/record': 'BaseRecord translation' } })
      expect(RecordExtensionSpec::ExtendedRecord.model_name.human).to eq('BaseRecord translation')
    end

  end

  describe 'translation of attribute name' do

    it 'has its own I18n key' do
      I18n.backend.store_translations(:en, activerecord: { attributes: { 'record_extension_spec/extended_record': { persisted_string: 'ExtendedRecord translation' } } })
      expect(RecordExtensionSpec::ExtendedRecord.human_attribute_name(:persisted_string)).to eq('ExtendedRecord translation')
    end

    it 'falls back to the I18n key of the base class if does not have its own I18n key' do
      I18n.backend.store_translations(:en, activerecord: { attributes: { 'record_extension_spec/record': { persisted_string: 'BaseRecord translation' } } })
      expect(RecordExtensionSpec::ExtendedRecord.human_attribute_name(:persisted_string)).to eq('BaseRecord translation')
    end

  end
end
