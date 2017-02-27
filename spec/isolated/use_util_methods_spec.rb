# encoding: utf-8

require 'isolated_spec_helper'

RSpec.describe 'ActiveType', type: :isolated do

  it 'can be used without explicitly using ActiveRecord::Base first' do
    require 'active_type'
    expect(ActiveType).to respond_to(:cast)
  end

end
