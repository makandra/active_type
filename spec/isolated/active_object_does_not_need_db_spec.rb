require 'isolated_spec_helper'

RSpec.describe 'ActiveType::Object', type: :isolated do

  it 'does not need a database connection' do
    require 'active_type'
    expect {
      klass = Class.new(ActiveType::Object) do
        attribute :foo, :integer
      end
      expect(klass.new(foo: '15').foo).to eq 15
    }.not_to raise_error
  end

end
