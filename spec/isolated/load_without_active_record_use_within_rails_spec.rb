# encoding: utf-8

require 'isolated_spec_helper'

RSpec.describe 'ActiveType', type: :isolated do

  it 'can be used in a Rails app without explicitly using ActiveRecord::Base first (see issue #75)' do
    expect {
      fake_rails
      require 'active_type'
      ActiveType::Object
    }.not_to raise_error
  end

end
