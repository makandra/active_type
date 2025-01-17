require 'spec_helper'

class HasManySpec
  class AObject < ActiveType::Object
    attribute :id, :string
    attribute :a_name, :string
    has_many :b_objects, class_name: "BObject"
  end

  class BObject < ActiveType::Object
    attribute :b_name, :string
  end
end

describe HasManySpec::AObject do
  it 'does not crash' do
    expect(HasManySpec::AObject.new(id: 'test_a', b_objects: [HasManySpec::BObject.new(b_name: 'test_b')]).id).to eq('test_a')
  end
end
