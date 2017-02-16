# encoding: utf-8

require 'isolated_spec_helper'

RSpec.describe 'ActiveType', type: :isolated do

  it 'does not trigger active_record load-hook on require, since this messes up AR configuration via Rails initializers (see issue #72)' do
    fake_rails
    loaded = false
    ActiveSupport.on_load(:active_record) do
      loaded = true
    end
    require 'active_type'
    expect(loaded).to eq false
  end

end
