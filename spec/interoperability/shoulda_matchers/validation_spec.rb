require 'spec_helper'
require 'shoulda-matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec

    # Keep as many of these lines as are necessary:
    with.library :active_record
    with.library :active_model
  end
end

module ShouldaMatchersSpec
  class Record < ActiveType::Record
    attribute :virtual_integer, :integer

    validates :persisted_integer, numericality: true
    validates :virtual_integer, numericality: true
  end

  class AR
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :virtual_integer, :integer

    validates :virtual_integer, numericality: true
  end

  class Object < ActiveType::Object
    attribute :virtual_integer, :integer

    validates :virtual_integer, numericality: true
  end
end

describe 'shoulda-matchers integration', type: :model do
  it 'can test numericality validation on ActiveType::Record' do
    expect(ShouldaMatchersSpec::Record.new).to validate_numericality_of(:persisted_integer)
    expect(ShouldaMatchersSpec::Record.new).to validate_numericality_of(:virtual_integer)
  end

  it 'can test numericality validation on ActiveModel::Attributes' do
    expect(ShouldaMatchersSpec::AR.new).to validate_numericality_of(:virtual_integer)
  end

  it 'can test numericality validation on ActiveType::User' do
    expect(ShouldaMatchersSpec::Object.new).to validate_numericality_of(:virtual_integer)
  end
end
