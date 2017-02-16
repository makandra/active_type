# encoding: utf-8

require 'isolated_spec_helper'

RSpec.describe 'ActiveType', type: :isolated do

  it 'can be used without explicitly using ActiveRecord::Base first' do
    expect {
      require 'active_type'
      ActiveType::Object
    }.not_to raise_error
  end

end
