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
    attribute :virtual_string, :string

    validates :persisted_string, numericality: true
    validates :virtual_string, numericality: true
  end

  class Object < ActiveType::Object
    attribute :virtual_string, :string

    validates :virtual_string, numericality: true
  end
end

describe 'shoulda-matchers integration', type: :model do
  it 'can test numericality validation on ActiveType::Record' do
    expect(ShouldaMatchersSpec::Record.new).to validate_numericality_of(:persisted_string)
    expect(ShouldaMatchersSpec::Record.new).to validate_numericality_of(:virtual_string)
  end

  it 'can test numericality validation on ActiveType::User' do
    expect(ShouldaMatchersSpec::Object.new).to validate_numericality_of(:virtual_string)
  end
end
